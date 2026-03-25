use std::net::SocketAddr;
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::Arc;

use futures_util::{SinkExt, StreamExt};
use log::{error, info, warn};
use serde::{Deserialize, Serialize};
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::net::{TcpListener, TcpStream};
use tokio::sync::{broadcast, RwLock};
use tokio_tungstenite::tungstenite::Message;

/// The latest EA version shipped with this server
const LATEST_EA_VERSION: &str = "2.01";

// ──────────────────────────────────────────────
//  Structs
// ──────────────────────────────────────────────

#[derive(Debug, Deserialize)]
struct ClientMessage {
    action: Option<String>,
}

#[derive(Debug, Serialize)]
struct DeployResponse {
    #[serde(rename = "type")]
    msg_type: String,
    status: String,
}

/// Shared state for EA version tracking
#[derive(Debug, Clone)]
struct EaState {
    connected: bool,
    version: String,
    symbol: String,
}

// ──────────────────────────────────────────────
//  Main
// ──────────────────────────────────────────────

#[tokio::main]
async fn main() {
    env_logger::Builder::from_env(env_logger::Env::default().default_filter_or("info")).init();

    let ws_addr = "127.0.0.1:8080";
    let mt5_addr = "127.0.0.1:8081";

    let ws_listener = TcpListener::bind(ws_addr).await.expect("Failed to bind WS");
    let mt5_listener = TcpListener::bind(mt5_addr).await.expect("Failed to bind MT5");

    info!("✅ ea-server WebSocket listening on ws://{}", ws_addr);
    info!("✅ ea-server MT5 TCP listening on {}", mt5_addr);
    info!("📦 Latest EA version: {}", LATEST_EA_VERSION);

    let active_eas = Arc::new(AtomicUsize::new(0));
    let ea_state = Arc::new(RwLock::new(EaState {
        connected: false,
        version: "unknown".to_string(),
        symbol: "".to_string(),
    }));

    let (tx, _rx) = broadcast::channel::<String>(100);

    // Spawn MT5 TCP Listener
    let tx_mt5 = tx.clone();
    let active_eas_mt5 = active_eas.clone();
    let ea_state_mt5 = ea_state.clone();
    tokio::spawn(async move {
        while let Ok((stream, peer_addr)) = mt5_listener.accept().await {
            let rx = tx_mt5.subscribe();
            tokio::spawn(handle_mt5_connection(
                stream,
                peer_addr,
                tx_mt5.clone(),
                rx,
                active_eas_mt5.clone(),
                ea_state_mt5.clone(),
            ));
        }
    });

    // Accept WebSocket connections
    while let Ok((stream, peer_addr)) = ws_listener.accept().await {
        let rx = tx.subscribe();
        tokio::spawn(handle_ws_connection(
            stream,
            peer_addr,
            tx.clone(),
            rx,
            active_eas.clone(),
            ea_state.clone(),
        ));
    }
}

// ──────────────────────────────────────────────
//  Handle MT5 Connection (Raw TCP)
// ──────────────────────────────────────────────

async fn handle_mt5_connection(
    mut stream: TcpStream,
    peer_addr: SocketAddr,
    tx: broadcast::Sender<String>,
    mut rx: broadcast::Receiver<String>,
    active_eas: Arc<AtomicUsize>,
    ea_state: Arc<RwLock<EaState>>,
) {
    info!("🔗 [MT5] New connection from: {}", peer_addr);
    active_eas.fetch_add(1, Ordering::SeqCst);

    let (reader, mut writer) = stream.split();
    let mut buf_reader = BufReader::new(reader);
    let mut line = String::new();

    loop {
        tokio::select! {
            result = buf_reader.read_line(&mut line) => {
                match result {
                    Ok(0) => {
                        info!("👋 [MT5] {} Disconnected", peer_addr);
                        break;
                    }
                    Ok(_) => {
                        let text = line.trim().to_string();
                        if !text.is_empty() {
                            // Check if this is ea_info message
                            if text.contains("\"ea_info\"") {
                                if let Ok(val) = serde_json::from_str::<serde_json::Value>(&text) {
                                    let ver = val["version"].as_str().unwrap_or("unknown").to_string();
                                    let sym = val["symbol"].as_str().unwrap_or("").to_string();
                                    info!("📋 [MT5] EA Version: {}, Symbol: {}", ver, sym);
                                    
                                    let mut state = ea_state.write().await;
                                    state.connected = true;
                                    state.version = ver.clone();
                                    state.symbol = sym.clone();

                                    // Broadcast ea_info to UI
                                    let info_msg = serde_json::json!({
                                        "type": "ea_info",
                                        "version": ver,
                                        "latest_version": LATEST_EA_VERSION,
                                        "symbol": sym,
                                        "update_available": ver != LATEST_EA_VERSION,
                                    }).to_string();
                                    let _ = tx.send(info_msg);
                                }
                            } else {
                                let _ = tx.send(text);
                            }
                        }
                        line.clear();
                    }
                    Err(e) => {
                        error!("❌ [MT5] Read error {}: {}", peer_addr, e);
                        break;
                    }
                }
            }

            msg_result = rx.recv() => {
                match msg_result {
                    Ok(msg) => {
                        if msg.contains("\"panic\"") || msg.contains("\"action\"") {
                            let mut out = msg.clone();
                            out.push('\n');
                            if let Err(e) = writer.write_all(out.as_bytes()).await {
                                error!("❌ [MT5] Send error to {}: {}", peer_addr, e);
                                break;
                            }
                            info!("🚀 [MT5] Sent command to EA: {}", msg);
                        }
                    }
                    Err(_) => break,
                }
            }
        }
    }

    // Reset state on disconnect
    {
        let mut state = ea_state.write().await;
        state.connected = false;
    }
    active_eas.fetch_sub(1, Ordering::SeqCst);
}

// ──────────────────────────────────────────────
//  Handle React WS Connection
// ──────────────────────────────────────────────

async fn handle_ws_connection(
    stream: TcpStream,
    peer_addr: SocketAddr,
    tx: broadcast::Sender<String>,
    mut rx: broadcast::Receiver<String>,
    active_eas: Arc<AtomicUsize>,
    ea_state: Arc<RwLock<EaState>>,
) {
    info!("🔗 [UI] New connection from: {}", peer_addr);

    let ws_stream = match tokio_tungstenite::accept_async(stream).await {
        Ok(ws) => ws,
        Err(e) => {
            error!("❌ [UI] WS handshake failed {}: {}", peer_addr, e);
            return;
        }
    };

    let (mut write, mut read) = ws_stream.split();

    // Send welcome + current EA state
    let state = ea_state.read().await;
    let welcome = serde_json::json!({
        "type": "welcome",
        "message": "Connected to ea-server",
        "status": "online",
        "latest_ea_version": LATEST_EA_VERSION,
        "ea_connected": state.connected,
        "ea_version": state.version,
        "ea_symbol": state.symbol,
        "update_available": state.connected && state.version != LATEST_EA_VERSION,
    });
    drop(state);
    let _ = write.send(Message::Text(welcome.to_string())).await;

    loop {
        tokio::select! {
            msg = read.next() => {
                match msg {
                    Some(Ok(Message::Text(text))) => {
                        info!("📩 [UI] Received: {}", text);
                        if let Ok(client_msg) = serde_json::from_str::<ClientMessage>(&text) {
                            if let Some(ref action) = client_msg.action {
                                match action.as_str() {
                                    "panic" => {
                                        warn!("🚨 [UI] PANIC ACTIVATED!");
                                        let panic_cmd = serde_json::json!({ "action": "panic" }).to_string();
                                        let _ = tx.send(panic_cmd);
                                    }
                                    "deploy_ea" => {
                                        info!("📦 [UI] Deploying EA...");
                                        if active_eas.load(Ordering::SeqCst) > 0 {
                                            let state = ea_state.read().await;
                                            if state.version == LATEST_EA_VERSION {
                                                let resp = DeployResponse {
                                                    msg_type: "deploy_status".to_string(),
                                                    status: "already_connected".to_string(),
                                                };
                                                let _ = write.send(Message::Text(serde_json::to_string(&resp).unwrap())).await;
                                            } else {
                                                // EA connected but outdated
                                                let resp = serde_json::json!({
                                                    "type": "deploy_status",
                                                    "status": "update_available",
                                                    "current_version": state.version,
                                                    "latest_version": LATEST_EA_VERSION,
                                                });
                                                let _ = write.send(Message::Text(resp.to_string())).await;
                                            }
                                        } else {
                                            let status = deploy_ea_to_mt5();
                                            let resp = DeployResponse {
                                                msg_type: "deploy_status".to_string(),
                                                status: if status { "success".to_string() } else { "error".to_string() },
                                            };
                                            let _ = write.send(Message::Text(serde_json::to_string(&resp).unwrap())).await;
                                        }
                                    }
                                    "update_ea" => {
                                        info!("🔄 [UI] Updating EA on MT5...");
                                        let status = deploy_ea_to_mt5();
                                        let resp = serde_json::json!({
                                            "type": "update_status",
                                            "status": if status { "success" } else { "error" },
                                            "latest_version": LATEST_EA_VERSION,
                                        });
                                        let _ = write.send(Message::Text(resp.to_string())).await;
                                    }
                                    _ => {}
                                }
                            }
                        }
                    }
                    Some(Ok(Message::Close(_))) | None => break,
                    Some(Err(e)) => {
                        error!("❌ [UI] Error {}: {}", peer_addr, e);
                        break;
                    }
                    _ => {}
                }
            }

            tick_result = rx.recv() => {
                match tick_result {
                    Ok(json) => {
                        // Forward ticks AND ea_info to UI
                        if json.contains("\"tick\"") || json.contains("\"ea_info\"") {
                            if let Err(e) = write.send(Message::Text(json)).await {
                                error!("❌ [UI] Send error to {}: {}", peer_addr, e);
                                break;
                            }
                        }
                    }
                    Err(_) => break,
                }
            }
        }
    }
    info!("🔌 [UI] Connection closed: {}", peer_addr);
}

// ──────────────────────────────────────────────
//  EA Deployment Logic
// ──────────────────────────────────────────────

fn deploy_ea_to_mt5() -> bool {
    let source_mq5 = PathBuf::from("mt5/EATradingClient.mq5");
    let source_ex5 = PathBuf::from("mt5/EATradingClient.ex5");

    if !source_mq5.exists() {
        error!("EA source file not found at {:?}", source_mq5);
        return false;
    }

    let appdata = std::env::var("APPDATA")
        .unwrap_or_else(|_| "C:\\Users\\Default\\AppData\\Roaming".to_string());
    let terminal_path = PathBuf::from(&appdata).join("MetaQuotes").join("Terminal");

    if !terminal_path.exists() {
        error!("MT5 Terminal folder not found: {:?}", terminal_path);
        return false;
    }

    let mut success = false;
    let mut target_instance: Option<PathBuf> = None;

    if let Ok(entries) = std::fs::read_dir(&terminal_path) {
        for entry in entries.flatten() {
            let path = entry.path();
            if path.is_dir() {
                let experts_dir = path.join("MQL5").join("Experts");
                if experts_dir.exists() {
                    let dest_mq5 = experts_dir.join("EATradingClient.mq5");
                    match std::fs::copy(&source_mq5, &dest_mq5) {
                        Ok(_) => {
                            info!("✅ Deployed EA source to {:?}", dest_mq5);
                            success = true;
                            if target_instance.is_none() {
                                target_instance = Some(path.clone());
                            }
                        }
                        Err(e) => error!("❌ Failed to copy to {:?}: {}", dest_mq5, e),
                    }
                    if source_ex5.exists() {
                        let dest_ex5 = experts_dir.join("EATradingClient.ex5");
                        if let Ok(_) = std::fs::copy(&source_ex5, &dest_ex5) {
                            info!("✅ Deployed compiled EA to {:?}", dest_ex5);
                        }
                    }
                }
            }
        }
    }

    if success {
        if let Some(instance_dir) = target_instance {
            launch_mt5_instance(&instance_dir);
        }
    }

    success
}

/// Parse UTF-16LE `origin.txt` and spawn MT5 with a custom `.ini` to auto-attach the EA.
fn launch_mt5_instance(instance_dir: &Path) {
    info!("🚀 Attempting to auto-launch MT5 from {:?}", instance_dir);

    let origin_file = instance_dir.join("origin.txt");
    if !origin_file.exists() {
        error!("origin.txt not found in {:?}", instance_dir);
        return;
    }

    let origin_bytes = match std::fs::read(&origin_file) {
        Ok(b) => b,
        Err(e) => {
            error!("Failed to read origin.txt: {}", e);
            return;
        }
    };

    let u16_chars: Vec<u16> = origin_bytes
        .chunks_exact(2)
        .map(|chunk| u16::from_le_bytes([chunk[0], chunk[1]]))
        .collect();
    let decoded_path = String::from_utf16_lossy(&u16_chars);
    let install_dir = decoded_path
        .trim_start_matches('\u{feff}')
        .trim_end_matches('\0')
        .trim()
        .to_string();

    let exe_path = PathBuf::from(&install_dir).join("terminal64.exe");
    if !exe_path.exists() {
        error!("terminal64.exe not found at {:?}", exe_path);
        return;
    }

    // Kill any running MT5 first
    info!("⏳ Killing existing MT5 instances...");
    let _ = std::process::Command::new("taskkill")
        .args(&["/F", "/IM", "terminal64.exe"])
        .output();
    std::thread::sleep(std::time::Duration::from_secs(2));

    let config_dir = instance_dir.join("config");
    if !config_dir.exists() {
        let _ = std::fs::create_dir_all(&config_dir);
    }
    let ini_path = config_dir.join("ea_startup.ini");

    let ini_content = "\
[Charts]
Chart1=XAUUSD,M1

[StartUp]
Expert=Experts\\EATradingClient
Symbol=XAUUSD
Period=M1
";
    if let Err(e) = std::fs::write(&ini_path, &ini_content) {
        error!("Failed to write config: {}", e);
        return;
    }

    let config_arg = format!("/config:{}", ini_path.to_string_lossy());
    info!("🚀 Spawning: {:?} {}", exe_path, config_arg);
    match std::process::Command::new(&exe_path)
        .arg(&config_arg)
        .spawn()
    {
        Ok(_) => info!("✅ Successfully launched MT5!"),
        Err(e) => error!("❌ Failed to spawn MT5: {}", e),
    }
}
