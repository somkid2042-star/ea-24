mod tray;

use std::net::SocketAddr;
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::Arc;

use futures_util::{SinkExt, StreamExt};
use log::{error, info, warn};
use serde::{Deserialize, Serialize};
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::net::{TcpListener, TcpStream};
use tokio::sync::{broadcast, watch, RwLock};
use tokio_tungstenite::tungstenite::Message;

use crate::tray::TrayState;

/// The latest EA version shipped with this server
const LATEST_EA_VERSION: &str = "2.01";

// ──────────────────────────────────────────────
//  Structs
// ──────────────────────────────────────────────

#[derive(Debug, Deserialize)]
struct ClientMessage {
    action: Option<String>,
    instance_id: Option<String>,
}

#[derive(Debug, Serialize, Clone)]
struct Mt5Instance {
    id: String,
    broker_name: String,
    install_path: String,
    terminal_exe: String,
    ea_deployed: bool,
    ea_version: String,
    has_experts_dir: bool,
    mt5_running: bool,
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

fn main() {
    env_logger::Builder::from_env(env_logger::Env::default().default_filter_or("info")).init();

    // Watch channel: server → tray
    let (tray_tx, tray_rx) = watch::channel(TrayState::default());
    let tray_tx = Arc::new(tray_tx);

    // Spawn tokio runtime on a background thread
    let tray_tx_clone = tray_tx.clone();
    std::thread::spawn(move || {
        let rt = tokio::runtime::Runtime::new().expect("Failed to create tokio runtime");
        rt.block_on(async move {
            run_server(tray_tx_clone).await;
        });
    });

    // Run the system tray on the main thread (Windows requires this)
    info!("🖥️  Starting system tray...");
    tray::run_tray(tray_rx);
}

async fn run_server(tray_tx: Arc<watch::Sender<TrayState>>) {
    let ws_addr: std::net::SocketAddr = "127.0.0.1:8080".parse().unwrap();
    let mt5_addr: std::net::SocketAddr = "127.0.0.1:8081".parse().unwrap();

    let ws_listener = create_reuse_listener(ws_addr);
    let mt5_listener = create_reuse_listener(mt5_addr);

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
    let tray_tx_mt5 = tray_tx.clone();
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
                tray_tx_mt5.clone(),
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
    tray_tx: Arc<watch::Sender<TrayState>>,
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

                                    // Update tray icon
                                    let _ = tray_tx.send(TrayState {
                                        server_online: true,
                                        ea_connected: true,
                                        ea_version: ver.clone(),
                                        ea_symbol: sym.clone(),
                                    });

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

    // Update tray icon
    let _ = tray_tx.send(TrayState {
        server_online: true,
        ea_connected: false,
        ea_version: "—".to_string(),
        ea_symbol: "".to_string(),
    });
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
                                    "scan_mt5" => {
                                        info!("🔍 [UI] Scanning MT5 instances...");
                                        let instances = scan_mt5_instances();
                                        let ea = ea_state.read().await;
                                        let resp = serde_json::json!({
                                            "type": "mt5_instances",
                                            "instances": instances,
                                            "ea_connected": ea.connected,
                                            "ea_version": ea.version,
                                            "ea_symbol": ea.symbol,
                                        });
                                        drop(ea);
                                        let _ = write.send(Message::Text(resp.to_string())).await;
                                    }
                                    "deploy_ea_to" => {
                                        let instance_id = client_msg.instance_id.clone().unwrap_or_default();
                                        info!("📦 [UI] Deploying EA to instance: {}", instance_id);
                                        let status = deploy_ea_to_instance(&instance_id);
                                        let resp = serde_json::json!({
                                            "type": "deploy_status",
                                            "status": if status { "success" } else { "error" },
                                            "instance_id": instance_id,
                                        });
                                        let _ = write.send(Message::Text(resp.to_string())).await;
                                    }
                                    "launch_mt5" => {
                                        let instance_id = client_msg.instance_id.clone().unwrap_or_default();
                                        info!("🚀 [UI] Launching MT5: {}", instance_id);
                                        let status = launch_mt5_by_id(&instance_id);
                                        let resp = serde_json::json!({
                                            "type": "launch_status",
                                            "status": if status { "success" } else { "error" },
                                            "instance_id": instance_id,
                                        });
                                        let _ = write.send(Message::Text(resp.to_string())).await;
                                    }

                                    "stop_trading" | "start_trading" => {
                                        info!("⚡ [UI] Forwarding {} to EA", action);
                                        let cmd = serde_json::json!({ "action": action }).to_string();
                                        let _ = tx.send(cmd);
                                    }
                                    "close_mt5" => {
                                        let instance_id = client_msg.instance_id.clone().unwrap_or_default();
                                        info!("🛑 [UI] Closing MT5 for: {}", instance_id);
                                        let _ = std::process::Command::new("taskkill")
                                            .args(&["/IM", "terminal64.exe"])
                                            .output();
                                        let resp = serde_json::json!({
                                            "type": "close_mt5_status",
                                            "status": "success",
                                            "instance_id": instance_id,
                                        });
                                        let _ = write.send(Message::Text(resp.to_string())).await;
                                    }
                                    "stop_server" => {
                                        warn!("🛑 [UI] STOP SERVER command received!");
                                        let resp = serde_json::json!({
                                            "type": "server_control",
                                            "status": "stopping",
                                        });
                                        let _ = write.send(Message::Text(resp.to_string())).await;
                                        // Give time for the response to be sent
                                        tokio::time::sleep(std::time::Duration::from_millis(300)).await;
                                        info!("👋 Server shutting down...");
                                        std::process::exit(0);
                                    }
                                    "restart_server" => {
                                        warn!("🔄 [UI] RESTART SERVER command received!");
                                        let resp = serde_json::json!({
                                            "type": "server_control",
                                            "status": "restarting",
                                        });
                                        let _ = write.send(Message::Text(resp.to_string())).await;
                                        tokio::time::sleep(std::time::Duration::from_millis(300)).await;
                                        // Spawn a new copy of ourselves before exiting
                                        let exe = std::env::current_exe().unwrap_or_default();
                                        info!("🔄 Spawning new server: {:?}", exe);
                                        let _ = std::process::Command::new(&exe).spawn();
                                        // Small delay for new process to start
                                        tokio::time::sleep(std::time::Duration::from_millis(500)).await;
                                        info!("👋 Old server exiting...");
                                        std::process::exit(0);
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
//  MT5 Auto-Discovery
// ──────────────────────────────────────────────

fn scan_mt5_instances() -> Vec<Mt5Instance> {
    let appdata = std::env::var("APPDATA")
        .unwrap_or_else(|_| "C:\\Users\\Default\\AppData\\Roaming".to_string());
    let terminal_path = PathBuf::from(&appdata).join("MetaQuotes").join("Terminal");

    let mut instances: Vec<Mt5Instance> = Vec::new();

    if !terminal_path.exists() {
        info!("MT5 Terminal folder not found: {:?}", terminal_path);
        return instances;
    }

    if let Ok(entries) = std::fs::read_dir(&terminal_path) {
        for entry in entries.flatten() {
            let path = entry.path();
            if !path.is_dir() {
                continue;
            }

            let folder_name = path.file_name().unwrap_or_default().to_string_lossy().to_string();
            if folder_name == "Common" || folder_name == "Community" {
                continue;
            }

            let origin_file = path.join("origin.txt");
            if !origin_file.exists() {
                continue;
            }

            // Read origin.txt (UTF-16LE) to get install path
            let install_dir = match std::fs::read(&origin_file) {
                Ok(bytes) => {
                    let u16_chars: Vec<u16> = bytes
                        .chunks_exact(2)
                        .map(|chunk| u16::from_le_bytes([chunk[0], chunk[1]]))
                        .collect();
                    String::from_utf16_lossy(&u16_chars)
                        .trim_start_matches('\u{feff}')
                        .trim_end_matches('\0')
                        .trim()
                        .to_string()
                }
                Err(_) => continue,
            };

            let broker_name = PathBuf::from(&install_dir)
                .file_name()
                .unwrap_or_default()
                .to_string_lossy()
                .to_string();

            let terminal_exe = PathBuf::from(&install_dir).join("terminal64.exe");
            let experts_dir = path.join("MQL5").join("Experts");
            let has_experts = experts_dir.exists();

            let ea_mq5 = experts_dir.join("EATradingClient.mq5");
            let ea_ex5 = experts_dir.join("EATradingClient.ex5");
            let ea_deployed = ea_mq5.exists() || ea_ex5.exists();

            let ea_version = if ea_mq5.exists() {
                read_ea_version_from_mq5(&ea_mq5)
            } else if ea_deployed {
                "compiled-only".to_string()
            } else {
                "-".to_string()
            };

            // Check if this MT5 instance is currently running
            let mt5_running = is_mt5_running(&install_dir);

            info!("🔍 Found MT5: {} ({}) EA={} v{} Running={}", broker_name, folder_name, ea_deployed, ea_version, mt5_running);

            instances.push(Mt5Instance {
                id: folder_name,
                broker_name,
                install_path: install_dir,
                terminal_exe: terminal_exe.to_string_lossy().to_string(),
                ea_deployed,
                ea_version,
                has_experts_dir: has_experts,
                mt5_running,
            });
        }
    }

    instances
}

fn read_ea_version_from_mq5(path: &Path) -> String {
    if let Ok(content) = std::fs::read_to_string(path) {
        for line in content.lines() {
            if line.contains("#define EA_VERSION") {
                if let Some(ver) = line.split('"').nth(1) {
                    return ver.to_string();
                }
            }
        }
    }
    "unknown".to_string()
}

fn deploy_ea_to_instance(instance_id: &str) -> bool {
    let source_mq5 = PathBuf::from("mt5/EATradingClient.mq5");
    let source_ex5 = PathBuf::from("mt5/EATradingClient.ex5");

    if !source_mq5.exists() {
        error!("EA source file not found at {:?}", source_mq5);
        return false;
    }

    let appdata = std::env::var("APPDATA")
        .unwrap_or_else(|_| "C:\\Users\\Default\\AppData\\Roaming".to_string());
    let instance_dir = PathBuf::from(&appdata)
        .join("MetaQuotes")
        .join("Terminal")
        .join(instance_id);

    if !instance_dir.exists() {
        error!("MT5 instance not found: {:?}", instance_dir);
        return false;
    }

    let experts_dir = instance_dir.join("MQL5").join("Experts");
    if !experts_dir.exists() {
        if let Err(e) = std::fs::create_dir_all(&experts_dir) {
            error!("Failed to create Experts dir: {}", e);
            return false;
        }
    }

    let dest_mq5 = experts_dir.join("EATradingClient.mq5");
    match std::fs::copy(&source_mq5, &dest_mq5) {
        Ok(_) => info!("✅ Deployed EA source to {:?}", dest_mq5),
        Err(e) => {
            error!("❌ Failed to copy to {:?}: {}", dest_mq5, e);
            return false;
        }
    }

    if source_ex5.exists() {
        let dest_ex5 = experts_dir.join("EATradingClient.ex5");
        if let Ok(_) = std::fs::copy(&source_ex5, &dest_ex5) {
            info!("✅ Deployed compiled EA to {:?}", dest_ex5);
        }
    }

    true
}

fn launch_mt5_by_id(instance_id: &str) -> bool {
    let appdata = std::env::var("APPDATA")
        .unwrap_or_else(|_| "C:\\Users\\Default\\AppData\\Roaming".to_string());
    let instance_dir = PathBuf::from(&appdata)
        .join("MetaQuotes")
        .join("Terminal")
        .join(instance_id);

    if !instance_dir.exists() {
        error!("MT5 instance not found: {:?}", instance_dir);
        return false;
    }

    launch_mt5_instance(&instance_dir);
    true
}



/// Parse UTF-16LE `origin.txt` and get the install directory
fn read_install_dir(instance_dir: &Path) -> Option<String> {
    let origin_file = instance_dir.join("origin.txt");
    if !origin_file.exists() {
        error!("origin.txt not found in {:?}", instance_dir);
        return None;
    }
    let origin_bytes = match std::fs::read(&origin_file) {
        Ok(b) => b,
        Err(e) => {
            error!("Failed to read origin.txt: {}", e);
            return None;
        }
    };
    let u16_chars: Vec<u16> = origin_bytes
        .chunks_exact(2)
        .map(|chunk| u16::from_le_bytes([chunk[0], chunk[1]]))
        .collect();
    let decoded_path = String::from_utf16_lossy(&u16_chars);
    Some(decoded_path
        .trim_start_matches('\u{feff}')
        .trim_end_matches('\0')
        .trim()
        .to_string())
}

/// Spawn MT5 with a custom `.ini` to auto-attach the EA on XAUUSD M1
fn launch_mt5_instance(instance_dir: &Path) {
    info!("🚀 Attempting to auto-launch MT5 from {:?}", instance_dir);

    let install_dir = match read_install_dir(instance_dir) {
        Some(d) => d,
        None => return,
    };

    let exe_path = PathBuf::from(&install_dir).join("terminal64.exe");
    if !exe_path.exists() {
        error!("terminal64.exe not found at {:?}", exe_path);
        return;
    }

    // Step 1: Ensure EA is compiled (.mq5 → .ex5)
    let ea_mq5 = instance_dir.join("MQL5").join("Experts").join("EATradingClient.mq5");
    let ea_ex5 = instance_dir.join("MQL5").join("Experts").join("EATradingClient.ex5");
    let metaeditor = PathBuf::from(&install_dir).join("metaeditor64.exe");

    // Only compile if .ex5 doesn't exist at all (per user request)
    let needs_compile = !ea_ex5.exists();

    if needs_compile && ea_mq5.exists() && metaeditor.exists() {
        info!("🔧 Compiling EA with MetaEditor (non-blocking)...");
        // Use spawn() instead of output() to avoid blocking
        match std::process::Command::new(&metaeditor)
            .args(&[
                "/compile", &ea_mq5.to_string_lossy(),
                "/log",
                "/include", &instance_dir.join("MQL5").to_string_lossy(),
            ])
            .spawn()
        {
            Ok(mut child) => {
                // Wait up to 10 seconds for compile
                let timeout = std::time::Duration::from_secs(10);
                let start = std::time::Instant::now();
                loop {
                    match child.try_wait() {
                        Ok(Some(_)) => {
                            info!("✅ MetaEditor compile finished");
                            break;
                        }
                        Ok(None) => {
                            if start.elapsed() > timeout {
                                info!("⏱️ MetaEditor timeout — killing process");
                                let _ = child.kill();
                                break;
                            }
                            std::thread::sleep(std::time::Duration::from_millis(500));
                        }
                        Err(e) => {
                            error!("❌ Error waiting for MetaEditor: {}", e);
                            break;
                        }
                    }
                }
                // Verify .ex5 was created
                if ea_ex5.exists() {
                    info!("✅ EA .ex5 found: {:?}", ea_ex5);
                } else {
                    error!("❌ EA .ex5 not found after compile");
                }
            }
            Err(e) => error!("❌ Failed to spawn MetaEditor: {}", e),
        }
    } else if ea_ex5.exists() {
        info!("✅ EA .ex5 already up to date, skipping compile");
    } else {
        if !ea_mq5.exists() { error!("EA source not found: {:?}", ea_mq5); }
        if !metaeditor.exists() { error!("MetaEditor not found: {:?}", metaeditor); }
    }

    // If MT5 is running, close gracefully first so it saves its state, then we can append to terminal.ini
    if is_mt5_running(&install_dir) {
        info!("⏳ Closing MT5 gracefully (saving session)...");
        let _ = std::process::Command::new("powershell")
            .args(&["-Command", &format!(
                "Get-Process terminal64 -ErrorAction SilentlyContinue | Where-Object {{ $_.Path -like '*{}*' }} | ForEach-Object {{ $_.CloseMainWindow() | Out-Null }}",
                install_dir.replace('\\', "\\\\")
            )])
            .output();

        for i in 0..20 {
            std::thread::sleep(std::time::Duration::from_millis(500));
            if !is_mt5_running(&install_dir) {
                info!("✅ MT5 closed gracefully after {}ms", (i+1) * 500);
                break;
            }
        }
        if is_mt5_running(&install_dir) {
            info!("⚠️ MT5 still running, force closing...");
            let _ = std::process::Command::new("taskkill")
                .args(&["/F", "/IM", "terminal64.exe"])
                .output();
            std::thread::sleep(std::time::Duration::from_secs(2));
        }
    }

    // Clone terminal.ini → ea_startup.ini, append [StartUp], launch with /config (absolute path)
    let terminal_ini_path = instance_dir.join("config").join("terminal.ini");
    let ea_startup_ini_path = instance_dir.join("config").join("ea_startup.ini");

    if terminal_ini_path.exists() {
        use std::io::Write;
        let bytes = std::fs::read(&terminal_ini_path).unwrap_or_default();
        let is_utf16le = bytes.starts_with(&[0xFF, 0xFE]);
        
        // Convert to String safely
        let content = if is_utf16le {
            let u16_data: Vec<u16> = bytes[2..]
                .chunks_exact(2)
                .map(|c| u16::from_le_bytes([c[0], c[1]]))
                .collect();
            String::from_utf16_lossy(&u16_data)
        } else {
            String::from_utf8_lossy(&bytes).into_owned()
        };

        // Parse into sections, removing ALL existing [StartUp] and [Experts] blocks
        let mut result_lines: Vec<String> = Vec::new();
        let mut skip_section = false;
        for line in content.lines() {
            let trimmed = line.trim().trim_matches('\0');
            if trimmed.starts_with('[') {
                // Check if this section should be skipped
                let section_lower = trimmed.to_lowercase();
                skip_section = section_lower == "[startup]" || section_lower == "[experts]";
            }
            if !skip_section && !trimmed.is_empty() {
                result_lines.push(line.to_string());
            }
        }

        // Append our clean EA startup config
        result_lines.push(String::new());
        result_lines.push("[StartUp]".to_string());
        result_lines.push("Expert=EATradingClient".to_string());
        result_lines.push("Symbol=XAUUSD".to_string());
        result_lines.push("Period=M1".to_string());
        result_lines.push(String::new());
        result_lines.push("[Experts]".to_string());
        result_lines.push("AllowLiveTrading=1".to_string());
        result_lines.push("Enabled=1".to_string());

        let final_text = result_lines.join("\r\n");

        // Write to ea_startup.ini (not terminal.ini — never touch the original)
        if let Ok(mut file) = std::fs::File::create(&ea_startup_ini_path) {
            info!("📝 Writing clean ea_startup.ini (UTF-16LE: {})", is_utf16le);
            if is_utf16le {
                let _ = file.write_all(&[0xFF, 0xFE]); // BOM
                let u16_chars: Vec<u16> = final_text.encode_utf16().collect();
                let u8_bytes: Vec<u8> = u16_chars.iter().flat_map(|&c| c.to_le_bytes().into_iter()).collect();
                let _ = file.write_all(&u8_bytes);
            } else {
                let _ = file.write_all(final_text.as_bytes());
            }
        }
    } else {
        error!("❌ terminal.ini not found at {:?}", terminal_ini_path);
        let fallback = "[StartUp]\r\nExpert=EATradingClient\r\nSymbol=XAUUSD\r\nPeriod=M1\r\n\r\n[Experts]\r\nAllowLiveTrading=1\r\nEnabled=1\r\n";
        let _ = std::fs::write(&ea_startup_ini_path, fallback);
    }

    // Launch MT5 with ABSOLUTE path to /config
    let config_arg = format!("/config:{}", ea_startup_ini_path.to_string_lossy());
    info!("🚀 Spawning: {:?} {}", exe_path, config_arg);
    match std::process::Command::new(&exe_path).arg(&config_arg).spawn() {
        Ok(_) => info!("✅ Successfully launched MT5 with EA!"),
        Err(e) => error!("❌ Failed to spawn MT5: {}", e),
    }
}

/// Check if a specific MT5 instance is running by matching its install path
fn is_mt5_running(install_dir: &str) -> bool {
    // Use wmic to get full executable paths of all terminal64.exe processes
    match std::process::Command::new("wmic")
        .args(&["process", "where", "name='terminal64.exe'", "get", "ExecutablePath", "/FORMAT:CSV"])
        .output()
    {
        Ok(output) => {
            let text = String::from_utf8_lossy(&output.stdout);
            // Normalize install_dir for comparison (lowercase, forward slashes)
            let normalized_install = install_dir.to_lowercase().replace('/', "\\");
            for line in text.lines() {
                let lower_line = line.to_lowercase();
                if lower_line.contains(&normalized_install) {
                    return true;
                }
            }
            false
        }
        Err(_) => false,
    }
}


// ──────────────────────────────────────────────
//  Socket Reuse Helper (SO_REUSEADDR)
// ──────────────────────────────────────────────

fn create_reuse_listener(addr: std::net::SocketAddr) -> TcpListener {
    for attempt in 1..=30 {
        let socket = socket2::Socket::new(
            socket2::Domain::IPV4,
            socket2::Type::STREAM,
            Some(socket2::Protocol::TCP),
        )
        .expect("Failed to create socket");

        socket.set_reuse_address(true).ok();

        match socket.bind(&addr.into()) {
            Ok(_) => {
                socket.listen(128).expect("Failed to listen");
                socket.set_nonblocking(true).expect("Failed to set nonblocking");
                info!("✅ Bound to {} (attempt {})", addr, attempt);
                return TcpListener::from_std(socket.into()).expect("Failed to convert listener");
            }
            Err(e) => {
                if attempt < 30 {
                    warn!("⏳ Port {} busy ({}), retrying in 2s... ({}/30)", addr.port(), e, attempt);
                    std::thread::sleep(std::time::Duration::from_secs(2));
                } else {
                    panic!("❌ Failed to bind to {} after 30 attempts: {}", addr, e);
                }
            }
        }
    }
    unreachable!()
}
