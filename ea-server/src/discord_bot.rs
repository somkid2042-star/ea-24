use log::{info, warn};
use serenity::async_trait;
use serenity::model::channel::Message;
use serenity::model::gateway::Ready;
use serenity::model::id::ChannelId;
use serenity::prelude::*;
use serenity::http::Http;
use std::sync::Arc;
use tokio::sync::RwLock;

// Global HTTP client to send messages from anywhere in the app
pub static DISCORD_HTTP: std::sync::OnceLock<Arc<Http>> = std::sync::OnceLock::new();

struct Handler {
    db: Arc<crate::db::Database>,
    tx: tokio::sync::broadcast::Sender<String>,
    ea_state: Arc<RwLock<crate::EaState>>,
}

#[async_trait]
impl EventHandler for Handler {
    async fn message(&self, ctx: Context, msg: Message) {
        // Ignore messages from self or other bots
        if msg.author.bot {
            return;
        }

        // Only listen in the ai-chat channel to avoid triggering on logs/reports
        let chat_channel = self.db.get_config("discord_channel_chat").await.unwrap_or_default();
        if chat_channel.is_empty() || msg.channel_id.to_string() != chat_channel {
            return; // Not the designated chat channel
        }

        let cmd = msg.content.trim();
        
        if cmd.starts_with("!") {
            let response = handle_discord_command(cmd, &self.db, &self.tx, &self.ea_state).await;
            if let Err(e) = msg.channel_id.say(&ctx.http, response).await {
                warn!("⚠️ Discord Reply error: {}", e);
            }
        }
    }

    async fn ready(&self, _: Context, ready: Ready) {
        info!("🎮 Discord Bot Connected as {}", ready.user.name);
    }
}

async fn handle_discord_command(
    text: &str,
    db: &Arc<crate::db::Database>,
    tx: &tokio::sync::broadcast::Sender<String>,
    ea_state: &Arc<RwLock<crate::EaState>>,
) -> String {
    let parts: Vec<&str> = text.split_whitespace().collect();
    if parts.is_empty() { return "❓ CMD?".into(); }
    
    let cmd = parts[0].to_lowercase();
    
    match cmd.as_str() {
        "!start" | "!help" => {
            "🤖 **EA-24 Discord Command Center**\n\n\
             `!status` — ดูสถานะระบบ\n\
             `!balance` — ดู Balance/Equity\n\
             `!pause` — หยุด Auto-Pilot\n\
             `!resume` — เริ่ม Auto-Pilot\n\
             `!force` — วิเคราะห์ทุก symbol ทันที\n\
             `!ask [SYMBOL]` — สั่งให้ Gemini วิเคราะห์กราฟเดี๋ยวนี้".to_string()
        }
        
        "!status" => {
            let state = ea_state.read().await;
            let auto = db.get_config("ai_auto_analyze").await.unwrap_or_else(|| "false".to_string());
            let jobs_str = db.get_config("ai_autopilot_jobs").await.unwrap_or_else(|| "[]".to_string());
            let jobs: Vec<serde_json::Value> = serde_json::from_str(&jobs_str).unwrap_or_default();
            
            let symbols: Vec<String> = jobs.iter()
                .filter_map(|j| j["symbol"].as_str().map(|s| s.to_string()))
                .collect();
            
            format!(
                "📊 **EA-24 Status**\n\n\
                 🔄 Auto-Pilot: {}\n\
                 📈 Symbols: {}\n\
                 💰 Balance: ${:.2}\n\
                 💎 Equity: ${:.2}\n\
                 📂 Open Positions: {}\n\
                 ⏰ {}",
                if auto == "true" { "🟢 ON" } else { "🔴 OFF" },
                if symbols.is_empty() { "ไม่มี".to_string() } else { symbols.join(", ") },
                state.balance,
                state.equity,
                state.open_positions,
                chrono::Local::now().format("%H:%M:%S %d/%m/%Y")
            )
        }
        
        "!balance" => {
            let state = ea_state.read().await;
            let pnl = state.equity - state.balance;
            let pnl_emoji = if pnl >= 0.0 { "📈" } else { "📉" };
            format!(
                "💰 **Account Info**\n\n\
                 Balance: **${:.2}**\n\
                 Equity: **${:.2}**\n\
                 {} P/L: **{}{:.2}$**\n\
                 📂 Positions: {}",
                state.balance, state.equity,
                pnl_emoji, if pnl >= 0.0 { "+" } else { "" }, pnl,
                state.open_positions
            )
        }
        
        "!pause" => {
            db.set_config("ai_auto_analyze", "false").await;
            "⏸️ Auto-Pilot **หยุดทำงาน** แล้ว\nใช้ `!resume` เพื่อเริ่มใหม่".to_string()
        }
        
        "!resume" => {
            db.set_config("ai_auto_analyze", "true").await;
            "▶️ Auto-Pilot **เริ่มทำงาน** แล้ว!".to_string()
        }
        
        "!force" => {
            let jobs_str = db.get_config("ai_autopilot_jobs").await.unwrap_or_else(|| "[]".to_string());
            let jobs: Vec<serde_json::Value> = serde_json::from_str(&jobs_str).unwrap_or_default();
            let symbols: Vec<String> = jobs.iter()
                .filter_map(|j| j["symbol"].as_str().map(|s| s.to_string()))
                .collect();
            
            for sym in &symbols {
                let cmd = serde_json::json!({
                    "type": "force_analyze",
                    "symbol": sym,
                }).to_string();
                let _ = tx.send(cmd);
            }
            
            format!("🚀 สั่ง Force Analyze: {}\nกำลังวิเคราะห์...", symbols.join(", "))
        }

        "!ask" => {
            if parts.len() < 2 {
                return "⚠️ รบกวนระบุคู่เงินด้วยครับ เช่น `!ask XAUUSD`".to_string();
            }
            let sym = parts[1].to_uppercase();
            // Start a force analyze which will dump into the Discord order channel
            let cmd = serde_json::json!({
                "type": "force_analyze",
                "symbol": sym,
            }).to_string();
            let _ = tx.send(cmd);

            format!("🧠 รับทราบครับ กำลังสั่งให้ Gemini วิเคราะห์กราฟ **{}**... (ผลจะส่งไปที่ห้อง Order)", sym)
        }
        
        _ => "❓ คำสั่งไม่รู้จัก — ใช้ `!help` เพื่อดูรายการคำสั่ง".to_string(),
    }
}

// ──────────────────────────────────────────────
//  Start Loop
// ──────────────────────────────────────────────

pub async fn start_discord_bot(
    db: Arc<crate::db::Database>,
    tx: tokio::sync::broadcast::Sender<String>,
    ea_state: Arc<RwLock<crate::EaState>>,
) {
    let token = db.get_config("discord_bot_token").await.unwrap_or_default();
    if token.is_empty() {
        info!("🎮 Discord Bot: ไม่มี Token — ข้ามการเปิดบอท");
        return;
    }

    let intents = GatewayIntents::GUILD_MESSAGES | GatewayIntents::MESSAGE_CONTENT;

    // Use serenity's built-in client configuration
    let mut client = Client::builder(&token, intents)
        .event_handler(Handler {
            db: db.clone(),
            tx: tx.clone(),
            ea_state: ea_state.clone(),
        })
        .await
        .expect("Error creating Discord client");

    // Store Http globally to enable sending messages from other threads
    let _ = DISCORD_HTTP.set(client.http.clone());

    info!("🎮 Discord Bot: กำลังเชื่อมต่อ...");
    if let Err(why) = client.start().await {
        warn!("🎮 Discord Bot error: {:?}", why);
    }
}

// ──────────────────────────────────────────────
//  Public Helper for Application-Wide Sends
// ──────────────────────────────────────────────

pub async fn send_to_channel(channel_id_str: &str, msg: &str) -> bool {
    if channel_id_str.is_empty() || msg.is_empty() { return false; }
    
    // Parse the channel ID
    let Ok(id) = channel_id_str.parse::<u64>() else { return false; };
    let channel_id = ChannelId::new(id);

    if let Some(http) = DISCORD_HTTP.get() {
        match channel_id.say(http, msg).await {
            Ok(_) => true,
            Err(e) => {
                warn!("⚠️ Discord output error: {:?}", e);
                false
            }
        }
    } else {
        warn!("⚠️ Discord HTTP Client not initialized");
        false
    }
}

/// Send a chart image + text message to a Discord channel
pub async fn send_chart_to_channel(channel_id_str: &str, msg: &str, image_data: &[u8], filename: &str) -> bool {
    if channel_id_str.is_empty() { return false; }
    
    let Ok(id) = channel_id_str.parse::<u64>() else { return false; };
    let channel_id = ChannelId::new(id);

    if let Some(http) = DISCORD_HTTP.get() {
        use serenity::builder::{CreateMessage, CreateAttachment};
        
        let attachment = CreateAttachment::bytes(image_data.to_vec(), filename.to_string());
        let message = CreateMessage::new()
            .content(msg)
            .add_file(attachment);

        match channel_id.send_message(http, message).await {
            Ok(_) => {
                info!("📊 Chart sent to Discord channel {}", channel_id_str);
                true
            }
            Err(e) => {
                warn!("⚠️ Discord chart send error: {:?}", e);
                false
            }
        }
    } else {
        warn!("⚠️ Discord HTTP Client not initialized");
        false
    }
}
