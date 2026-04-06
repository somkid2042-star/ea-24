// Removed windows subsystem


mod db;
mod updater;
mod strategy;
mod notify;
mod ai_engine;

use std::net::SocketAddr;
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::Arc;

use crate::ai_engine::{NewsResult, CalendarResult};

use futures_util::{SinkExt, StreamExt};
use log::{error, info, warn};
use serde::{Deserialize, Serialize};
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::net::{TcpListener, TcpStream};
use tokio::sync::{broadcast, RwLock};
use tokio_tungstenite::tungstenite::Message;




/// The latest EA version shipped with this server
const LATEST_EA_VERSION: &str = "2.14";

/// Compare version strings as floating point numbers.
/// Returns true if `latest` is strictly greater than `current`.
fn is_update_available(current: &str, latest: &str) -> bool {
    let cur: f64 = current.parse().unwrap_or(0.0);
    let lat: f64 = latest.parse().unwrap_or(0.0);
    lat > cur
}

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
    // Multi-Agent fields
    balance: Option<f64>,
    equity: Option<f64>,
    open_positions: Option<usize>,
    max_positions: Option<usize>,
    max_drawdown_pct: Option<f64>,
    emergency_stop: Option<bool>,
    // Trading command fields
    direction: Option<String>,
    ticket: Option<i64>,
    sl: Option<f64>,
    tp: Option<f64>,
    comment: Option<String>,
    // History request fields
    limit: Option<i64>,
    // Upload fields
    file_name: Option<String>,
    content_base64: Option<String>,
    // AI fields
    question: Option<String>,
    ai_mode: Option<String>,
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
    gap_status: std::collections::HashMap<String, String>,
    last_quote_times: std::collections::HashMap<String, i64>,
    balance: f64,
    equity: f64,
    open_positions: usize,
}

#[derive(Debug, Clone, Serialize)]
pub struct GlobalAiData {
    pub news: Option<NewsResult>,
    pub calendar: Option<CalendarResult>,
    pub macro_data: Option<ai_engine::MacroResult>,
    pub last_updated: i64,
}

// ──────────────────────────────────────────────
//  Main
// ──────────────────────────────────────────────

#[tokio::main]
async fn main() {
    // ---------------------------------------------------------
    // Kill any old ea-server processes before starting
    // ---------------------------------------------------------
    kill_old_instances();

    // ---------------------------------------------------------
    // Single Instance Lock
    // ---------------------------------------------------------
    let lock_addr = std::net::SocketAddr::from(([127, 0, 0, 1], 4174));
    let _app_lock = match std::net::UdpSocket::bind(lock_addr) {
        Ok(s) => s,
        Err(_) => {
            eprintln!("Another instance of EA Server is already running. Exiting.");
            std::process::exit(0);
        }
    };

    // Redirect log output to file (no console window available)
    let log_file = std::fs::File::create("ea-server.log").ok();
    let mut builder = env_logger::Builder::from_env(env_logger::Env::default().default_filter_or("info"));
    if let Some(file) = log_file {
        builder.target(env_logger::Target::Pipe(Box::new(file)));
    }
    builder.init();

    run_server().await;
}

/// Kill all other ea-server processes except the current one.
/// This ensures only ONE instance runs at a time after updates.
fn kill_old_instances() {
    let my_pid = std::process::id();
    let mut killed = 0;

    #[cfg(unix)]
    {
        // Scan /proc to find ea-server processes — skip our own PID
        if let Ok(entries) = std::fs::read_dir("/proc") {
            for entry in entries.flatten() {
                let pid_str = entry.file_name().to_string_lossy().to_string();
                if let Ok(pid) = pid_str.parse::<u32>() {
                    if pid == my_pid {
                        continue; // Don't kill ourselves!
                    }
                    let cmdline_path = format!("/proc/{}/cmdline", pid);
                    if let Ok(cmdline) = std::fs::read_to_string(&cmdline_path) {
                        if cmdline.contains("ea-server") {
                            eprintln!("🔪 Killing old ea-server process (PID: {})", pid);
                            unsafe { libc_kill(pid as i32, 9); }
                            killed += 1;
                        }
                    }
                }
            }
        }
    }

    if killed > 0 {
        eprintln!("✅ Killed {} old instance(s). Starting fresh (PID: {})...", killed, my_pid);
        // Give OS time to release ports
        std::thread::sleep(std::time::Duration::from_secs(2));
    } else {
        eprintln!("✅ No old instances found. Starting fresh (PID: {})...", my_pid);
    }
}

#[cfg(unix)]
extern "C" {
    fn kill(pid: i32, sig: i32) -> i32;
}

#[cfg(unix)]
unsafe fn libc_kill(pid: i32, sig: i32) {
    kill(pid, sig);
}

async fn run_server() {
    let ws_addr: std::net::SocketAddr = "0.0.0.0:8080".parse().unwrap();
    let mt5_addr: std::net::SocketAddr = "0.0.0.0:8081".parse().unwrap();
    let http_addr: std::net::SocketAddr = "0.0.0.0:4173".parse().unwrap();

    let ws_listener = create_reuse_listener(ws_addr);
    let mt5_listener = create_reuse_listener(mt5_addr);
    let http_listener = create_reuse_listener(http_addr);

    let _ = dotenvy::dotenv(); // Load .env file if it exists
    let db_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgres://postgres:postgres@localhost:5432/ea24".to_string());

    // Initialize PostgreSQL database
    let database = match db::Database::init(&db_url).await {
        Ok(db) => Arc::new(db),
        Err(e) => {
            error!("❌ Failed to initialize database: {}", e);
            error!("   Please check your PostgreSQL connection string inside .env (DATABASE_URL)");
            std::process::exit(1);
        }
    };

    info!("✅ ea-server WebSocket listening on ws://{}", ws_addr);
    info!("✅ ea-server MT5 TCP listening on {}", mt5_addr);
    info!("🌐 ea-server Web Dashboard on http://{}", http_addr);
    info!("🚀 ea-server v{} is starting up...", env!("CARGO_PKG_VERSION"));
    info!("📦 EA script version mapping: v{}", LATEST_EA_VERSION);

    let server_start = std::time::Instant::now();

    // Auto-update loop removed: Updater is now triggered manually via Dashboard UI

    // Automatically run React development server
    if std::path::Path::new("../ea-client").exists() {
        tokio::spawn(async {
            info!("⚡ Starting React development server...");
            let child = tokio::process::Command::new("npm")
                .arg("run")
                .arg("dev")
                .current_dir("../ea-client")
                .kill_on_drop(true)
                .spawn();
            
            match child {
                Ok(mut c) => {
                    let _ = c.wait().await;
                }
                Err(e) => {
                    log::warn!("Failed to start React dev server: {}", e);
                }
            }
        });
    }

    let active_eas = Arc::new(AtomicUsize::new(0));
    let ea_state = Arc::new(RwLock::new(EaState {
        connected: false,
        version: "unknown".to_string(),
        symbol: "".to_string(),
        gap_status: std::collections::HashMap::new(),
        last_quote_times: std::collections::HashMap::new(),
        balance: 0.0,
        equity: 0.0,
        open_positions: 0,
    }));

    let mut initial_news = None;
    let mut initial_calendar = None;
    let mut initial_last_updated = 0;
    
    if let Some(news_str) = database.get_config("global_news_cache").await {
        if let Ok(news) = serde_json::from_str::<NewsResult>(&news_str) {
            initial_news = Some(news);
        }
    }
    if let Some(cal_str) = database.get_config("global_calendar_cache").await {
        if let Ok(cal) = serde_json::from_str::<CalendarResult>(&cal_str) {
            initial_calendar = Some(cal);
        }
    }
    if let Some(lu_str) = database.get_config("global_news_last_updated").await {
        if let Ok(last) = lu_str.parse::<i64>() {
            initial_last_updated = last;
        }
    }
    
    let mut initial_macro = None;
    if let Some(m_str) = database.get_config("global_macro_cache").await {
        if let Ok(m) = serde_json::from_str::<ai_engine::MacroResult>(&m_str) {
            initial_macro = Some(m);
        }
    }

    let global_ai_data = Arc::new(RwLock::new(GlobalAiData {
        news: initial_news,
        calendar: initial_calendar,
        macro_data: initial_macro,
        last_updated: initial_last_updated,
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
                db_mt5.clone(),
            ));
        }
    });

    // Spawn AI Auto-Pilot loop
    let db_ai = database.clone();
    let tx_ai = tx.clone();
    let ea_state_ai = ea_state.clone();
    let global_ai_data_ai = global_ai_data.clone();
    tokio::spawn(async move {
        tokio::time::sleep(tokio::time::Duration::from_secs(10)).await;
        let mut last_runs: std::collections::HashMap<String, std::time::Instant> = std::collections::HashMap::new();

        loop {
            let auto_analyze = db_ai.get_config("ai_auto_analyze").await.unwrap_or_else(|| "false".to_string()) == "true";
            if auto_analyze {
                let jobs_str = db_ai.get_config("ai_autopilot_jobs").await.unwrap_or_else(|| "[]".to_string());
                let jobs: Vec<serde_json::Value> = serde_json::from_str(&jobs_str).unwrap_or_default();
                
                let gemini_key = db_ai.get_config("gemini_api_key").await.unwrap_or_default();
                let gemini_model = db_ai.get_config("gemini_model").await.unwrap_or_default();
                let tavily_key = db_ai.get_config("tavily_api_key").await.unwrap_or_default();
                let ai_mode = db_ai.get_config("ai_mode").await.unwrap_or_else(|| "auto".to_string());
                
                for job in jobs {
                    let sym = job["symbol"].as_str().unwrap_or("").to_uppercase();
                    if sym.is_empty() { continue; }
                    
                    let is_enabled = job["enabled"].as_bool().unwrap_or(true);
                    if !is_enabled { continue; }
                    
                    let interval_min = job["interval"].as_u64().unwrap_or(5);
                    let auto_trade = job["auto_trade"].as_bool().unwrap_or(false);
                    let fallback_lot = db_ai.get_config("ai_auto_lot_size").await.unwrap_or_else(|| "0.01".to_string()).parse().unwrap_or(0.01);
                    let auto_lot = job["lot_size"].as_f64().unwrap_or(fallback_lot);
                    
                    let telegram_alert = job["telegram_alert"].as_bool().unwrap_or(false);
                    let tp_sl_mode = job["tp_sl_mode"].as_str().unwrap_or("none");
                    let tp_value = job["tp_value"].as_f64().unwrap_or(0.0);
                    let sl_value = job["sl_value"].as_f64().unwrap_or(0.0);
                    let ts_value = job["ts_value"].as_f64().unwrap_or(0.0);

                    // Sync risk config to MT5 instantly anytime auto_analyze loops for this symbol
                    let risk_cmd = serde_json::json!({
                        "action": "set_risk_config",
                        "symbol": sym,
                        "risk_mode": tp_sl_mode,
                        "tp_value": tp_value,
                        "sl_value": sl_value,
                        "ts_value": ts_value
                    }).to_string();
                    let _ = tx_ai.send(risk_cmd);

                    let should_run = last_runs.get(&sym)
                        .map(|last| last.elapsed().as_secs() >= interval_min * 60)
                        .unwrap_or(true); // First run is always true!

                    if should_run {
                        last_runs.insert(sym.clone(), std::time::Instant::now());

                        let latest_tick = db_ai.get_latest_tick_timestamp(&sym).await;
                        let now_ts = chrono::Utc::now().timestamp();
                        // 300 seconds (5 minutes) without ticks = Market Closed
                        if now_ts - latest_tick > 300 && latest_tick > 0 {
                            info!("🤖 [Auto-Pilot] Skipping {} because market is closed (last tick {}s ago)", sym, now_ts - latest_tick);
                            let closed_msg = serde_json::json!({
                                "type": "market_closed",
                                "symbol": sym,
                                "message": "ตลาดปิดหยุดการคำนวณจาก AI"
                            }).to_string();
                            let _ = tx_ai.send(closed_msg);
                            // continue; // Temporarily removed for weekend testing!
                        }
                        
                        info!("🤖 [Auto-Pilot] Triggering Scheduled Multi-Agent Analysis on {}", sym);
                        
                        let start_msg = serde_json::json!({ "type": "agents_started", "symbol": sym }).to_string();
                        let _ = tx_ai.send(start_msg);
                        
                        let candles_m5 = db_ai.get_candles_for_strategy(&sym, 5, 50).await;
                        let candles_m15 = db_ai.get_candles_for_strategy(&sym, 15, 50).await;
                        let candles_h1 = db_ai.get_candles_for_strategy(&sym, 60, 50).await;
                        let candles_h4 = db_ai.get_candles_for_strategy(&sym, 240, 30).await;
                        
                        let multi_tf_candles = vec![
                            ("M5", candles_m5),
                            ("M15", candles_m15),
                            ("H1", candles_h1),
                            ("H4", candles_h4),
                        ];
                        
                        let (bal, eq, open_pos) = {
                            let state = ea_state_ai.read().await;
                            (state.balance, state.equity, state.open_positions)
                        };
                        
                        let job_ai_mode = job["ai_mode"].as_str().unwrap_or(&ai_mode).to_string();
                        let disabled_agents: Vec<String> = job["disabled_agents"]
                            .as_array()
                            .map(|arr| arr.iter().filter_map(|v| v.as_str().map(|s| s.to_string())).collect())
                            .unwrap_or_default();
                        
                        let is_centralized = db_ai.get_config("agent_centralized").await.unwrap_or_else(|| "true".to_string()) == "true";
                        let global_news = if is_centralized {
                            let state = global_ai_data_ai.read().await;
                            state.news.clone()
                        } else {
                            None
                        };
                        
                        let result = ai_engine::run_all_agents_multi_tf(
                            &gemini_key, &gemini_model, &tavily_key,
                            &sym, &multi_tf_candles,
                            if bal > 0.0 { bal } else { 10000.0 }, 
                            if eq > 0.0 { eq } else { 10000.0 }, 
                            open_pos, 5, 10.0, false, 
                            &job_ai_mode,
                            &disabled_agents,
                            global_news,
                            &tx_ai
                        ).await;
                        
                        let resp = serde_json::json!({
                            "type": "multi_agent_result",
                            "symbol": sym,
                            "result": result
                        });
                        let _ = tx_ai.send(resp.to_string());
                    
                        if result.final_decision == "BUY" || result.final_decision == "SELL" {
                            if auto_trade {
                                info!("🤖 [Auto-Pilot] Executing {} order automatically on {}", result.final_decision, sym);
                                let cmd = serde_json::json!({
                                    "action": "open_trade",
                                    "symbol": sym,
                                    "direction": result.final_decision,
                                    "lot_size": auto_lot,
                                    "comment": format!("EA24-{}", job_ai_mode)
                                }).to_string();
                                let _ = tx_ai.send(cmd);
                                
                                if telegram_alert {
                                    let tg_token = db_ai.get_config("telegram_bot_token").await.unwrap_or_default();
                                    let tg_chat = db_ai.get_config("telegram_chat_id").await.unwrap_or_default();
                                    if !tg_token.is_empty() && !tg_chat.is_empty() {
                                        notify::send_telegram_notify(&tg_token, &tg_chat, &format!("🔥 AI Auto-Execute: {} {}\nLot Size: {}\nConfidence: {}%\nMode: {}", result.final_decision, sym, auto_lot, result.confidence, tp_sl_mode)).await;
                                    }
                                }
                            } else {
                                info!("🤖 [Auto-Pilot] Proposing {} order on {}, awaiting user confirmation", result.final_decision, sym);
                                let proposal = serde_json::json!({
                                    "type": "ai_trade_proposal",
                                    "symbol": sym,
                                    "direction": result.final_decision,
                                    "confidence": result.confidence,
                                    "reasoning": result.reasoning,
                                    "lot_size": auto_lot,
                                    "comment": format!("EA24-{}", job_ai_mode)
                                }).to_string();
                                let _ = tx_ai.send(proposal);
                                
                                let tg_token = db_ai.get_config("telegram_bot_token").await.unwrap_or_default();
                                let tg_chat = db_ai.get_config("telegram_chat_id").await.unwrap_or_default();
                                notify::send_telegram_notify(&tg_token, &tg_chat, &format!("🚨 AI Trade Proposal: {} {}\nConfidence: {}%\n\n{}", result.final_decision, sym, result.confidence, result.reasoning)).await;
                            }
                        }
                    }
                }
            } else {
                 last_runs.clear();
            }
            tokio::time::sleep(tokio::time::Duration::from_secs(10)).await;
        }
    });

    // Spawn Global AI loop (News & Calendar every 1 hour)
    let global_ai_db = database.clone();
    let global_ai_tx = tx.clone();
    let global_ai_state = global_ai_data.clone();
    tokio::spawn(async move {
        tokio::time::sleep(tokio::time::Duration::from_secs(15)).await; // delayed startup
        loop {
            let gemini_key = global_ai_db.get_config("gemini_api_key").await.unwrap_or_default();
            let gemini_model = global_ai_db.get_config("gemini_model").await.unwrap_or_default();
            let tavily_key = global_ai_db.get_config("tavily_api_key").await.unwrap_or_default();

            if !gemini_key.is_empty() && !tavily_key.is_empty() {
                info!("🤖 [Global-AI] Fetching News and Economic Calendar for global Watchlist...");
                let sym_keyword = global_ai_db.get_config("agent_news_keyword").await.unwrap_or_else(|| "Global Forex Market".to_string());
                let sym = sym_keyword.as_str();
                
                // Fetch in parallel
                let news_fut = ai_engine::run_news_hunter(&gemini_key, &gemini_model, &tavily_key, sym, &global_ai_tx);
                let cal_fut = ai_engine::run_calendar_watcher(sym, &global_ai_tx);
                let macro_fut = ai_engine::fetch_macro_indicators(&gemini_key, &gemini_model, &tavily_key, &global_ai_tx);
                
                let (news_result, cal_result, macro_result) = tokio::join!(news_fut, cal_fut, macro_fut);
                
                let update_ts = chrono::Utc::now().timestamp();
                {
                    let mut st = global_ai_state.write().await;
                    st.news = Some(news_result.clone());
                    st.calendar = Some(cal_result.clone());
                    st.macro_data = Some(macro_result.clone());
                    st.last_updated = update_ts;
                }
                
                // Save to DB
                if let Ok(n_str) = serde_json::to_string(&news_result) {
                    global_ai_db.set_config("global_news_cache", &n_str).await;
                }
                if let Ok(c_str) = serde_json::to_string(&cal_result) {
                    global_ai_db.set_config("global_calendar_cache", &c_str).await;
                }
                if let Ok(m_str) = serde_json::to_string(&macro_result) {
                    global_ai_db.set_config("global_macro_cache", &m_str).await;
                }
                global_ai_db.set_config("global_news_last_updated", &update_ts.to_string()).await;
                
                let msg = serde_json::json!({
                    "type": "global_ai_data",
                    "data": {
                        "news": news_result,
                        "calendar": cal_result,
                        "macro_data": macro_result,
                        "last_updated": update_ts
                    }
                }).to_string();
                let _ = global_ai_tx.send(msg);
                info!("🤖 [Global-AI] Successfully updated Global News and Calendar. Next fetch in 1 hour.");
                tokio::time::sleep(tokio::time::Duration::from_secs(3600)).await;
            } else {
                // If keys are not set, check again quickly
                tokio::time::sleep(tokio::time::Duration::from_secs(15)).await;
            }
        }
    });

    // Spawn sysinfo polling loop — track only THIS process
    let sys_db = database.clone();
    let sys_tx = tx.clone();
    tokio::spawn(async move {
        let pid = sysinfo::Pid::from_u32(std::process::id());
        let mut sys = sysinfo::System::new();
        let mut networks = sysinfo::Networks::new_with_refreshed_list();
        // Initial refresh so first delta is valid
        sys.refresh_processes(sysinfo::ProcessesToUpdate::Some(&[pid]), true);
        sys.refresh_memory();
        loop {
            tokio::time::sleep(tokio::time::Duration::from_secs(1)).await;
            sys.refresh_processes(sysinfo::ProcessesToUpdate::Some(&[pid]), true);
            sys.refresh_memory();
            networks.refresh(true);

            let (cpu, ram) = if let Some(proc) = sys.process(pid) {
                (proc.cpu_usage(), proc.memory() / 1048576) // bytes to MB
            } else {
                (0.0, 0)
            };
            let total = sys.total_memory() / 1048576;
            
            let mut rx_kb = 0.0;
            let mut tx_kb = 0.0;
            for (_interface_name, data) in &networks {
                rx_kb += data.received() as f32 / 1024.0;
                tx_kb += data.transmitted() as f32 / 1024.0;
            }

            let db_pool_size = sys_db.size();

            let msg = serde_json::json!({
                "type": "telemetry",
                "cpu": cpu,
                "ram_mb": ram,
                "total_ram_mb": total,
                "rx_kb": rx_kb,
                "tx_kb": tx_kb,
                "db_pool": db_pool_size
            }).to_string();
            let _ = sys_tx.send(msg);
        }
    });

    // Spawn Strategy Engine
    let engine_db = database.clone();
    let engine_tx = tx.clone();
    let engine_ea = ea_state.clone();
    tokio::spawn(async move {
        strategy::run_strategy_engine(engine_db, engine_tx, engine_ea).await;
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
            server_start,
            global_ai_data.clone(),
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
    db: Arc<db::Database>,
) {
    info!("🔗 [MT5] New connection from: {}", peer_addr);
    active_eas.fetch_add(1, Ordering::SeqCst);

    let (reader, mut writer) = stream.split();
    let mut buf_reader = BufReader::new(reader);
    let mut line = String::new();

    let mut digits_map: std::collections::HashMap<String, i64> = std::collections::HashMap::new();
    let mut last_risk_alert = std::time::Instant::now() - std::time::Duration::from_secs(3600);
    let mut is_real_ea = false; // Tracks if this connection has sent ea_info

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
                                    is_real_ea = true;

                                    // Update tray icon


                                    // Broadcast ea_info to UI
                                    let info_msg = serde_json::json!({
                                        "type": "ea_info",
                                        "version": ver,
                                        "latest_version": LATEST_EA_VERSION,
                                        "symbol": sym,
                                        "update_available": is_update_available(&ver, LATEST_EA_VERSION),
                                    }).to_string();
                                    let _ = tx.send(info_msg);

                                    // === Gap-fill: Request ONLY missing data for the period server was offline ===
                                    let db_gf = db.clone();
                                    let tx_gf = tx.clone();
                                    let ea_state_gf = ea_state.clone();
                                    tokio::spawn(async move {
                                        tokio::time::sleep(tokio::time::Duration::from_secs(3)).await;
                                        let symbols = db_gf.get_tracked_symbols().await;
                                        let now = chrono::Utc::now().timestamp();
                                        for sym in &symbols {
                                            let last_tick = db_gf.get_latest_tick_timestamp(sym).await;
                                            if last_tick == 0 { continue; }
                                            let gap_secs = now - last_tick;
                                            let gap_minutes = gap_secs / 60;
                                            if gap_minutes > 5 && gap_minutes < 1440 {
                                                // Request exact gap amount only (M1 candles)
                                                let count = gap_minutes;
                                                info!("🔄 [Gap-Fill] {} gap={}min, fetching {} M1 candles from ts={}", sym, gap_minutes, count, last_tick);
                                                
                                                // Update in state
                                                ea_state_gf.write().await.gap_status.insert(sym.clone(), "loading".to_string());
                                                
                                                // Broadcast 'loading' status
                                                let status_msg = serde_json::json!({
                                                    "type": "gap_fill_status",
                                                    "symbol": sym,
                                                    "status": "loading"
                                                }).to_string();
                                                let _ = tx_gf.send(status_msg);

                                                let cmd = serde_json::json!({
                                                    "action": "request_candles",
                                                    "symbol": sym,
                                                    "timeframe": 1,
                                                    "count": count,
                                                    "from_time": last_tick,
                                                }).to_string();
                                                let _ = tx_gf.send(cmd);
                                                tokio::time::sleep(tokio::time::Duration::from_millis(300)).await;
                                            } else {
                                                if gap_minutes >= 1440 {
                                                    info!("⏭️ [Gap-Fill] {} gap={}min (>1 day), skip backfill", sym, gap_minutes);
                                                }
                                                // Update in state
                                                ea_state_gf.write().await.gap_status.insert(sym.clone(), "loaded".to_string());
                                                
                                                // Broadcast 'loaded' status
                                                let status_msg = serde_json::json!({
                                                    "type": "gap_fill_status",
                                                    "symbol": sym,
                                                    "status": "loaded"
                                                }).to_string();
                                                let _ = tx_gf.send(status_msg);
                                            }
                                        }
                                        if !symbols.is_empty() {
                                            info!("✅ [Gap-Fill] Done checking {} symbols", symbols.len());
                                        }
                                    });
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
                                            let mut state = ea_state.write().await;
                                            for info in symbols {
                                                let sym = info["symbol"].as_str().unwrap_or("");
                                                let digits = info["digits"].as_i64().unwrap_or(5);
                                                let time = info["time"].as_i64().unwrap_or(0);
                                                if !sym.is_empty() {
                                                    digits_map.insert(sym.to_string(), digits);
                                                    if time > 0 {
                                                        state.last_quote_times.insert(sym.to_string(), time);
                                                    }
                                                }
                                            }
                                        }
                                    } else if msg_type == Some("trade_history") {
                                        if let Some(deals) = val.get("deals") {
                                            let new_deals = db.save_trade_history(deals).await;
                                            
                                            // 🔔 Send Telegram Notification for closed trades
                                            let notify_close = db.get_config("notify_on_close").await.unwrap_or("true".to_string()) == "true";
                                            let bot_token = db.get_config("telegram_bot_token").await.unwrap_or_default();
                                            let chat_id = db.get_config("telegram_chat_id").await.unwrap_or_default();
                                            
                                            if notify_close && !bot_token.is_empty() && !chat_id.is_empty() {
                                                for deal in new_deals {
                                                    let ticket = deal["ticket"].as_i64().unwrap_or(0);
                                                    let pos_id = deal["pos_id"].as_i64().unwrap_or(0);
                                                    
                                                    // In MT5, an exit deal has ticket != pos_id and affects PNL.
                                                    if pos_id > 0 && ticket != pos_id {
                                                        let profit = deal["profit"].as_f64().unwrap_or(0.0);
                                                        let swap = deal["swap"].as_f64().unwrap_or(0.0);
                                                        let comm = deal["commission"].as_f64().unwrap_or(0.0);
                                                        let total_pnl = profit + swap + comm;
                                                        
                                                        let sym = deal["symbol"].as_str().unwrap_or("");
                                                        let lot = deal["volume"].as_f64().unwrap_or(0.0);
                                                        
                                                        // A sell deal closes a long position -> origin was BUY
                                                        let type_str = deal["type"].as_str().unwrap_or("");
                                                        let dir = if type_str == "1" || type_str.contains("SELL") { "BUY" } else { "SELL" };
                                                        
                                                        let msg = crate::notify::format_trade_close(sym, dir, lot, total_pnl);
                                                        let bt = bot_token.clone();
                                                        let cid = chat_id.clone();
                                                        tokio::spawn(async move { crate::notify::send_telegram_notify(&bt, &cid, &msg).await; });
                                                    }
                                                }
                                            }
                                        }
                                    } else if msg_type == Some("candle_data") {
                                        if let Some(candles) = val.get("candles") {
                                            let sym = val["symbol"].as_str().unwrap_or("");
                                            let tf_min = val["timeframe"].as_i64().unwrap_or(5);
                                            let tf_label = match tf_min {
                                                1 => "M1", 5 => "M5", 15 => "M15", 30 => "M30",
                                                60 => "H1", 240 => "H4", 1440 => "D1", _ => "M5",
                                            };
                                            db.insert_candles_as_ticks(sym, candles).await;
                                            
                                            // Convert candle_data format {t,o,h,l,c} → history format {time,open,high,low,close}
                                            if let Some(arr) = candles.as_array() {
                                                let converted: Vec<serde_json::Value> = arr.iter().map(|c| {
                                                    serde_json::json!({
                                                        "time": c["t"].as_i64().unwrap_or(0),
                                                        "open": c["o"].as_f64().unwrap_or(0.0),
                                                        "high": c["h"].as_f64().unwrap_or(0.0),
                                                        "low": c["l"].as_f64().unwrap_or(0.0),
                                                        "close": c["c"].as_f64().unwrap_or(0.0),
                                                    })
                                                }).collect();
                                                // Send as 'history' so chart renders MT5 candles directly
                                                let history_msg = serde_json::json!({
                                                    "type": "history",
                                                    "symbol": sym,
                                                    "timeframe": tf_label,
                                                    "candles": converted,
                                                    "source": "mt5_direct"
                                                }).to_string();
                                                let _ = tx.send(history_msg);
                                                info!("📊 [MT5] Forwarded {} direct candles for {} {}", converted.len(), sym, tf_label);
                                            }

                                            // Notify clients that backend data gap-fill is done
                                            ea_state.write().await.gap_status.insert(sym.to_string(), "loaded".to_string());
                                            let status_msg = serde_json::json!({
                                                "type": "gap_fill_status",
                                                "symbol": sym,
                                                "status": "loaded"
                                            }).to_string();
                                            let _ = tx.send(status_msg);
                                        }
                                    } else if msg_type == Some("account_data") {
                                        // Server-side trailing stop
                                        if let Some(positions) = val.get("positions").and_then(|p| p.as_array()) {
                                            let balance = val["balance"].as_f64().unwrap_or(0.0);
                                            let equity = val["equity"].as_f64().unwrap_or(balance);
                                            let mut risk_usd = 0.0;
                                            
                                            // Update EaState
                                            {
                                                let mut st = ea_state.write().await;
                                                st.balance = balance;
                                                st.equity = equity;
                                                st.open_positions = positions.len();
                                            }

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
                                            let setups = db.get_trade_setups().await;
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
                    Err(tokio::sync::broadcast::error::RecvError::Lagged(skipped)) => {
                        warn!("⚠️ [MT5] Receiver lagged, skipped {} messages", skipped);
                    }
                    Err(tokio::sync::broadcast::error::RecvError::Closed) => break,
                }
            }
        }
    }

    // Reset state on disconnect — only if this was a real EA connection
    if is_real_ea {
        let mut state = ea_state.write().await;
        state.connected = false;
    }
    active_eas.fetch_sub(1, Ordering::SeqCst);

    // Update tray icon

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
    server_start: std::time::Instant,
    global_ai_data: Arc<RwLock<GlobalAiData>>,
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
        "update_available": state.connected && is_update_available(&state.version, LATEST_EA_VERSION),
        "server_uptime_secs": server_start.elapsed().as_secs(),
        "gap_status": state.gap_status,
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
                                            "server_uptime_secs": server_start.elapsed().as_secs(),
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
                                    "request_candles" => {
                                        let sym = client_msg.symbol.as_deref().unwrap_or("XAUUSD");
                                        let tf = client_msg.timeframe.as_deref().unwrap_or("M5");
                                        let tf_minutes: i64 = match tf {
                                            "M1" => 1, "M5" => 5, "M15" => 15, "M30" => 30,
                                            "H1" => 60, "H4" => 240, "D1" => 1440, _ => 5,
                                        };
                                        info!("📊 [UI] Requesting candles for {} {}", sym, tf);
                                        let cmd = serde_json::json!({
                                            "action": "request_candles",
                                            "symbol": sym,
                                            "timeframe": tf_minutes,
                                            "count": 500
                                        }).to_string();
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
                                        // Find the install_dir for this instance to kill only this one
                                        let appdata = get_wine_appdata();
                                        let idir = appdata.join("MetaQuotes").join("Terminal").join(&instance_id);
                                        if let Some(install_dir) = read_install_dir(&idir) {
                                            kill_mt5_instance(&install_dir);
                                        } else {
                                            // Fallback: kill all
                                            let _ = std::process::Command::new("true")
                                                .args(&["-f", "terminal64.exe"])
                                                .output();
                                        }
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
                                            crate::updater::check_and_update(Some(check_tx), false).await;
                                        });
                                        let resp = serde_json::json!({
                                            "type": "update_status",
                                            "status": "checking",
                                            "message": "Checking GitHub for updates..."
                                        });
                                        let _ = write.send(Message::Text(resp.to_string())).await;
                                    }
                                    "do_update" => {
                                        info!("🚀 [UI] Update DO_UPDATE triggered!");
                                        let do_tx = tx.clone();
                                        tokio::spawn(async move {
                                            crate::updater::check_and_update(Some(do_tx), true).await;
                                        });
                                        let resp = serde_json::json!({
                                            "type": "update_status",
                                            "status": "downloading",
                                            "message": "Starting download process..."
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
                                        let _ = std::process::Command::new(&exe).spawn();
                                        // Small delay for new process to start
                                        tokio::time::sleep(std::time::Duration::from_millis(500)).await;
                                        info!("👋 Old server exiting...");
                                        std::process::exit(0);
                                    }
                                    "get_global_ai_data" => {
                                        info!("🤖 [UI] Requesting global AI data...");
                                        let data = global_ai_data.read().await;
                                        let resp = serde_json::json!({
                                            "type": "global_ai_data",
                                            "data": {
                                                "news": data.news.as_ref().map(|n| serde_json::to_value(n).unwrap_or(serde_json::Value::Null)).unwrap_or_else(|| serde_json::json!({
                                                    "sentiment": "NEUTRAL",
                                                    "summary": "ยังไม่มีข้อมูลข่าวสารในขณะนี้ กรุณากดปุ่มเพื่อดึงข้อมูล...",
                                                    "headlines": ["Pending First Fetch"]
                                                })),
                                                "calendar": data.calendar.as_ref().map(|c| serde_json::to_value(c).unwrap_or(serde_json::Value::Null)).unwrap_or_else(|| serde_json::json!({
                                                    "high_impact_soon": false,
                                                    "events": [{
                                                        "date": chrono::Utc::now().to_rfc3339(),
                                                        "title": "Awaiting API Configuration",
                                                        "impact": "Info",
                                                        "country": "SYS"
                                                    }]
                                                })),
                                                "macro_data": data.macro_data.as_ref().map(|m| serde_json::to_value(m).unwrap_or(serde_json::Value::Null)).unwrap_or_else(|| serde_json::json!({
                                                    "fed": { "value": "N/A", "date": "-" },
                                                    "nfp": { "value": "N/A", "date": "-" },
                                                    "cpi": { "value": "N/A", "date": "-" }
                                                })),
                                                "last_updated": if data.last_updated > 0 { data.last_updated } else { chrono::Utc::now().timestamp() }
                                            }
                                        }).to_string();
                                        let _ = write.send(Message::Text(resp)).await;
                                    }
                                    "force_fetch_news" => {
                                        let gemini_key = db.get_config("gemini_api_key").await.unwrap_or_default();
                                        let gemini_model = db.get_config("gemini_model").await.unwrap_or_default();
                                        let tavily_key = db.get_config("tavily_api_key").await.unwrap_or_default();
                                        
                                        if !gemini_key.is_empty() {
                                            let global_tx = tx.clone();
                                            let global_state = global_ai_data.clone();
                                            let db_clone = db.clone();
                                            tokio::spawn(async move {
                                                info!("🤖 [UI] Manual force fetch News requested...");
                                                let sym_keyword = db_clone.get_config("agent_news_keyword").await.unwrap_or_else(|| "Global Forex Market".to_string());
                                                let sym = sym_keyword.as_str();
                                                
                                                let _ = global_tx.send(serde_json::json!({
                                                    "type": "agent_log", "symbol": sym, "agent": "news_hunter", "status": "running",
                                                    "message": "กำลังดึงข้อมูลข่าวสารล่าสุด (Manual Refresh)..."
                                                }).to_string());
                                                
                                                let tv_key = if !tavily_key.is_empty() { tavily_key.clone() } else { "".to_string() };
                                                
                                                let news_fut = ai_engine::run_news_hunter(&gemini_key, &gemini_model, &tv_key, sym, &global_tx);
                                                let cal_fut = ai_engine::run_calendar_watcher(sym, &global_tx);
                                                let macro_fut = ai_engine::fetch_macro_indicators(&gemini_key, &gemini_model, &tv_key, &global_tx);
                                                
                                                let (news_result, cal_result, macro_result) = tokio::join!(news_fut, cal_fut, macro_fut);
                                                
                                                let update_ts = chrono::Utc::now().timestamp();
                                                {
                                                    let mut st = global_state.write().await;
                                                    st.news = Some(news_result.clone());
                                                    st.calendar = Some(cal_result.clone());
                                                    st.macro_data = Some(macro_result.clone());
                                                    st.last_updated = update_ts;
                                                }
                                                // Save to DB
                                                if let Ok(n_str) = serde_json::to_string(&news_result) {
                                                    db_clone.set_config("global_news_cache", &n_str).await;
                                                }
                                                if let Ok(c_str) = serde_json::to_string(&cal_result) {
                                                    db_clone.set_config("global_calendar_cache", &c_str).await;
                                                }
                                                db_clone.set_config("global_news_last_updated", &update_ts.to_string()).await;

                                                let msg = serde_json::json!({
                                                    "type": "global_ai_data",
                                                    "data": { "news": news_result, "calendar": cal_result, "macro_data": macro_result, "last_updated": update_ts }
                                                }).to_string();
                                                let _ = global_tx.send(msg);
                                                info!("🤖 [UI] Manual fetch complete and broadcasted.");
                                            });
                                        } else {
                                            info!("🤖 [UI] Cannot force fetch: missing Gemini API keys.");
                                            let msg = serde_json::json!({
                                                "type": "global_ai_data",
                                                "data": {
                                                    "news": {
                                                        "sentiment": "NEUTRAL",
                                                        "summary": "ไม่สามารถวิเคราะห์ข่าวได้ กรุณาเพิ่มที่อยู่ API Key สำหรับ Gemini",
                                                        "headlines": [],
                                                        "source_count": 0
                                                    },
                                                    "calendar": null,
                                                    "last_updated": chrono::Utc::now().timestamp()
                                                }
                                            }).to_string();
                                            let _ = tx.send(msg); // Send directly on normal broadcast channel
                                        }
                                    }
                                    _ => {}
                                }

                                // === Database Actions ===
                                match action.as_str() {
                                    "get_history" => {
                                        let sym = client_msg.symbol.as_deref().unwrap_or("XAUUSD");
                                        let limit = client_msg.limit.unwrap_or(500);
                                        let tf = client_msg.timeframe.as_deref().unwrap_or("M1");
                                        let tf_minutes: i64 = match tf {
                                            "M1" => 1, "M5" => 5, "M15" => 15, "M30" => 30,
                                            "H1" => 60, "H4" => 240, "D1" => 1440, _ => 1,
                                        };
                                        info!("📊 [UI] History requested for {} {} (limit {})", sym, tf, limit);
                                        let candles_raw = db.get_candles_for_strategy(sym, tf_minutes, limit).await;
                                        
                                        let candles: Vec<serde_json::Value> = candles_raw.iter().map(|c| {
                                            serde_json::json!({ "time": c.time, "open": c.open, "high": c.high, "low": c.low, "close": c.close })
                                        }).collect();
                                        info!("📊 [UI] Returning {} candles for {} {}", candles.len(), sym, tf);
                                        let resp = serde_json::json!({
                                            "type": "history",
                                            "symbol": sym,
                                            "timeframe": tf,
                                            "candles": candles,
                                        });
                                        let _ = write.send(Message::Text(resp.to_string())).await;

                                        if candles_raw.len() < 50 {
                                            info!("📊 [UI] DB history insufficient for {} ({} candles), requesting from EA", sym, candles_raw.len());
                                            ea_state.write().await.gap_status.insert(sym.to_string(), "loading".to_string());
                                            let status_msg = serde_json::json!({
                                                "type": "gap_fill_status",
                                                "symbol": sym,
                                                "status": "loading"
                                            }).to_string();
                                            let _ = tx.send(status_msg);

                                            let sym_clone = sym.to_string();
                                            let tx_clone = tx.clone();
                                            tokio::spawn(async move {
                                                for _ in 0..3 {
                                                    let cmd = serde_json::json!({
                                                        "action": "request_candles",
                                                        "symbol": sym_clone,
                                                        "timeframe": tf_minutes,
                                                        "count": limit,
                                                        "from_time": 0
                                                    }).to_string();
                                                    let _ = tx_clone.send(cmd);
                                                    tokio::time::sleep(tokio::time::Duration::from_millis(1500)).await;
                                                }
                                            });
                                        }
                                    }
                                    "get_db_stats" => {
                                        info!("📊 [UI] DB stats requested");
                                        let stats = db.get_stats().await;
                                        let resp = serde_json::json!({
                                            "type": "db_stats",
                                            "stats": stats,
                                        });
                                        let _ = write.send(Message::Text(resp.to_string())).await;
                                    }
                                    "get_server_config" => {
                                        info!("⚙️ [UI] Config requested");
                                        let config = db.get_all_config().await;
                                        let resp = serde_json::json!({
                                            "type": "server_config",
                                            "config": config,
                                        });
                                        let _ = write.send(Message::Text(resp.to_string())).await;
                                    }
                                    "set_server_config" => {
                                        if let (Some(key), Some(value)) = (&client_msg.config_key, &client_msg.config_value) {
                                            info!("💾 [UI] Config set: {} = {}", key, value);
                                            db.set_config(key, value).await;
                                            let resp = serde_json::json!({
                                                "type": "config_saved",
                                                "status": "success",
                                                "key": key,
                                            });
                                            let _ = write.send(Message::Text(resp.to_string())).await;
                                            
                                            // 🚀 If API Keys were updated, trigger a manual fetch of Global AI Data!
                                            if key == "tavily_api_key" || key == "gemini_api_key" {
                                                let gemini_key = db.get_config("gemini_api_key").await.unwrap_or_default();
                                                let gemini_model = db.get_config("gemini_model").await.unwrap_or_default();
                                                let tavily_key = db.get_config("tavily_api_key").await.unwrap_or_default();
                                                if !gemini_key.is_empty() && !tavily_key.is_empty() {
                                                    let global_tx = tx.clone();
                                                    let global_state = global_ai_data.clone();
                                                    let db_clone = db.clone();
                                                    tokio::spawn(async move {
                                                        info!("🤖 [Global-AI] API Keys updated! Forcing immediate fetch for Global Watchlist...");
                                                        let sym_keyword = db_clone.get_config("agent_news_keyword").await.unwrap_or_else(|| "Global Forex Market".to_string());
                                                        let sym = sym_keyword.as_str();
                                                        // Send "Loading" status to UI
                                                        let _ = global_tx.send(serde_json::json!({
                                                            "type": "agent_log", "symbol": sym, "agent": "news_hunter", "status": "running",
                                                            "message": "กำลังดึงข้อมูลข่าวสารล่าสุดเนื่องจากมีการอัพเดท API Key..."
                                                        }).to_string());
                                                        
                                                        let news_fut = ai_engine::run_news_hunter(&gemini_key, &gemini_model, &tavily_key, sym, &global_tx);
                                                        let cal_fut = ai_engine::run_calendar_watcher(sym, &global_tx);
                                                        let macro_fut = ai_engine::fetch_macro_indicators(&gemini_key, &gemini_model, &tavily_key, &global_tx);
                                                        let (news_result, cal_result, macro_result) = tokio::join!(news_fut, cal_fut, macro_fut);
                                                        
                                                        let update_ts = chrono::Utc::now().timestamp();
                                                        {
                                                            let mut st = global_state.write().await;
                                                            st.news = Some(news_result.clone());
                                                            st.calendar = Some(cal_result.clone());
                                                            st.macro_data = Some(macro_result.clone());
                                                            st.last_updated = update_ts;
                                                        }
                                                        
                                                        let msg = serde_json::json!({
                                                            "type": "global_ai_data",
                                                            "data": {
                                                                "news": news_result,
                                                                "calendar": cal_result,
                                                                "macro_data": macro_result,
                                                                "last_updated": update_ts
                                                            }
                                                        }).to_string();
                                                        let _ = global_tx.send(msg);
                                                        info!("🤖 [Global-AI] Immediate fetch complete.");
                                                    });
                                                }
                                            }
                                        }
                                    }
                                    "vacuum_db" => {
                                        info!("🧹 [UI] VACUUM requested");
                                        let success = db.vacuum().await;
                                        let stats = db.get_stats().await;
                                        let resp = serde_json::json!({
                                            "type": "vacuum_result",
                                            "status": if success { "success" } else { "error" },
                                            "stats": stats,
                                        });
                                        let _ = write.send(Message::Text(resp.to_string())).await;
                                    }
                                    "test_telegram_notify" => {
                                        let bot_token = db.get_config("telegram_bot_token").await.unwrap_or_default();
                                        let chat_id = db.get_config("telegram_chat_id").await.unwrap_or_default();
                                        let ok = notify::send_telegram_notify(&bot_token, &chat_id, "✅ ทดสอบแจ้งเตือน EA-24\nระบบแจ้งเตือนผ่าน Telegram ทำงานปกติ!").await;
                                        let resp = serde_json::json!({
                                            "type": "telegram_notify_test",
                                            "success": ok,
                                        });
                                        let _ = write.send(Message::Text(resp.to_string())).await;
                                    }
                                    "get_risk_config" => {
                                        let config = db.get_all_config().await;
                                        let resp = serde_json::json!({
                                            "type": "risk_config",
                                            "config": config,
                                        });
                                        let _ = write.send(Message::Text(resp.to_string())).await;
                                    }
                                    "get_trade_setups" => {
                                        let setups = db.get_trade_setups().await;
                                        let resp = serde_json::json!({
                                            "type": "trade_setups",
                                            "setups": setups,
                                        });
                                        let _ = write.send(Message::Text(resp.to_string())).await;
                                    }
                                    "get_trade_history" => {
                                        let history = db.get_trade_history().await;
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
                                        if let Some(id) = db.add_trade_setup(sym, strat, tf, lot, risk, mt5_inst, tp_en, tp_m, tp_v, sl_en, sl_m, sl_v, ts_en, ts_pts).await {
                                            let setups = db.get_trade_setups().await;
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
                                            let current = db.get_trade_setups().await;
                                            if let Some(arr) = current.as_array() {
                                                for s in arr {
                                                    if s["id"].as_i64() == Some(id) {
                                                        let new_status = if s["status"].as_str() == Some("active") { "paused" } else { "active" };
                                                        db.update_trade_setup_status(id, new_status).await;
                                                    }
                                                }
                                            }
                                            let setups = db.get_trade_setups().await;
                                            let resp = serde_json::json!({
                                                "type": "trade_setups",
                                                "setups": setups,
                                            });
                                            let _ = write.send(Message::Text(resp.to_string())).await;
                                        }
                                    }
                                    "delete_trade_setup" => {
                                        if let Some(id) = client_msg.setup_id {
                                            db.delete_trade_setup(id).await;
                                            let setups = db.get_trade_setups().await;
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
                                            db.update_trade_setup(id, sym, strat, tf, lot, risk, mt5_inst, tp_en, tp_m, tp_v, sl_en, sl_m, sl_v, ts_en, ts_pts).await;
                                            let setups = db.get_trade_setups().await;
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
                                                let linux_install_dir = PathBuf::from(&inst.install_path);
                                                let experts_dir = linux_install_dir.join("MQL5").join("Experts");
                                                
                                                let src_ex5 = PathBuf::from("mt5").join("EATradingClient.ex5");
                                                let dest_ex5 = experts_dir.join("EATradingClient.ex5");

                                                if src_ex5.exists() {
                                                    std::fs::create_dir_all(&experts_dir).ok();
                                                    match std::fs::copy(&src_ex5, &dest_ex5) {
                                                        Ok(_) => {
                                                            info!("✅ Pre-compiled EA .ex5 copied to {:?}", dest_ex5);
                                                            "success"
                                                        }
                                                        Err(e) => {
                                                            error!("❌ Copy failed: {}", e);
                                                            "copy_failed"
                                                        }
                                                    }
                                                } else {
                                                    error!("❌ Source EA not found: {:?}", src_ex5);
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
                                    "update_ea" => {
                                        info!("🔄 [UI] Update EA requested — compile & deploy to all running MT5");
                                        let instances = scan_mt5_instances();
                                        let running: Vec<_> = instances.iter().filter(|i| i.mt5_running).collect();
                                        
                                        let mq5_src = PathBuf::from("mt5").join("EATradingClient.mq5");
                                        let mut results = Vec::new();
                                        
                                        if !mq5_src.exists() {
                                            error!("❌ Source .mq5 not found at {:?}", mq5_src);
                                            let resp = serde_json::json!({
                                                "type": "deploy_status",
                                                "status": "error",
                                                "message": "Source .mq5 file not found",
                                            });
                                            let _ = write.send(Message::Text(resp.to_string())).await;
                                        } else {
                                            for inst in &running {
                                                let linux_dir = PathBuf::from(&inst.install_path);
                                                let experts_dir = linux_dir.join("MQL5").join("Experts");
                                                let dest_mq5 = experts_dir.join("EATradingClient.mq5");
                                                let metaeditor = linux_dir.join("MetaEditor64.exe");
                                                
                                                std::fs::create_dir_all(&experts_dir).ok();
                                                
                                                // 1. Copy .mq5 source
                                                match std::fs::copy(&mq5_src, &dest_mq5) {
                                                    Ok(_) => info!("✅ Copied .mq5 to {:?}", dest_mq5),
                                                    Err(e) => {
                                                        error!("❌ Copy .mq5 failed: {}", e);
                                                        results.push(format!("{}: copy failed", inst.id));
                                                        continue;
                                                    }
                                                }
                                                
                                                // 2. Compile with MetaEditor
                                                if metaeditor.exists() {
                                                    let mq5_win = format!("Z:{}", dest_mq5.display().to_string().replace('/', "\\"));
                                                    info!("🔧 Compiling EA via MetaEditor: {}", mq5_win);
                                                    
                                                    if let Ok(_) = std::process::Command::new("true")
                                                        .arg(&metaeditor)
                                                        .arg("-c").arg("exit 0")
                                                        .spawn()
                                                    {
                                                        std::thread::sleep(std::time::Duration::from_secs(5));
                                                        // Send F7 to compile
                                                        if let Ok(output) = std::process::Command::new("true")
                                                            .args(&["search", "--name", "MetaEditor"])
                                                            .output()
                                                        {
                                                            let ids = String::from_utf8_lossy(&output.stdout);
                                                            for wid in ids.lines() {
                                                                let wid = wid.trim();
                                                                if !wid.is_empty() {
                                                                    let _ = std::process::Command::new("true")
                                                                        .args(&["windowactivate", "--sync", wid])
                                                                        .output();
                                                                    std::thread::sleep(std::time::Duration::from_millis(500));
                                                                    let _ = std::process::Command::new("true")
                                                                        .args(&["key", "F7"])
                                                                        .output();
                                                                    info!("🔧 Sent F7 compile to MetaEditor (window {})", wid);
                                                                }
                                                            }
                                                        }
                                                        std::thread::sleep(std::time::Duration::from_secs(10));
                                                        let _ = std::process::Command::new("true")
                                                            .args(&["-f", "MetaEditor64.exe"])
                                                            .output();
                                                        info!("🔧 MetaEditor closed");
                                                        std::thread::sleep(std::time::Duration::from_secs(2));
                                                        
                                                        // Copy compiled .ex5 to cache and AppData
                                                        let compiled_ex5 = experts_dir.join("EATradingClient.ex5");
                                                        if compiled_ex5.exists() {
                                                            // Copy to server cache
                                                            std::fs::copy(&compiled_ex5, Path::new("mt5/EATradingClient.ex5")).ok();
                                                            
                                                            // Also copy to AppData for this instance 
                                                            let home = std::env::var("HOME").unwrap_or_default();
                                                            let user = std::env::var("USER").unwrap_or_else(|_| "user".to_string());
                                                            let appdata_experts = PathBuf::from(&home)
                                                                .join(".wine/drive_c/users")
                                                                .join(&user)
                                                                .join("AppData/Roaming/MetaQuotes/Terminal")
                                                                .join(&inst.id)
                                                                .join("MQL5/Experts");
                                                            std::fs::create_dir_all(&appdata_experts).ok();
                                                            std::fs::copy(&compiled_ex5, appdata_experts.join("EATradingClient.ex5")).ok();
                                                            
                                                            info!("✅ EA compiled and deployed to {}", inst.broker_name);
                                                            results.push(format!("{}: success", inst.broker_name));
                                                        } else {
                                                            error!("❌ Compiled .ex5 not found after MetaEditor");
                                                            results.push(format!("{}: compile failed", inst.broker_name));
                                                        }
                                                    }
                                                } else {
                                                    // No MetaEditor — just copy .ex5 if available
                                                    let src_ex5 = PathBuf::from("mt5").join("EATradingClient.ex5");
                                                    if src_ex5.exists() {
                                                        std::fs::copy(&src_ex5, experts_dir.join("EATradingClient.ex5")).ok();
                                                        results.push(format!("{}: ex5 copied (no compile)", inst.broker_name));
                                                    } else {
                                                        results.push(format!("{}: no MetaEditor or .ex5", inst.broker_name));
                                                    }
                                                }
                                            }
                                            
                                            let resp = serde_json::json!({
                                                "type": "deploy_status",
                                                "status": if results.iter().any(|r| r.contains("success")) { "success" } else { "partial" },
                                                "message": format!("Updated {} instance(s): {}", results.len(), results.join(", ")),
                                                "results": results,
                                            });
                                            let _ = write.send(Message::Text(resp.to_string())).await;
                                        }
                                    }
                                    "get_signals" => {
                                        let limit = client_msg.limit.unwrap_or(20);
                                        let signals = db.get_recent_signals(limit).await;
                                        let resp = serde_json::json!({
                                            "type": "strategy_signals",
                                            "signals": signals,
                                        });
                                        let _ = write.send(Message::Text(resp.to_string())).await;
                                    }
                                    "upload_ea" => {
                                        if let (Some(name), Some(content)) = (client_msg.file_name.as_deref(), client_msg.content_base64.as_deref()) {
                                            use base64::{Engine as _, engine::general_purpose};
                                            // Handle cases where JS might prepend "data:application/octet-stream;base64,"
                                            let b64_str = if content.contains(',') {
                                                content.split(',').nth(1).unwrap_or(content)
                                            } else {
                                                content
                                            };
                                            
                                            let result = match general_purpose::STANDARD.decode(b64_str) {
                                                Ok(bytes) => {
                                                    let mt5_dir = PathBuf::from("mt5");
                                                    std::fs::create_dir_all(&mt5_dir).ok();
                                                    let filepath = mt5_dir.join(name);
                                                    match std::fs::write(&filepath, bytes) {
                                                        Ok(_) => {
                                                            info!("✅ EA file uploaded and saved to {:?}", filepath);
                                                            "success"
                                                        }
                                                        Err(e) => {
                                                            error!("❌ Failed to write uploaded EA: {}", e);
                                                            "write_failed"
                                                        }
                                                    }
                                                }
                                                Err(e) => {
                                                    error!("❌ Failed to decode Base64 EA content: {}", e);
                                                    "decode_error"
                                                }
                                            };
                                            let resp = serde_json::json!({
                                                "type": "upload_status",
                                                "status": result,
                                            });
                                            let _ = write.send(Message::Text(resp.to_string())).await;
                                        }
                                    }
                                    "test_ai" => {
                                        info!("🤖 [UI] AI connection test requested");
                                        let api_key = db.get_config("gemini_api_key").await.unwrap_or_default();
                                        let model = db.get_config("gemini_model").await.unwrap_or_default();
                                        let tx_ai = tx.clone();
                                        tokio::spawn(async move {
                                            match ai_engine::test_connection(&api_key, &model).await {
                                                Ok(reply) => {
                                                    let resp = serde_json::json!({
                                                        "type": "ai_test_result",
                                                        "success": true,
                                                        "message": reply,
                                                        "model": if model.is_empty() { "gemini-2.5-flash" } else { &model },
                                                    });
                                                    let _ = tx_ai.send(resp.to_string());
                                                }
                                                Err(e) => {
                                                    let resp = serde_json::json!({
                                                        "type": "ai_test_result",
                                                        "success": false,
                                                        "message": e,
                                                    });
                                                    let _ = tx_ai.send(resp.to_string());
                                                }
                                            }
                                        });
                                    }
                                    "test_tavily" => {
                                        info!("🔍 [UI] Tavily connection test requested");
                                        let api_key = db.get_config("tavily_api_key").await.unwrap_or_default();
                                        let tx_ai = tx.clone();
                                        tokio::spawn(async move {
                                            match ai_engine::test_tavily_connection(&api_key).await {
                                                Ok(reply) => {
                                                    let resp = serde_json::json!({
                                                        "type": "tavily_test_result",
                                                        "success": true,
                                                        "message": reply,
                                                    });
                                                    let _ = tx_ai.send(resp.to_string());
                                                }
                                                Err(e) => {
                                                    let resp = serde_json::json!({
                                                        "type": "tavily_test_result",
                                                        "success": false,
                                                        "message": e,
                                                    });
                                                    let _ = tx_ai.send(resp.to_string());
                                                }
                                            }
                                        });
                                    }
                                    "ask_ai" => {
                                        let question = client_msg.question.unwrap_or_else(|| "สวัสดี".to_string());
                                        info!("🤖 [UI] AI question: {}", question);
                                        let api_key = db.get_config("gemini_api_key").await.unwrap_or_default();
                                        let model = db.get_config("gemini_model").await.unwrap_or_default();
                                        let tx_ai = tx.clone();
                                        tokio::spawn(async move {
                                            match ai_engine::ask_ai(&api_key, &model, &question).await {
                                                Ok(reply) => {
                                                    let resp = serde_json::json!({
                                                        "type": "ai_response",
                                                        "success": true,
                                                        "question": question,
                                                        "answer": reply,
                                                    });
                                                    let _ = tx_ai.send(resp.to_string());
                                                }
                                                Err(e) => {
                                                    let resp = serde_json::json!({
                                                        "type": "ai_response",
                                                        "success": false,
                                                        "question": question,
                                                        "answer": format!("❌ {}", e),
                                                    });
                                                    let _ = tx_ai.send(resp.to_string());
                                                }
                                            }
                                        });
                                    }
                                    "get_ai_models" => {
                                        let models = ai_engine::available_models();
                                        let models_json: Vec<serde_json::Value> = models.iter().map(|(id, name)| {
                                            serde_json::json!({ "id": id, "name": name })
                                        }).collect();
                                        let resp = serde_json::json!({
                                            "type": "ai_models",
                                            "models": models_json,
                                        });
                                        let _ = tx.send(resp.to_string());
                                    }
                                    "analyze_market" => {
                                        let sym = client_msg.symbol.unwrap_or_else(|| "XAUUSD".to_string());
                                        let tf = client_msg.timeframe.unwrap_or_else(|| "M5".to_string());
                                        let strat = client_msg.strategy.unwrap_or_else(|| "Auto".to_string());
                                        info!("🤖 [UI] AI market analysis for {} {} ({})", sym, tf, strat);
                                        
                                        let api_key = db.get_config("gemini_api_key").await.unwrap_or_default();
                                        let model = db.get_config("gemini_model").await.unwrap_or_default();
                                        let tf_min: i64 = match tf.as_str() {
                                            "M1" => 1, "M5" => 5, "M15" => 15, "M30" => 30,
                                            "H1" => 60, "H4" => 240, "D1" => 1440, _ => 5,
                                        };
                                        let candles = db.get_candles_for_strategy(&sym, tf_min, 100).await;
                                        let price = candles.last().map(|c| c.close).unwrap_or(0.0);
                                        let tx_ai = tx.clone();
                                        
                                        tokio::spawn(async move {
                                            match ai_engine::analyze_market(&api_key, &model, &sym, &tf, &candles, price, &strat).await {
                                                Ok(analysis) => {
                                                    let resp = serde_json::json!({
                                                        "type": "ai_analysis",
                                                        "success": true,
                                                        "symbol": sym,
                                                        "timeframe": tf,
                                                        "recommendation": analysis.recommendation,
                                                        "confidence": analysis.confidence,
                                                        "reasoning": analysis.reasoning,
                                                        "full_analysis": analysis.full_analysis,
                                                        "model": analysis.model,
                                                    });
                                                    let _ = tx_ai.send(resp.to_string());
                                                }
                                                Err(e) => {
                                                    let resp = serde_json::json!({
                                                        "type": "ai_analysis",
                                                        "success": false,
                                                        "symbol": sym,
                                                        "message": e,
                                                    });
                                                    let _ = tx_ai.send(resp.to_string());
                                                }
                                            }
                                        });
                                    }
                                    "run_agents" => {
                                        let sym = client_msg.symbol.unwrap_or_else(|| "XAUUSD".to_string());
                                        
                                        let (state_bal, state_eq, state_open_pos) = {
                                            let st = ea_state.read().await;
                                            (st.balance, st.equity, st.open_positions)
                                        };
                                        
                                        let balance = client_msg.balance.unwrap_or_else(|| if state_bal > 0.0 { state_bal } else { 10000.0 });
                                        let equity = client_msg.equity.unwrap_or_else(|| if state_eq > 0.0 { state_eq } else { 10000.0 });
                                        let open_pos = client_msg.open_positions.unwrap_or(state_open_pos);
                                        let db_max_pos = db.get_config("max_positions").await.unwrap_or_else(|| "5".to_string()).parse::<usize>().unwrap_or(5);
                                        let db_max_dd = db.get_config("max_drawdown_pct").await.unwrap_or_else(|| "10.0".to_string()).parse::<f64>().unwrap_or(10.0);
                                        let db_estop = db.get_config("emergency_stop").await.unwrap_or_else(|| "false".to_string()) == "true";

                                        let max_pos = client_msg.max_positions.unwrap_or(db_max_pos);
                                        let max_dd = client_msg.max_drawdown_pct.unwrap_or(db_max_dd);
                                        let estop = client_msg.emergency_stop.unwrap_or(db_estop);
                                        
                                        info!("🤖 [UI] Run Multi-Agents (Multi-TF) requested for {}", sym);
                                        
                                        let gemini_key = db.get_config("gemini_api_key").await.unwrap_or_default();
                                        let gemini_model = db.get_config("gemini_model").await.unwrap_or_default();
                                        let tavily_key = db.get_config("tavily_api_key").await.unwrap_or_default();
                                        
                                        // Multi-timeframe: get candles for M5, M15, H1, H4
                                        let candles_m5 = db.get_candles_for_strategy(&sym, 5, 50).await;
                                        let candles_m15 = db.get_candles_for_strategy(&sym, 15, 50).await;
                                        let candles_h1 = db.get_candles_for_strategy(&sym, 60, 50).await;
                                        let candles_h4 = db.get_candles_for_strategy(&sym, 240, 30).await;

                                        let multi_tf_candles = vec![
                                            ("M5", candles_m5),
                                            ("M15", candles_m15),
                                            ("H1", candles_h1),
                                            ("H4", candles_h4),
                                        ];

                                        let ai_mode = client_msg.ai_mode.clone().unwrap_or_else(|| "auto".to_string());
                                        let tx_agents = tx.clone();
                                        let sym_resp = sym.clone();
                                        let db_agents = db.clone();
                                        let global_data_agents = global_ai_data.clone();
                                        tokio::spawn(async move {
                                            let is_centralized = db_agents.get_config("agent_centralized").await.unwrap_or_else(|| "true".to_string()) == "true";
                                            let global_news = if is_centralized {
                                                let state = global_data_agents.read().await;
                                                state.news.clone()
                                            } else {
                                                None
                                            };
                                            
                                            let result = ai_engine::run_all_agents_multi_tf(
                                                &gemini_key, &gemini_model, &tavily_key,
                                                &sym, &multi_tf_candles,
                                                balance, equity, open_pos, max_pos, max_dd, estop,
                                                &ai_mode,
                                                &[], // Manual runs don't disable agents by default
                                                global_news,
                                                &tx_agents
                                            ).await;
                                            
                                            let resp = serde_json::json!({
                                                "type": "multi_agent_result",
                                                "result": result
                                            });
                                            let _ = tx_agents.send(resp.to_string());
                                        });

                                        let resp = serde_json::json!({ "type": "agents_started", "symbol": sym_resp });
                                        let _ = write.send(Message::Text(resp.to_string())).await;
                                    }
                                    "get_tracked_symbols" => {
                                        let symbols = db.get_tracked_symbols().await;
                                        let mut closed_map = serde_json::Map::new();
                                        let now_ts = chrono::Utc::now().timestamp();
                                        let state = ea_state.read().await;
                                        for sym in &symbols {
                                            // Priority: memory tracked quote time (market_watch), then fallback to db tick
                                            let mut lt = state.last_quote_times.get(sym).copied().unwrap_or(0);
                                            if lt == 0 {
                                                lt = db.get_latest_tick_timestamp(sym).await;
                                            }
                                            closed_map.insert(sym.clone(), serde_json::Value::Bool(now_ts - lt > 300 && lt > 0));
                                        }
                                        let resp = serde_json::json!({
                                            "type": "tracked_symbols",
                                            "symbols": symbols,
                                            "closed_map": closed_map
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
                        // Forward ticks, ea_info, account_data, market_watch, alerts, and trade commands to UI
                        if json.contains("\"tick\"") || json.contains("\"history\"") || json.contains("\"ea_info\"") || json.contains("\"account_data\"") || json.contains("\"market_watch\"") || json.contains("\"trade_result\"") || json.contains("\"trade_history\"") || json.contains("\"update_status\"") || json.contains("\"alert\"") || json.contains("\"modify_sl\"") || json.contains("\"strategy_signal\"") || json.contains("\"engine_status\"") || json.contains("\"candle_data\"") || json.contains("\"ai_response\"") || json.contains("\"ai_analysis\"") || json.contains("\"agent_log\"") || json.contains("\"multi_agent_result\"") || json.contains("\"ai_trade_proposal\"") || json.contains("\"agents_started\"") || json.contains("\"ai_test_result\"") || json.contains("\"ai_models\"") || json.contains("\"telemetry\"") || json.contains("\"global_ai_data\"") || json.contains("\"gap_fill_status\"") {
                            if let Err(e) = write.send(Message::Text(json)).await {
                                error!("❌ [UI] Send error to {}: {}", peer_addr, e);
                                break;
                            }
                        }
                    }
                    Err(tokio::sync::broadcast::error::RecvError::Lagged(skipped)) => {
                        warn!("⚠️ [UI] Receiver lagged, skipped {} messages", skipped);
                    }
                    Err(tokio::sync::broadcast::error::RecvError::Closed) => break,
                }
            }
        }
    }
    info!("🔌 [UI] Connection closed: {}", peer_addr);
}

// ──────────────────────────────────────────────
//  MT5 Auto-Discovery
// ──────────────────────────────────────────────

fn get_wine_appdata() -> PathBuf {
    PathBuf::from("/tmp/ea24_mock_appdata")
}

fn win_to_linux_path(win_path: &str) -> PathBuf {
    let p = win_path.replace("\\", "/");
    let home = std::env::var("HOME").unwrap_or_else(|_| "/root".to_string());
    let prefix = std::env::var("WINEPREFIX").unwrap_or_else(|_| format!("{}/.wine", home));
    
    if p.to_uppercase().starts_with("C:/") {
        PathBuf::from(prefix).join("drive_c").join(&p[3..])
    } else if p.to_uppercase().starts_with("Z:/") {
        PathBuf::from(format!("/{}", &p[3..]))
    } else {
        PathBuf::from(p)
    }
}

fn scan_mt5_instances() -> Vec<Mt5Instance> {
    let appdata = get_wine_appdata();
    let terminal_path = appdata.join("MetaQuotes").join("Terminal");

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

            let linux_install_dir = win_to_linux_path(&install_dir);
            let terminal_exe = PathBuf::from(&install_dir).join("terminal64.exe");
            let experts_dir = linux_install_dir.join("MQL5").join("Experts");
            let has_experts = experts_dir.exists();

            let ea_mq5 = experts_dir.join("EATradingClient.mq5");
            let ea_ex5 = experts_dir.join("EATradingClient.ex5");
            let ea_deployed = ea_ex5.exists();

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
                install_path: linux_install_dir.to_string_lossy().to_string(),
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
    let appdata = get_wine_appdata();
    let instance_dir = appdata
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

/// Helper to dynamically find a viable symbol from Market Watch history
fn find_valid_symbol(linux_install_dir: &Path) -> String {
    let mut valid_symbol = "XAUUSD".to_string(); // Default

    // Look at bases/<broker>/history/<symbol> directories
    let bases_dir = linux_install_dir.join("bases");
    if let Ok(entries) = std::fs::read_dir(&bases_dir) {
        for entry in entries.flatten() {
            if entry.path().is_dir() {
                let history_dir = entry.path().join("history");
                if let Ok(hist_entries) = std::fs::read_dir(history_dir) {
                    for hist_entry in hist_entries.flatten() {
                        let symbol_dir = hist_entry.path();
                        if symbol_dir.is_dir() {
                            let name = symbol_dir.file_name().unwrap_or_default().to_string_lossy().to_string();
                            let lower = name.to_lowercase();
                            let ignore = ["config", "symb", "mail", "symbols", "custom", "cache", "ticks"];
                            if !ignore.contains(&lower.as_str()) && !name.is_empty() {
                                valid_symbol = name.clone();
                                // Prefer XAUUSD or Gold variants if we stumble on them
                                if lower.starts_with("xauusd") || lower.starts_with("gold") {
                                    return name;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    valid_symbol
}

/// Spawn MT5 with a custom `.ini` to auto-attach the EA on XAUUSD M1
fn launch_mt5_instance(instance_dir: &Path) {
    info!("🚀 Attempting to auto-launch MT5 from {:?}", instance_dir);

    let install_dir = match read_install_dir(instance_dir) {
        Some(d) => d,
        None => return,
    };

    let linux_install_dir = win_to_linux_path(&install_dir);
    let exe_path = linux_install_dir.join("terminal64.exe");
    if !exe_path.exists() {
        error!("terminal64.exe not found at {:?}", exe_path);
        return;
    }

    let symbol = find_valid_symbol(&linux_install_dir);
    info!("🔎 Auto-selected chart symbol: {}", symbol);

    // Step 1: Ensure EA is deployed to both AppData and Install paths
    let experts_appdata = instance_dir.join("MQL5").join("Experts");
    let experts_install = linux_install_dir.join("MQL5").join("Experts");
    std::fs::create_dir_all(&experts_appdata).ok();
    std::fs::create_dir_all(&experts_install).ok();

    let source_mq5 = Path::new("mt5/EATradingClient.mq5");
    let source_ex5 = Path::new("mt5/EATradingClient.ex5");
    
    // Copy to AppData (where MT5 reads from)
    if source_mq5.exists() { std::fs::copy(source_mq5, experts_appdata.join("EATradingClient.mq5")).ok(); }
    if source_ex5.exists() { std::fs::copy(source_ex5, experts_appdata.join("EATradingClient.ex5")).ok(); }
    
    // Copy to Install Dir (where MetaEditor compiles from)
    if source_mq5.exists() { std::fs::copy(source_mq5, experts_install.join("EATradingClient.mq5")).ok(); }
    if source_ex5.exists() { std::fs::copy(source_ex5, experts_install.join("EATradingClient.ex5")).ok(); }

    let ea_ex5 = experts_appdata.join("EATradingClient.ex5");
    if !ea_ex5.exists() {
        warn!("⚠️ EA .ex5 not found in AppData {:?}. Please deploy it from the dashboard.", instance_dir.file_name().unwrap_or_default());
    } else {
        info!("✅ EA .ex5 verified present in AppData");
    }

    // If THIS MT5 instance is running, close only this one
    if is_mt5_running(&install_dir) {
        info!("⏳ Closing MT5 instance gracefully: {}", install_dir);
        kill_mt5_instance(&install_dir);

        for i in 0..20 {
            std::thread::sleep(std::time::Duration::from_millis(500));
            if !is_mt5_running(&install_dir) {
                info!("✅ MT5 closed gracefully after {}ms", (i+1) * 500);
                break;
            }
        }
        if is_mt5_running(&install_dir) {
            info!("⚠️ MT5 still running, force killing...");
            force_kill_mt5_instance(&install_dir);
            std::thread::sleep(std::time::Duration::from_secs(2));
        }
    }

    // Step 2: Auto-configure common.ini for EA permissions
    let common_ini_path = linux_install_dir.join("Config").join("common.ini");
    if common_ini_path.exists() {
        info!("⚙️ Auto-configuring EA permissions in common.ini...");
        let bytes = std::fs::read(&common_ini_path).unwrap_or_default();
        let is_utf16le = bytes.starts_with(&[0xFF, 0xFE]);
        let content = if is_utf16le {
            let u16_data: Vec<u16> = bytes[2..]
                .chunks_exact(2)
                .map(|c| u16::from_le_bytes([c[0], c[1]]))
                .collect();
            String::from_utf16_lossy(&u16_data)
        } else {
            String::from_utf8_lossy(&bytes).into_owned()
        };

        let mut result_lines: Vec<String> = Vec::new();
        let mut in_experts = false;
        let mut set_dll = false;
        let mut set_enabled = false;
        let mut set_webrequest = false;

        for line in content.lines() {
            let trimmed = line.trim().trim_matches('\0');
            if trimmed.starts_with('[') {
                // If leaving [Experts] section, ensure all keys were set
                if in_experts {
                    if !set_dll { result_lines.push("AllowDllImport=1".to_string()); }
                    if !set_enabled { result_lines.push("Enabled=1".to_string()); }
                    if !set_webrequest { result_lines.push("WebRequest=1".to_string()); }
                    // Note: WebRequestUrl uses encrypted format, cannot set programmatically
                }
                in_experts = trimmed.to_lowercase() == "[experts]";
                if in_experts {
                    set_dll = false;
                    set_enabled = false;
                    set_webrequest = false;
                }
                result_lines.push(line.to_string());
            } else if in_experts && trimmed.contains('=') {
                let key = trimmed.split('=').next().unwrap_or("").trim();
                match key {
                    "AllowDllImport" => {
                        result_lines.push("AllowDllImport=1".to_string());
                        set_dll = true;
                    }
                    "Enabled" => {
                        result_lines.push("Enabled=1".to_string());
                        set_enabled = true;
                    }
                    "WebRequest" => {
                        result_lines.push("WebRequest=1".to_string());
                        set_webrequest = true;
                    }
                    "WebRequestUrl" => {
                        // Keep existing encrypted value — MT5 uses encrypted format
                        result_lines.push(line.to_string());
                    }
                    _ => {
                        result_lines.push(line.to_string());
                    }
                }
            } else {
                result_lines.push(line.to_string());
            }
        }

        // Handle case where [Experts] was the last section
        if in_experts {
            if !set_dll { result_lines.push("AllowDllImport=1".to_string()); }
            if !set_enabled { result_lines.push("Enabled=1".to_string()); }
            if !set_webrequest { result_lines.push("WebRequest=1".to_string()); }
            // Note: WebRequestUrl uses encrypted format, cannot set programmatically
        }

        let final_text = result_lines.join("\r\n");
        use std::io::Write;
        if let Ok(mut file) = std::fs::File::create(&common_ini_path) {
            if is_utf16le {
                let _ = file.write_all(&[0xFF, 0xFE]);
                let u16_chars: Vec<u16> = final_text.encode_utf16().collect();
                let u8_bytes: Vec<u8> = u16_chars.iter().flat_map(|&c| c.to_le_bytes().into_iter()).collect();
                let _ = file.write_all(&u8_bytes);
            } else {
                let _ = file.write_all(final_text.as_bytes());
            }
            info!("✅ EA permissions configured: AllowDllImport=1, Enabled=1, WebRequest=127.0.0.1");
        }
    }
    // Clone terminal.ini → ea_startup.ini, append [StartUp], launch with /config (absolute path)
    let config_dir = instance_dir.join("config");
    std::fs::create_dir_all(&config_dir).ok();

    let mut terminal_ini_path = config_dir.join("terminal.ini");
    let ea_startup_ini_path = config_dir.join("ea_startup.ini");

    if !terminal_ini_path.exists() {
        let install_dir_config = linux_install_dir.join("Config").join("terminal.ini");
        if install_dir_config.exists() {
            terminal_ini_path = install_dir_config;
        }
    }

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

        // Parse into sections, removing [StartUp], [Experts], and [Window] blocks
        let mut result_lines: Vec<String> = Vec::new();
        let mut skip_section = false;

        for line in content.lines() {
            let trimmed = line.trim().trim_matches('\0');
            if trimmed.starts_with('[') {
                let section_lower = trimmed.to_lowercase();
                skip_section = section_lower == "[startup]"
                    || section_lower == "[experts]"
                    || section_lower == "[window]";
            }
            if !skip_section && !trimmed.is_empty() {
                result_lines.push(line.to_string());
            }
        }

        // Force fullscreen chart: hide all panels
        result_lines.push(String::new());
        result_lines.push("[Window]".to_string());
        result_lines.push("MarketWatch=0".to_string());
        result_lines.push("Navigator=0".to_string());
        result_lines.push("Terminal=0".to_string());
        result_lines.push("DataWindow=0".to_string());
        result_lines.push("Tester=0".to_string());
        result_lines.push("ToolBox=0".to_string());

        // Append our clean EA startup config
        result_lines.push(String::new());
        result_lines.push("[StartUp]".to_string());
        result_lines.push("Expert=EATradingClient".to_string());
        result_lines.push(format!("Symbol={}", symbol));
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
        let fallback = format!("[Window]\r\nMarketWatch=0\r\nNavigator=0\r\nTerminal=0\r\nDataWindow=0\r\nTester=0\r\nToolBox=0\r\n\r\n[StartUp]\r\nExpert=EATradingClient\r\nSymbol={}\r\nPeriod=M1\r\n\r\n[Experts]\r\nAllowLiveTrading=1\r\nEnabled=1\r\n", symbol);
        let _ = std::fs::write(&ea_startup_ini_path, fallback);
    }

    // Step: Auto-compile .mq5 ONLY when version has changed
    let mq5_path = linux_install_dir.join("MQL5").join("Experts").join("EATradingClient.mq5");
    let metaeditor_path = linux_install_dir.join("MetaEditor64.exe");
    if mq5_path.exists() && metaeditor_path.exists() {
        let source_version = read_ea_version_from_mq5(&mq5_path);
        let ex5_exists = ea_ex5.exists();
        // Read version embedded in the currently running server constant
        let deployed_version = if ex5_exists {
            // Compare source .mq5 version vs server's LATEST_EA_VERSION
            LATEST_EA_VERSION.to_string()
        } else {
            "none".to_string()
        };

        if !ex5_exists || source_version != deployed_version {
            info!("🔧 Version changed ({} → {}), auto-compiling EA via MetaEditor...", deployed_version, source_version);
            let _mq5_win = format!("Z:{}", mq5_path.display().to_string().replace('/', "\\"));
            if let Ok(_) = std::process::Command::new("true")
                .arg(&metaeditor_path)
                .arg("-c").arg("exit 0")
                .spawn()
            {
                std::thread::sleep(std::time::Duration::from_secs(5));
                if let Ok(output) = std::process::Command::new("true")
                    .args(&["search", "--name", "MetaEditor"])
                    .output()
                {
                    let ids = String::from_utf8_lossy(&output.stdout);
                    for wid in ids.lines() {
                        let wid = wid.trim();
                        if !wid.is_empty() {
                            let _ = std::process::Command::new("true")
                                .args(&["windowactivate", "--sync", wid])
                                .output();
                            std::thread::sleep(std::time::Duration::from_millis(500));
                            let _ = std::process::Command::new("true")
                                .args(&["key", "F7"])
                                .output();
                            info!("🔧 Sent F7 compile to MetaEditor (window {})", wid);
                        }
                    }
                }
                std::thread::sleep(std::time::Duration::from_secs(10));
                let _ = std::process::Command::new("true")
                    .args(&["-f", "MetaEditor64.exe"])
                    .output();
                info!("🔧 MetaEditor closed");
                std::thread::sleep(std::time::Duration::from_secs(2));

                // IMPORTANT: MetaEditor outputs to install dir, copy to AppData and cache
                let compiled_ex5 = linux_install_dir.join("MQL5").join("Experts").join("EATradingClient.ex5");
                if compiled_ex5.exists() {
                    let experts_appdata = instance_dir.join("MQL5").join("Experts");
                    std::fs::copy(&compiled_ex5, experts_appdata.join("EATradingClient.ex5")).ok();
                    std::fs::copy(&compiled_ex5, Path::new("mt5/EATradingClient.ex5")).ok();
                    info!("✅ Copied newly compiled EATradingClient.ex5 to AppData");
                }
            }
        } else {
            info!("✅ EA version {} is up-to-date, skipping compile", source_version);
        }
    }

    // Launch MT5 with ABSOLUTE path to /config map to Z: so Wine understands
    let config_arg = format!("/config:Z:{}", ea_startup_ini_path.display().to_string().replace('/', "\\"));
    info!("🚀 Spawning: {:?} {}", exe_path, config_arg);
    match std::process::Command::new("true").arg(&exe_path).arg(&config_arg).spawn() {
        Ok(_) => {
            info!("✅ Successfully launched MT5 with EA!");
            // Minimize the MT5 window after it loads
            std::thread::spawn(|| {
                std::thread::sleep(std::time::Duration::from_secs(10));
                info!("🔽 Attempting to minimize MT5 window...");
                let search = std::process::Command::new("true")
                    .args(&["search", "--name", "MetaTrader"])
                    .output();
                match search {
                    Ok(output) => {
                        let ids = String::from_utf8_lossy(&output.stdout);
                        for wid in ids.lines() {
                            let wid = wid.trim();
                            if !wid.is_empty() {
                                let _ = std::process::Command::new("true")
                                    .args(&["windowminimize", wid])
                                    .output();
                                info!("🔽 Minimized MT5 window: {}", wid);
                            }
                        }
                    }
                    Err(e) => warn!("⚠️ xdotool search failed: {}", e),
                }
            });
        }
        Err(e) => error!("❌ Failed to spawn MT5: {}", e),
    }
}

/// Check if a specific MT5 instance is running by matching its install path
fn is_mt5_running(install_dir: &str) -> bool {
    // Use pgrep to list processes containing terminal64.exe and the install dir
    match std::process::Command::new("pgrep")
        .args(&["-f", "-a", "terminal64.exe"])
        .output()
    {
        Ok(output) => {
            let text = String::from_utf8_lossy(&output.stdout);
            let normalized_install = install_dir.replace('\\', "/");
            let win_install = install_dir.to_lowercase();
            
            for line in text.lines() {
                let lower_line = line.to_lowercase();
                if lower_line.contains(&win_install) || lower_line.contains(&normalized_install.to_lowercase()) {
                    return true;
                }
            }
            false
        }
        Err(_) => false,
    }
}

/// Kill a specific MT5 instance gracefully by matching its install path
fn kill_mt5_instance(install_dir: &str) {
    if let Ok(output) = std::process::Command::new("pgrep")
        .args(&["-f", "-a", "terminal64.exe"])
        .output()
    {
        let text = String::from_utf8_lossy(&output.stdout);
        let normalized = install_dir.replace('\\', "/").to_lowercase();
        let win_path = install_dir.to_lowercase();
        for line in text.lines() {
            let lower = line.to_lowercase();
            if lower.contains(&win_path) || lower.contains(&normalized) {
                if let Some(pid) = line.split_whitespace().next() {
                    info!("🛑 Killing MT5 process {} for {}", pid, install_dir);
                    let _ = std::process::Command::new("kill")
                        .arg(pid)
                        .output();
                }
            }
        }
    }
}

/// Force kill a specific MT5 instance
fn force_kill_mt5_instance(install_dir: &str) {
    if let Ok(output) = std::process::Command::new("pgrep")
        .args(&["-f", "-a", "terminal64.exe"])
        .output()
    {
        let text = String::from_utf8_lossy(&output.stdout);
        let normalized = install_dir.replace('\\', "/").to_lowercase();
        let win_path = install_dir.to_lowercase();
        for line in text.lines() {
            let lower = line.to_lowercase();
            if lower.contains(&win_path) || lower.contains(&normalized) {
                if let Some(pid) = line.split_whitespace().next() {
                    info!("💀 Force killing MT5 process {} for {}", pid, install_dir);
                    let _ = std::process::Command::new("kill")
                        .args(&["-9", pid])
                        .output();
                }
            }
        }
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

    // Handle MT5 Icon dynamically
    if relative.starts_with("icon/") {
        let instance_id = relative.trim_start_matches("icon/");
        let instances = scan_mt5_instances();
        if let Some(inst) = instances.iter().find(|i| i.id == instance_id) {
            // Convert Wine path e.g. C:\Program Files\... to native Linux path ~/.wine/drive_c/...
            let linux_install_dir = win_to_linux_path(&inst.install_path);
            let icon_path = linux_install_dir.join("Terminal.ico");
            if let Ok(bytes) = std::fs::read(&icon_path) {
                let response = format!(
                    "HTTP/1.1 200 OK\r\nContent-Type: image/x-icon\r\nContent-Length: {}\r\nAccess-Control-Allow-Origin: *\r\nCache-Control: public, max-age=86400\r\nConnection: close\r\n\r\n",
                    bytes.len()
                );
                let _ = stream.write_all(response.as_bytes()).await;
                let _ = stream.write_all(&bytes).await;
                return;
            }
        }
    }

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
