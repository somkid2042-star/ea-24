use log::{info, warn};
use std::sync::Arc;
use tokio::sync::RwLock;
use std::collections::HashMap;
use std::time::{Duration, Instant};

// ──────────────────────────────────────────────
//  Smart API Key Cooldown Manager
// ──────────────────────────────────────────────

pub struct KeyCooldownManager {
    /// Maps key index -> (cooldown_until, consecutive_failures)
    cooldowns: RwLock<HashMap<usize, (Instant, u32)>>,
}

impl KeyCooldownManager {
    pub fn new() -> Self {
        Self { cooldowns: RwLock::new(HashMap::new()) }
    }

    /// Mark a key as rate-limited (429). Cooldown scales with consecutive failures.
    pub async fn mark_rate_limited(&self, key_idx: usize) {
        let mut map = self.cooldowns.write().await;
        let entry = map.entry(key_idx).or_insert((Instant::now(), 0));
        entry.1 += 1; // increment consecutive failures
        let cooldown_secs = match entry.1 {
            1 => 30,
            2 => 60,
            3 => 120,
            _ => 180,
        };
        entry.0 = Instant::now() + Duration::from_secs(cooldown_secs);
        info!("🔑 Key #{} cooling down for {}s (consecutive fails: {})", key_idx + 1, cooldown_secs, entry.1);
    }

    /// Mark a key as successful — reset its cooldown.
    pub async fn mark_success(&self, key_idx: usize) {
        let mut map = self.cooldowns.write().await;
        map.remove(&key_idx);
    }

    /// Check if a key is currently in cooldown.
    pub async fn is_available(&self, key_idx: usize) -> bool {
        let map = self.cooldowns.read().await;
        match map.get(&key_idx) {
            Some((until, _)) => Instant::now() >= *until,
            None => true,
        }
    }

    /// Get status summary for all keys (for /status command)
    #[allow(dead_code)]
    pub async fn get_status_summary(&self, total_keys: usize) -> String {
        let map = self.cooldowns.read().await;
        let available = (0..total_keys).filter(|i| {
            map.get(i).map(|(until, _)| Instant::now() >= *until).unwrap_or(true)
        }).count();
        let cooling = total_keys - available;
        format!("🔑 API Keys: {}/{} พร้อม, {} cooling down", available, total_keys, cooling)
    }
}

// Global singleton

// Simple global accessor using OnceLock
static KEY_MANAGER: std::sync::OnceLock<Arc<KeyCooldownManager>> = std::sync::OnceLock::new();

pub fn get_key_manager() -> Arc<KeyCooldownManager> {
    KEY_MANAGER.get_or_init(|| Arc::new(KeyCooldownManager::new())).clone()
}

// ──────────────────────────────────────────────
//  Telegram: Send Messages  
// ──────────────────────────────────────────────

/// Send a Telegram message
pub async fn send_telegram_notify(bot_token: &str, chat_id: &str, message: &str) -> bool {
    if bot_token.is_empty() || chat_id.is_empty() {
        return false;
    }
    let client = reqwest::Client::new();
    let url = format!("https://api.telegram.org/bot{}/sendMessage", bot_token);
    let payload = serde_json::json!({
        "chat_id": chat_id,
        "text": message,
        "parse_mode": "HTML",
    });
    
    match client.post(&url).json(&payload).send().await {
        Ok(resp) => {
            let ok = resp.status().is_success();
            if !ok {
                info!("⚠️ Telegram Notify failed: status {}", resp.status());
            }
            ok
        }
        Err(e) => {
            info!("⚠️ Telegram Notify error: {}", e);
            false
        }
    }
}

/// Send Telegram message with inline keyboard buttons
#[allow(dead_code)]
pub async fn send_telegram_with_buttons(bot_token: &str, chat_id: &str, message: &str, buttons: Vec<(String, String)>) -> bool {
    if bot_token.is_empty() || chat_id.is_empty() {
        return false;
    }
    let client = reqwest::Client::new();
    let url = format!("https://api.telegram.org/bot{}/sendMessage", bot_token);
    
    let keyboard_buttons: Vec<serde_json::Value> = buttons.iter().map(|(text, data)| {
        serde_json::json!({ "text": text, "callback_data": data })
    }).collect();
    
    let payload = serde_json::json!({
        "chat_id": chat_id,
        "text": message,
        "parse_mode": "HTML",
        "reply_markup": {
            "inline_keyboard": [keyboard_buttons]
        }
    });
    
    match client.post(&url).json(&payload).send().await {
        Ok(resp) => resp.status().is_success(),
        Err(_) => false,
    }
}

// ──────────────────────────────────────────────
//  Telegram Bot: Command Polling Loop
// ──────────────────────────────────────────────

#[allow(dead_code)]
pub async fn start_telegram_bot_loop(
    db: Arc<crate::db::Database>,
    tx: tokio::sync::broadcast::Sender<String>,
    ea_state: Arc<RwLock<crate::EaState>>,
) {
    let bot_token = db.get_config("telegram_bot_token").await.unwrap_or_default();
    let chat_id = db.get_config("telegram_chat_id").await.unwrap_or_default();
    
    if bot_token.is_empty() || chat_id.is_empty() {
        info!("📱 Telegram Bot: ไม่มี token/chat_id — ข้ามการเปิด bot");
        return;
    }
    
    info!("📱 Telegram Bot: เริ่มรับคำสั่ง...");
    let client = reqwest::Client::builder()
        .timeout(Duration::from_secs(35))
        .build().unwrap_or_default();
    
    let mut last_update_id: i64 = 0;
    
    loop {
        let url = format!(
            "https://api.telegram.org/bot{}/getUpdates?offset={}&timeout=30", 
            bot_token, last_update_id + 1
        );
        
        match client.get(&url).send().await {
            Ok(resp) => {
                if let Ok(body) = resp.json::<serde_json::Value>().await {
                    if let Some(updates) = body["result"].as_array() {
                        for update in updates {
                            last_update_id = update["update_id"].as_i64().unwrap_or(last_update_id);
                            
                            // Handle text commands
                            if let Some(text) = update["message"]["text"].as_str() {
                                let from_chat = update["message"]["chat"]["id"].as_i64().unwrap_or(0).to_string();
                                if from_chat != chat_id { continue; }
                                
                                let response = handle_telegram_command(text, &db, &tx, &ea_state).await;
                                send_telegram_notify(&bot_token, &chat_id, &response).await;
                            }
                            
                            // Handle inline keyboard callbacks
                            if let Some(data) = update["callback_query"]["data"].as_str() {
                                let callback_id = update["callback_query"]["id"].as_str().unwrap_or("");
                                let from_chat = update["callback_query"]["message"]["chat"]["id"].as_i64().unwrap_or(0).to_string();
                                if from_chat != chat_id { continue; }
                                
                                let response = handle_telegram_command(data, &db, &tx, &ea_state).await;
                                send_telegram_notify(&bot_token, &chat_id, &response).await;
                                
                                // Answer callback to remove loading state
                                let answer_url = format!("https://api.telegram.org/bot{}/answerCallbackQuery?callback_query_id={}", bot_token, callback_id);
                                let _ = client.get(&answer_url).send().await;
                            }
                        }
                    }
                }
            }
            Err(e) => {
                warn!("📱 Telegram Bot poll error: {}", e);
                tokio::time::sleep(Duration::from_secs(5)).await;
            }
        }
    }
}

#[allow(dead_code)]
async fn handle_telegram_command(
    text: &str,
    db: &Arc<crate::db::Database>,
    tx: &tokio::sync::broadcast::Sender<String>,
    ea_state: &Arc<RwLock<crate::EaState>>,
) -> String {
    let cmd = text.trim().to_lowercase();
    
    match cmd.as_str() {
        "/start" | "/help" => {
            "🤖 <b>EA-24 Bot Commands</b>\n\n\
             /status — ดูสถานะระบบ\n\
             /balance — ดู Balance/Equity\n\
             /pause — หยุด Auto-Pilot\n\
             /resume — เริ่ม Auto-Pilot\n\
             /force — วิเคราะห์ทุก symbol ทันที\n\
             /keys — ดูสถานะ API Keys".to_string()
        }
        
        "/status" => {
            let state = ea_state.read().await;
            let auto = db.get_config("ai_auto_analyze").await.unwrap_or_else(|| "false".to_string());
            let jobs_str = db.get_config("ai_autopilot_jobs").await.unwrap_or_else(|| "[]".to_string());
            let jobs: Vec<serde_json::Value> = serde_json::from_str(&jobs_str).unwrap_or_default();
            
            let symbols: Vec<String> = jobs.iter()
                .filter_map(|j| j["symbol"].as_str().map(|s| s.to_string()))
                .collect();
            
            let key_count = db.get_config("gemini_api_key").await.unwrap_or_default()
                .split(',').filter(|s| !s.trim().is_empty()).count();
            
            let key_status = get_key_manager().get_status_summary(key_count).await;
            
            format!(
                "📊 <b>EA-24 Status</b>\n\n\
                 🔄 Auto-Pilot: {}\n\
                 📈 Symbols: {}\n\
                 💰 Balance: ${:.2}\n\
                 💎 Equity: ${:.2}\n\
                 📂 Open Positions: {}\n\
                 {}\n\
                 ⏰ {}",
                if auto == "true" { "🟢 ON" } else { "🔴 OFF" },
                if symbols.is_empty() { "ไม่มี".to_string() } else { symbols.join(", ") },
                state.balance,
                state.equity,
                state.open_positions,
                key_status,
                chrono::Local::now().format("%H:%M:%S %d/%m/%Y")
            )
        }
        
        "/balance" => {
            let state = ea_state.read().await;
            let pnl = state.equity - state.balance;
            let pnl_emoji = if pnl >= 0.0 { "📈" } else { "📉" };
            format!(
                "💰 <b>Account Info</b>\n\n\
                 Balance: <b>${:.2}</b>\n\
                 Equity: <b>${:.2}</b>\n\
                 {} P/L: <b>{}{:.2}$</b>\n\
                 📂 Positions: {}",
                state.balance, state.equity,
                pnl_emoji, if pnl >= 0.0 { "+" } else { "" }, pnl,
                state.open_positions
            )
        }
        
        "/pause" => {
            db.set_config("ai_auto_analyze", "false").await;
            "⏸️ Auto-Pilot <b>หยุดทำงาน</b> แล้ว\nใช้ /resume เพื่อเริ่มใหม่".to_string()
        }
        
        "/resume" => {
            db.set_config("ai_auto_analyze", "true").await;
            "▶️ Auto-Pilot <b>เริ่มทำงาน</b> แล้ว!".to_string()
        }
        
        "/force" => {
            let jobs_str = db.get_config("ai_autopilot_jobs").await.unwrap_or_else(|| "[]".to_string());
            let jobs: Vec<serde_json::Value> = serde_json::from_str(&jobs_str).unwrap_or_default();
            let symbols: Vec<String> = jobs.iter()
                .filter_map(|j| j["symbol"].as_str().map(|s| s.to_string()))
                .collect();
            
            // Send force_analyze command via broadcast
            for sym in &symbols {
                let cmd = serde_json::json!({
                    "type": "force_analyze",
                    "symbol": sym,
                }).to_string();
                let _ = tx.send(cmd);
            }
            
            format!("🚀 สั่ง Force Analyze: {}\nกำลังวิเคราะห์...", symbols.join(", "))
        }
        
        "/keys" => {
            let key_count = db.get_config("gemini_api_key").await.unwrap_or_default()
                .split(',').filter(|s| !s.trim().is_empty()).count();
            let status = get_key_manager().get_status_summary(key_count).await;
            format!("🔑 <b>API Key Status</b>\n\n{}", status)
        }
        
        _ => {
            if cmd.starts_with("/close") {
                // Not directly possible without MT5 integration
                "⚠️ ปิดออเดอร์ต้องทำผ่าน Dashboard หรือ MT5 โดยตรง".to_string()
            } else {
                "❓ คำสั่งไม่รู้จัก — ใช้ /help เพื่อดูรายการคำสั่ง".to_string()
            }
        }
    }
}

// ──────────────────────────────────────────────
//  Notification Formatters (Original)
// ──────────────────────────────────────────────

/// Format trade open notification
pub fn format_trade_open(symbol: &str, direction: &str, lot: f64, price: f64, strategy: &str) -> String {
    format!(
        "\n🟢 เปิดออเดอร์ใหม่\n📊 {} {} {:.2} lot\n💰 ราคา: {:.5}\n🎯 กลยุทธ์: {}\n⏰ {}",
        symbol, 
        if direction == "BUY" { "ซื้อ" } else { "ขาย" },
        lot, price, strategy,
        chrono::Local::now().format("%H:%M:%S %d/%m/%Y")
    )
}

/// Format trade close notification  
pub fn format_trade_close(symbol: &str, direction: &str, lot: f64, pnl: f64) -> String {
    let emoji = if pnl >= 0.0 { "🟢" } else { "🔴" };
    format!(
        "\n{} ปิดออเดอร์\n📊 {} {} {:.2} lot\n💵 กำไร/ขาดทุน: {}{:.2} $\n⏰ {}",
        emoji, symbol, 
        if direction == "BUY" { "ซื้อ" } else { "ขาย" },
        lot, if pnl >= 0.0 { "+" } else { "" }, pnl,
        chrono::Local::now().format("%H:%M:%S %d/%m/%Y")
    )
}

/// Format EA disconnect notification
#[allow(dead_code)]
pub fn format_ea_disconnect() -> String {
    format!(
        "\n⚠️ EA หลุดการเชื่อมต่อ!\n🔌 MT5 ไม่ตอบสนอง\n⏰ {}",
        chrono::Local::now().format("%H:%M:%S %d/%m/%Y")
    )
}

/// Format daily summary
#[allow(dead_code)]
pub fn format_daily_summary(profit: f64, trades: i64, win_rate: f64) -> String {
    let emoji = if profit >= 0.0 { "📈" } else { "📉" };
    format!(
        "\n{} สรุปผลประจำวัน\n💰 กำไร/ขาดทุน: {}{:.2} $\n📊 จำนวนเทรด: {} ออเดอร์\n🎯 Win Rate: {:.1}%\n⏰ {}",
        emoji, if profit >= 0.0 { "+" } else { "" }, profit,
        trades, win_rate,
        chrono::Local::now().format("%d/%m/%Y")
    )
}

/// Format risk alert
pub fn format_risk_alert(drawdown: f64, max_dd: f64) -> String {
    format!(
        "\n🚨 แจ้งเตือนความเสี่ยง!\n📉 Drawdown วันนี้: {:.2} $\n⛔ ขีดจำกัด: {:.2} $\n🛑 หยุดเทรดอัตโนมัติ\n⏰ {}",
        drawdown, max_dd,
        chrono::Local::now().format("%H:%M:%S %d/%m/%Y")
    )
}
