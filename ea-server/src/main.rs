#![cfg_attr(target_os = "windows", windows_subsystem = "windows")]

mod db;
mod updater;
#[cfg(target_os = "windows")]
mod tray;
#[cfg(not(target_os = "windows"))]
mod tray {
    #[allow(dead_code)]
    pub struct TrayState { pub server_online: bool, pub ea_connected: bool, pub ea_version: String, pub ea_symbol: String, pub last_error: Option<String> }
    impl Default for TrayState { fn default() -> Self { Self { server_online: true, ea_connected: false, ea_version: "—".into(), ea_symbol: String::new(), last_error: None } } }
    pub fn run_tray(_rx: tokio::sync::watch::Receiver<TrayState>) { loop { std::thread::park(); } }
}

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

#[cfg(target_os = "windows")]
use std::os::windows::process::CommandExt;

/// Creates a new `Command` that runs without a console window on Windows.
fn new_hidden_cmd<S: AsRef<std::ffi::OsStr>>(program: S) -> std::process::Command {
    #[allow(unused_mut)]
    let mut cmd = std::process::Command::new(program);
    #[cfg(target_os = "windows")]
    {
        const CREATE_NO_WINDOW: u32 = 0x08000000;
        cmd.creation_flags(CREATE_NO_WINDOW);
    }
    cmd
}

/// The latest EA version shipped with this server
const LATEST_EA_VERSION: &str = "2.04";

// ──────────────────────────────────────────────
//  Structs
// ──────────────────────────────────────────────

#[derive(Debug, Deserialize)]
struct ClientMessage {
    action: Option<String>,
    instance_id: Option<String>,
    config_key: Option<String>,
    config_value: Option<String>,
    // Trade setup fields
    setup_id: Option<i64>,
    symbol: Option<String>,
    strategy: Option<String>,
    timeframe: Option<String>,
    lot_size: Option<f64>,
    risk_percent: Option<f64>,
    mt5_instance: Option<String>,
    tp_enabled: Option<bool>,
    tp_mode: Option<String>,
    tp_value: Option<f64>,
    sl_enabled: Option<bool>,
    sl_mode: Option<String>,
    sl_value: Option<f64>,
    trailing_stop_enabled: Option<bool>,
    trailing_stop_points: Option<f64>,
    // Trading command fields
    direction: Option<String>,
    ticket: Option<i64>,
    sl: Option<f64>,
    tp: Option<f64>,
    comment: Option<String>,
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
    // Redirect log output to file (no console window available)
    let log_file = std::fs::File::create("ea-server.log").ok();
    let mut builder = env_logger::Builder::from_env(env_logger::Env::default().default_filter_or("info"));
    if let Some(file) = log_file {
        builder.target(env_logger::Target::Pipe(Box::new(file)));
    }
    builder.init();

    // Watch channel: server → tray
    let (tray_tx, tray_rx) = watch::channel(TrayState::default());
    let tray_tx = Arc::new(tray_tx);

    // Spawn tokio runtime on a background thread
    let tray_tx_clone = tray_tx.clone();
    std::thread::spawn(move || {
        match tokio::runtime::Runtime::new() {
            Ok(rt) => {
                rt.block_on(async move {
                    run_server(tray_tx_clone).await;
                });
            }
            Err(e) => {
                let _ = tray_tx_clone.send(TrayState {
                    server_online: false,
                    last_error: Some(format!("Runtime error: {}", e)),
                    ..TrayState::default()
                });
            }
        }
    });

    // Run the system tray on the main thread (Windows requires this)
    info!("🖥️  Starting system tray...");
    tray::run_tray(tray_rx);
}

async fn run_server(tray_tx: Arc<watch::Sender<TrayState>>) {
    let ws_addr: std::net::SocketAddr = "0.0.0.0:8080".parse().unwrap();
    let mt5_addr: std::net::SocketAddr = "0.0.0.0:8081".parse().unwrap();
    let http_addr: std::net::SocketAddr = "0.0.0.0:4173".parse().unwrap();

    let ws_listener = create_reuse_listener(ws_addr);
    let mt5_listener = create_reuse_listener(mt5_addr);
    let http_listener = create_reuse_listener(http_addr);

    // Initialize SQLite database
    let database = match db::Database::init("data/ea24.db") {
        Ok(db) => Arc::new(db),
        Err(e) => {
            error!("❌ Failed to initialize database: {}", e);
            error!("   Server will continue without database logging.");
            // Create in-memory fallback
            Arc::new(db::Database::init(":memory:").expect("Failed even in-memory DB"))
        }
    };

    info!("✅ ea-server WebSocket listening on ws://{}", ws_addr);
    info!("✅ ea-server MT5 TCP listening on {}", mt5_addr);
    info!("🌐 ea-server Web Dashboard on http://{}", http_addr);
    info!("🚀 ea-server v{} is starting up...", env!("CARGO_PKG_VERSION"));
    info!("📦 EA script version mapping: v{}", LATEST_EA_VERSION);

    // Call updater asynchronously in a background loop every 2 hours
    tokio::spawn(async {
        loop {
            crate::updater::check_and_update(None).await;
            tokio::time::sleep(tokio::time::Duration::from_secs(7200)).await;
        }
    });

    let active_eas = Arc::new(AtomicUsize::new(0));
    let ea_state = Arc::new(RwLock::new(EaState {
        connected: false,
        version: "unknown".to_string(),
        symbol: "".to_string(),
    }));

    let (tx, _rx) = broadcast::channel::<String>(100);

    // Spawn HTTP static file server (serves React dist/)
    tokio::spawn(async move {
        info!("🌐 Serving web dashboard from dist/ folder...");
        while let Ok((stream, peer_addr)) = http_listener.accept().await {
            tokio::spawn(handle_http_request(stream, peer_addr));
        }
    });

    // Spawn MT5 TCP Listener
    let tx_mt5 = tx.clone();
    let active_eas_mt5 = active_eas.clone();
    let ea_state_mt5 = ea_state.clone();
    let tray_tx_mt5 = tray_tx.clone();
    let db_mt5 = database.clone();
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
                db_mt5.clone(),
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
            database.clone(),
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
    db: Arc<db::Database>,
) {
    info!("🔗 [MT5] New connection from: {}", peer_addr);
    active_eas.fetch_add(1, Ordering::SeqCst);

    let (reader, mut writer) = stream.split();
    let mut buf_reader = BufReader::new(reader);
    let mut line = String::new();

    let mut digits_map: std::collections::HashMap<String, i64> = std::collections::HashMap::new();
    let mut last_risk_alert = std::time::Instant::now() - std::time::Duration::from_secs(3600);

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
                                        last_error: None,
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
                                // Parse JSON to log specific types to database
                                if let Ok(val) = serde_json::from_str::<serde_json::Value>(&text) {
                                    let msg_type = val.get("type").and_then(|t| t.as_str());
                                    if msg_type == Some("tick") {
                                        let sym = val["symbol"].as_str().unwrap_or("");
                                        let bid = val["bid"].as_f64().unwrap_or(0.0);
                                        let ask = val["ask"].as_f64().unwrap_or(0.0);
                                        let spread = val["spread"].as_f64().unwrap_or(0.0);
                                        if !sym.is_empty() {
                                            db.log_tick(sym, bid, ask, spread);
                                        }
                                    } else if msg_type == Some("market_watch") {
                                        if let Some(symbols) = val.get("symbols").and_then(|s| s.as_array()) {
                                            for info in symbols {
                                                let sym = info["symbol"].as_str().unwrap_or("");
                                                let digits = info["digits"].as_i64().unwrap_or(5);
                                                if !sym.is_empty() {
                                                    digits_map.insert(sym.to_string(), digits);
                                                }
                                            }
                                        }
                                    } else if msg_type == Some("trade_history") {
                                        if let Some(deals) = val.get("deals") {
                                            db.save_trade_history(deals);
                                        }
                                    } else if msg_type == Some("account_data") {
                                        // Server-side trailing stop
                                        if let Some(positions) = val.get("positions").and_then(|p| p.as_array()) {
                                            // 1. Risk Alert Logic
                                            let balance = val["balance"].as_f64().unwrap_or(0.0);
                                            let mut risk_usd = 0.0;
                                            for p in positions {
                                                let pnl = p["pnl"].as_f64().unwrap_or(0.0);
                                                if pnl < 0.0 { risk_usd += pnl.abs(); }
                                            }
                                            let risk_pct = if balance > 0.0 { (risk_usd / balance) * 100.0 } else { 0.0 };
                                            if risk_pct > 5.0 && last_risk_alert.elapsed().as_secs() > 300 {
                                                info!("🚨 [ALERT] Risk is high: {:.2}%", risk_pct);
                                                let alert_msg = serde_json::json!({
                                                    "type": "alert",
                                                    "level": "warning",
                                                    "title": "High Risk Warning",
                                                    "message": format!("Current floating drawdown is {:.2}%", risk_pct)
                                                }).to_string();
                                                let _ = tx.send(alert_msg);
                                                last_risk_alert = std::time::Instant::now();
                                            }

                                            // 2. Trailing Stop Logic
                                            let setups = db.get_trade_setups();
                                            if let Some(setups_arr) = setups.as_array() {
                                                let mut ts_configs = std::collections::HashMap::new();
                                                for setup in setups_arr {
                                                    if setup["status"].as_str() == Some("active") 
                                                        && setup["trailing_stop_enabled"].as_i64() == Some(1) {
                                                        let sym = setup["symbol"].as_str().unwrap_or("").to_string();
                                                        let pts = setup["trailing_stop_points"].as_f64().unwrap_or(0.0);
                                                        ts_configs.insert(sym, pts);
                                                    }
                                                }

                                                for pos in positions {
                                                    let ticket = pos["ticket"].as_i64().unwrap_or(0);
                                                    let sym = pos["symbol"].as_str().unwrap_or("");
                                                    let type_str = pos["type"].as_str().unwrap_or(""); 
                                                    let current_price = pos["current_price"].as_f64().unwrap_or(0.0);
                                                    let current_sl = pos["sl"].as_f64().unwrap_or(0.0);
                                                    
                                                    if let Some(&ts_pts) = ts_configs.get(sym) {
                                                        let digits = *digits_map.get(sym).unwrap_or(&5);
                                                        let point = 1.0 / 10f64.powi(digits as i32);
                                                        let distance = ts_pts * point;

                                                        let (new_sl, needs_update) = if type_str == "BUY" {
                                                            let calc_sl = current_price - distance;
                                                            (calc_sl, calc_sl > current_sl && calc_sl < current_price)
                                                        } else if type_str == "SELL" {
                                                            let calc_sl = current_price + distance;
                                                            (calc_sl, (current_sl == 0.0 || calc_sl < current_sl) && calc_sl > current_price)
                                                        } else {
                                                            (0.0, false)
                                                        };
                                                        
                                                        // Require at least 2 pips (20 points) improvement to avoid spamming modification
                                                        let min_step = 20.0 * point;
                                                        let significant_change = if type_str == "BUY" {
                                                            new_sl - current_sl >= min_step
                                                        } else {
                                                            current_sl == 0.0 || current_sl - new_sl >= min_step
                                                        };

                                                        if needs_update && significant_change {
                                                            info!("🔄 [TS] Modifying SL for {} ticket {} to {:.5}", sym, ticket, new_sl);
                                                            let cmd = serde_json::json!({
                                                                "action": "modify_sl",
                                                                "ticket": ticket,
                                                                "new_sl": new_sl
                                                            }).to_string();
                                                            let _ = tx.send(cmd.clone());
                                                            
                                                            let alert_msg = serde_json::json!({
                                                                "type": "alert",
                                                                "level": "info",
                                                                "title": "Trailing Stop Activated",
                                                                "message": format!("Moved {} SL to {:.5}", sym, new_sl)
                                                            }).to_string();
                                                            let _ = tx.send(alert_msg);
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
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
        last_error: None,
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
    _active_eas: Arc<AtomicUsize>,
    ea_state: Arc<RwLock<EaState>>,
    db: Arc<db::Database>,
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
        "server_version": env!("CARGO_PKG_VERSION"),
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
                                        // Handled by the second deploy_ea_to block below (with MetaEditor support)
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
                                    "open_trade" => {
                                        let sym = client_msg.symbol.as_deref().unwrap_or("XAUUSD");
                                        let dir = client_msg.direction.as_deref().unwrap_or("BUY");
                                        let lot = client_msg.lot_size.unwrap_or(0.01);
                                        let sl_val = client_msg.sl.unwrap_or(0.0);
                                        let tp_val = client_msg.tp.unwrap_or(0.0);
                                        let cmt = client_msg.comment.as_deref().unwrap_or("EA-Web");
                                        info!("📈 [UI] OPEN TRADE: {} {} {} SL={} TP={}", sym, dir, lot, sl_val, tp_val);
                                        let cmd = serde_json::json!({
                                            "action": "open_trade",
                                            "symbol": sym,
                                            "direction": dir,
                                            "lot_size": lot,
                                            "sl": sl_val,
                                            "tp": tp_val,
                                            "comment": cmt,
                                        }).to_string();
                                        let _ = tx.send(cmd);
                                    }
                                    "close_trade" => {
                                        if let Some(ticket) = client_msg.ticket {
                                            info!("📉 [UI] CLOSE TRADE: ticket={}", ticket);
                                            let cmd = serde_json::json!({
                                                "action": "close_trade",
                                                "ticket": ticket,
                                            }).to_string();
                                            let _ = tx.send(cmd);
                                        }
                                    }
                                    "modify_sl" => {
                                        if let (Some(ticket), Some(new_sl)) = (client_msg.ticket, client_msg.sl) {
                                            info!("🔧 [UI] MODIFY SL: ticket={} sl={}", ticket, new_sl);
                                            let cmd = serde_json::json!({
                                                "action": "modify_sl",
                                                "ticket": ticket,
                                                "new_sl": new_sl,
                                            }).to_string();
                                            let _ = tx.send(cmd);
                                        }
                                    }
                                    "close_mt5" => {
                                        let instance_id = client_msg.instance_id.clone().unwrap_or_default();
                                        info!("🛑 [UI] Closing MT5 for: {}", instance_id);
                                        let _ = new_hidden_cmd("taskkill")
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
                                    "check_update" => {
                                        info!("🔄 [UI] Manual update check triggered.");
                                        let check_tx = tx.clone();
                                        tokio::spawn(async move {
                                            crate::updater::check_and_update(Some(check_tx)).await;
                                        });
                                        let resp = serde_json::json!({
                                            "type": "update_status",
                                            "status": "checking",
                                            "message": "Checking GitHub for updates..."
                                        });
                                        let _ = write.send(Message::Text(resp.to_string())).await;
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
                                        let _ = new_hidden_cmd(&exe).spawn();
                                        // Small delay for new process to start
                                        tokio::time::sleep(std::time::Duration::from_millis(500)).await;
                                        info!("👋 Old server exiting...");
                                        std::process::exit(0);
                                    }
                                    _ => {}
                                }

                                // === Database Actions ===
                                match action.as_str() {
                                    "get_db_stats" => {
                                        info!("📊 [UI] DB stats requested");
                                        let stats = db.get_stats();
                                        let resp = serde_json::json!({
                                            "type": "db_stats",
                                            "stats": stats,
                                        });
                                        let _ = write.send(Message::Text(resp.to_string())).await;
                                    }
                                    "get_server_config" => {
                                        info!("⚙️ [UI] Config requested");
                                        let config = db.get_all_config();
                                        let resp = serde_json::json!({
                                            "type": "server_config",
                                            "config": config,
                                        });
                                        let _ = write.send(Message::Text(resp.to_string())).await;
                                    }
                                    "set_server_config" => {
                                        if let (Some(key), Some(value)) = (&client_msg.config_key, &client_msg.config_value) {
                                            info!("💾 [UI] Config set: {} = {}", key, value);
                                            db.set_config(key, value);
                                            let resp = serde_json::json!({
                                                "type": "config_saved",
                                                "status": "success",
                                                "key": key,
                                            });
                                            let _ = write.send(Message::Text(resp.to_string())).await;
                                        }
                                    }
                                    "vacuum_db" => {
                                        info!("🧹 [UI] VACUUM requested");
                                        let success = db.vacuum();
                                        let stats = db.get_stats();
                                        let resp = serde_json::json!({
                                            "type": "vacuum_result",
                                            "status": if success { "success" } else { "error" },
                                            "stats": stats,
                                        });
                                        let _ = write.send(Message::Text(resp.to_string())).await;
                                    }
                                    // === Trade Setup Actions ===
                                    "get_trade_setups" => {
                                        let setups = db.get_trade_setups();
                                        let resp = serde_json::json!({
                                            "type": "trade_setups",
                                            "setups": setups,
                                        });
                                        let _ = write.send(Message::Text(resp.to_string())).await;
                                    }
                                    "get_trade_history" => {
                                        let history = db.get_trade_history();
                                        let resp = serde_json::json!({
                                            "type": "trade_history_db",
                                            "deals": history,
                                        });
                                        let _ = write.send(Message::Text(resp.to_string())).await;
                                    }
                                    "add_trade_setup" => {
                                        let sym = client_msg.symbol.as_deref().unwrap_or("EURUSD");
                                        let strat = client_msg.strategy.as_deref().unwrap_or("Scalper Pro");
                                        let tf = client_msg.timeframe.as_deref().unwrap_or("M5");
                                        let lot = client_msg.lot_size.unwrap_or(0.01);
                                        let risk = client_msg.risk_percent.unwrap_or(2.0);
                                        let mt5_inst = client_msg.mt5_instance.as_deref().unwrap_or("");
                                        let tp_en = client_msg.tp_enabled.unwrap_or(false);
                                        let tp_m = client_msg.tp_mode.as_deref().unwrap_or("pips");
                                        let tp_v = client_msg.tp_value.unwrap_or(50.0);
                                        let sl_en = client_msg.sl_enabled.unwrap_or(false);
                                        let sl_m = client_msg.sl_mode.as_deref().unwrap_or("pips");
                                        let sl_v = client_msg.sl_value.unwrap_or(30.0);
                                        let ts_en = client_msg.trailing_stop_enabled.unwrap_or(false);
                                        let ts_pts = client_msg.trailing_stop_points.unwrap_or(50.0);
                                        if let Some(id) = db.add_trade_setup(sym, strat, tf, lot, risk, mt5_inst, tp_en, tp_m, tp_v, sl_en, sl_m, sl_v, ts_en, ts_pts) {
                                            let setups = db.get_trade_setups();
                                            let resp = serde_json::json!({
                                                "type": "trade_setups",
                                                "setups": setups,
                                                "added_id": id,
                                            });
                                            let _ = write.send(Message::Text(resp.to_string())).await;
                                        }
                                    }
                                    "toggle_trade_setup" => {
                                        if let Some(id) = client_msg.setup_id {
                                            // Get current status then toggle
                                            let current = db.get_trade_setups();
                                            if let Some(arr) = current.as_array() {
                                                for s in arr {
                                                    if s["id"].as_i64() == Some(id) {
                                                        let new_status = if s["status"].as_str() == Some("active") { "paused" } else { "active" };
                                                        db.update_trade_setup_status(id, new_status);
                                                    }
                                                }
                                            }
                                            let setups = db.get_trade_setups();
                                            let resp = serde_json::json!({
                                                "type": "trade_setups",
                                                "setups": setups,
                                            });
                                            let _ = write.send(Message::Text(resp.to_string())).await;
                                        }
                                    }
                                    "delete_trade_setup" => {
                                        if let Some(id) = client_msg.setup_id {
                                            db.delete_trade_setup(id);
                                            let setups = db.get_trade_setups();
                                            let resp = serde_json::json!({
                                                "type": "trade_setups",
                                                "setups": setups,
                                            });
                                            let _ = write.send(Message::Text(resp.to_string())).await;
                                        }
                                    }
                                    "update_trade_setup" => {
                                        if let Some(id) = client_msg.setup_id {
                                            let sym = client_msg.symbol.as_deref().unwrap_or("EURUSD");
                                            let strat = client_msg.strategy.as_deref().unwrap_or("Scalper Pro");
                                            let tf = client_msg.timeframe.as_deref().unwrap_or("M5");
                                            let lot = client_msg.lot_size.unwrap_or(0.01);
                                            let risk = client_msg.risk_percent.unwrap_or(2.0);
                                            let mt5_inst = client_msg.mt5_instance.as_deref().unwrap_or("");
                                            let tp_en = client_msg.tp_enabled.unwrap_or(false);
                                            let tp_m = client_msg.tp_mode.as_deref().unwrap_or("pips");
                                            let tp_v = client_msg.tp_value.unwrap_or(50.0);
                                            let sl_en = client_msg.sl_enabled.unwrap_or(false);
                                            let sl_m = client_msg.sl_mode.as_deref().unwrap_or("pips");
                                            let sl_v = client_msg.sl_value.unwrap_or(30.0);
                                            let ts_en = client_msg.trailing_stop_enabled.unwrap_or(false);
                                            let ts_pts = client_msg.trailing_stop_points.unwrap_or(50.0);
                                            db.update_trade_setup(id, sym, strat, tf, lot, risk, mt5_inst, tp_en, tp_m, tp_v, sl_en, sl_m, sl_v, ts_en, ts_pts);
                                            let setups = db.get_trade_setups();
                                            let resp = serde_json::json!({
                                                "type": "trade_setups",
                                                "setups": setups,
                                            });
                                            let _ = write.send(Message::Text(resp.to_string())).await;
                                        }
                                    }
                                    "get_running_mt5" => {
                                        let instances = scan_mt5_instances();
                                        let running: Vec<_> = instances.iter().filter(|i| i.mt5_running).collect();
                                        let arr: Vec<serde_json::Value> = running.iter().map(|i| {
                                            serde_json::json!({
                                                "id": i.id,
                                                "broker_name": i.broker_name,
                                                "ea_deployed": i.ea_deployed,
                                            })
                                        }).collect();
                                        let resp = serde_json::json!({
                                            "type": "running_mt5",
                                            "instances": arr,
                                        });
                                        let _ = write.send(Message::Text(resp.to_string())).await;
                                    }
                                    "deploy_ea_to" => {
                                        if let Some(instance_id) = client_msg.instance_id.as_deref() {
                                            let instances = scan_mt5_instances();
                                            let result = if let Some(inst) = instances.iter().find(|i| i.id == instance_id) {
                                                let appdata = std::env::var("APPDATA").unwrap_or_default();
                                                let experts_dir = PathBuf::from(&appdata)
                                                    .join("MetaQuotes").join("Terminal").join(instance_id)
                                                    .join("MQL5").join("Experts");
                                                let dest_mq5 = experts_dir.join("EATradingClient.mq5");

                                                // Copy .mq5 source
                                                let src_mq5 = PathBuf::from("mt5").join("EATradingClient.mq5");
                                                if src_mq5.exists() {
                                                    std::fs::create_dir_all(&experts_dir).ok();
                                                    match std::fs::copy(&src_mq5, &dest_mq5) {
                                                        Ok(_) => {
                                                            info!("✅ EA .mq5 copied to {:?}", dest_mq5);

                                                            // Auto-compile with MetaEditor
                                                            let metaeditor = PathBuf::from(&inst.install_path).join("metaeditor64.exe");
                                                            if metaeditor.exists() {
                                                                info!("🔨 Compiling EA with MetaEditor...");
                                                                match new_hidden_cmd(&metaeditor)
                                                                    .arg(format!("/compile:{}", dest_mq5.display()))
                                                                    .arg("/log")
                                                                    .output()
                                                                {
                                                                    Ok(output) => {
                                                                        let ex5_path = experts_dir.join("EATradingClient.ex5");
                                                                        if ex5_path.exists() {
                                                                            info!("✅ EA compiled successfully: {:?}", ex5_path);
                                                                            "success"
                                                                        } else {
                                                                            error!("❌ Compile failed — .ex5 not found. Exit: {}", output.status);
                                                                            "compile_failed"
                                                                        }
                                                                    }
                                                                    Err(e) => {
                                                                        error!("❌ MetaEditor launch failed: {}", e);
                                                                        "compile_error"
                                                                    }
                                                                }
                                                            } else {
                                                                warn!("⚠️ MetaEditor not found, .mq5 copied but not compiled");
                                                                "copied_only"
                                                            }
                                                        }
                                                        Err(e) => {
                                                            error!("❌ Copy failed: {}", e);
                                                            "copy_failed"
                                                        }
                                                    }
                                                } else {
                                                    error!("❌ Source EA not found: {:?}", src_mq5);
                                                    "source_not_found"
                                                }
                                            } else {
                                                "instance_not_found"
                                            };
                                            let resp = serde_json::json!({
                                                "type": "deploy_status",
                                                "instance_id": instance_id,
                                                "status": result,
                                            });
                                            let _ = write.send(Message::Text(resp.to_string())).await;
                                        }
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
                        // Forward ticks, ea_info, account_data, market_watch, alerts, and trade commands to UI
                        if json.contains("\"tick\"") || json.contains("\"ea_info\"") || json.contains("\"account_data\"") || json.contains("\"market_watch\"") || json.contains("\"trade_result\"") || json.contains("\"trade_history\"") || json.contains("\"update_status\"") || json.contains("\"alert\"") || json.contains("\"modify_sl\"") {
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

// NOTE: deploy_ea_to_instance() was removed — its logic is fully handled
// inside the WebSocket handler's "deploy_ea_to" action (with MetaEditor compile support).

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
        match new_hidden_cmd(&metaeditor)
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
        let _ = new_hidden_cmd("powershell")
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
            let _ = new_hidden_cmd("taskkill")
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
    match new_hidden_cmd(&exe_path).arg(&config_arg).spawn() {
        Ok(_) => info!("✅ Successfully launched MT5 with EA!"),
        Err(e) => error!("❌ Failed to spawn MT5: {}", e),
    }
}

/// Check if a specific MT5 instance is running by matching its install path
fn is_mt5_running(install_dir: &str) -> bool {
    // Use wmic to get full executable paths of all terminal64.exe processes
    match new_hidden_cmd("wmic")
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


use rust_embed::RustEmbed;

#[derive(RustEmbed)]
#[folder = "../ea-client/dist/"]
struct WebAssets;

async fn handle_http_request(mut stream: TcpStream, _peer_addr: SocketAddr) {
    use tokio::io::{AsyncReadExt, AsyncWriteExt};

    let mut buf = vec![0u8; 4096];
    let n = match stream.read(&mut buf).await {
        Ok(n) if n > 0 => n,
        _ => return,
    };

    let request = String::from_utf8_lossy(&buf[..n]);
    let path = request
        .lines()
        .next()
        .and_then(|line| line.split_whitespace().nth(1))
        .unwrap_or("/");

    let clean_path = path.split('?').next().unwrap_or(path);
    let mut relative = clean_path.trim_start_matches('/');

    if relative.is_empty() {
        relative = "index.html";
    }

    let mut asset = WebAssets::get(relative);

    // SPA fallback: if file doesn't exist and has no extension, serve index.html
    if asset.is_none() && !relative.contains('.') {
        asset = WebAssets::get("index.html");
    }

    let (status, body, content_type) = if let Some(file) = asset {
        let mime = mime_guess::from_path(relative).first_or_octet_stream();
        ("200 OK", file.data.into_owned(), mime.to_string())
    } else {
        (
            "404 Not Found",
            b"<h1>404 Not Found</h1><p>Not found in embedded assets.</p>".to_vec(),
            "text/html".to_string(),
        )
    };

    let response = format!(
        "HTTP/1.1 {}\r\nContent-Type: {}\r\nContent-Length: {}\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\n\r\n",
        status, content_type, body.len()
    );

    let _ = stream.write_all(response.as_bytes()).await;
    let _ = stream.write_all(&body).await;
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
