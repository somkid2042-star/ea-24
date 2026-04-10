// ──────────────────────────────────────────────
//  Position Manager — AI Portfolio Guardian
//  Monitors open positions and takes action:
//  HOLD / CLOSE / HEDGE / PARTIAL_CLOSE / MODIFY_SL
// ──────────────────────────────────────────────

use log::{info, warn};
use serde::{Serialize, Deserialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PositionInfo {
    pub ticket: i64,
    pub symbol: String,
    pub direction: String,  // "BUY" or "SELL"
    pub volume: f64,
    pub open_price: f64,
    pub current_price: f64,
    pub pnl: f64,
    pub swap: f64,
    pub comment: String,
}

#[derive(Debug, Clone, Serialize)]
pub struct ManageResult {
    pub action: String,        // HOLD, CLOSE, HEDGE, PARTIAL_CLOSE, MODIFY_SL
    pub ticket: i64,
    pub symbol: String,
    pub reasoning: String,
    pub hedge_direction: Option<String>,
    pub hedge_lot: Option<f64>,
}

pub struct ManageContext {
    pub symbol: String,
    pub positions: Vec<PositionInfo>,
    pub balance: f64,
    pub equity: f64,
    pub gemini_key: String,
    pub gemini_model: String,
    pub max_loss_usd: f64,
    pub manage_interval: i32,
    pub hedge_enabled: bool,
    pub discord_alert: bool,
    pub discord_channel_order: String,
    pub job_config: serde_json::Value,
}

/// Parse positions from MT5 JSON array and filter by symbol
pub fn parse_positions(positions_detail: &[serde_json::Value], symbol: &str) -> Vec<PositionInfo> {
    positions_detail.iter().filter_map(|p| {
        let sym = p["symbol"].as_str().unwrap_or("");
        // Match exact symbol or symbol without broker suffix
        let sym_base = sym.split('.').next().unwrap_or(sym);
        let target_base = symbol.split('.').next().unwrap_or(symbol);
        
        if sym != symbol && sym_base != target_base && sym != target_base {
            return None;
        }
        
        let direction = match p["type"].as_i64().unwrap_or(-1) {
            0 => "BUY",
            1 => "SELL",
            _ => return None,
        };
        
        Some(PositionInfo {
            ticket: p["ticket"].as_i64().unwrap_or(0),
            symbol: sym.to_string(),
            direction: direction.to_string(),
            volume: p["volume"].as_f64().unwrap_or(0.0),
            open_price: p["open_price"].as_f64().unwrap_or(p["price_open"].as_f64().unwrap_or(0.0)),
            current_price: p["current_price"].as_f64().unwrap_or(p["price_current"].as_f64().unwrap_or(0.0)),
            pnl: p["pnl"].as_f64().unwrap_or(p["profit"].as_f64().unwrap_or(0.0)),
            swap: p["swap"].as_f64().unwrap_or(0.0),
            comment: p["comment"].as_str().unwrap_or("").to_string(),
        })
    }).collect()
}

/// Main entry: manage open positions with AI
pub async fn manage_positions(
    ctx: &ManageContext,
    log_tx: &tokio::sync::broadcast::Sender<String>,
) -> Vec<ManageResult> {
    let mut results = Vec::new();
    
    if ctx.positions.is_empty() {
        return results;
    }
    
    let total_pnl: f64 = ctx.positions.iter().map(|p| p.pnl).sum();
    let total_volume: f64 = ctx.positions.iter().map(|p| p.volume).sum();
    
    info!("🛡️ [Position Manager] {} positions on {} | Total P&L: ${:.2} | Threshold: ${:.2}",
        ctx.positions.len(), ctx.symbol, total_pnl, ctx.max_loss_usd);
    
    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": ctx.symbol, "agent": "position_manager", "status": "running",
        "message": format!("กำลังดูแลออเดอร์ {} ออเดอร์ | P&L: ${:.2}", ctx.positions.len(), total_pnl)
    }).to_string());
    
    // Build position summary for AI
    let mut pos_summary = String::new();
    for (i, p) in ctx.positions.iter().enumerate() {
        pos_summary.push_str(&format!(
            "#{} Ticket:{} {} {:.2} lots @ {:.5} → {:.5} | P&L: ${:.2} | Swap: ${:.2} | {}\n",
            i+1, p.ticket, p.direction, p.volume, p.open_price, p.current_price,
            p.pnl, p.swap, p.comment
        ));
    }
    
    // Ask AI to analyze each position
    let prompt = format!(
r#"You are an AI portfolio manager for forex/crypto trading. Analyze EACH open position below and decide the best action.

## Open Positions on {symbol}
{positions}

## Portfolio Status
- Balance: ${balance:.2}
- Equity: ${equity:.2}
- Total P&L: ${total_pnl:.2}
- Max Loss Threshold: ${max_loss:.2} (if loss exceeds this, consider HEDGE)
- Hedge Enabled: {hedge_enabled}

## Rules
1. For each position, decide ONE action:
   - **HOLD**: Position is OK, let it run
   - **CLOSE**: Close this position (take profit or cut loss)
   - **HEDGE**: Open opposite position to lock loss (ONLY if loss > ${max_loss:.2} AND hedge is enabled)
   - **PARTIAL_CLOSE**: Close 50% of position (lock some profit)
   - **MODIFY_SL**: Move SL to breakeven (when in profit)

2. Priority rules:
   - If a position's loss > ${max_loss:.2} AND hedge_enabled → HEDGE
   - If a position is profitable > $20 → consider PARTIAL_CLOSE or MODIFY_SL
   - If trend is reversing against position → CLOSE
   - Default: HOLD

3. For HEDGE action, specify the opposite direction and same lot size

Respond EXACTLY in this JSON format (array of decisions, one per position):
[
  {{
    "ticket": 12345,
    "action": "HOLD",
    "reasoning": "เหตุผลภาษาไทย 1 บรรทัด"
  }}
]

ONLY output valid JSON array. No markdown, no explanation outside JSON."#,
        symbol = ctx.symbol,
        positions = pos_summary,
        balance = ctx.balance,
        equity = ctx.equity,
        total_pnl = total_pnl,
        max_loss = ctx.max_loss_usd,
        hedge_enabled = ctx.hedge_enabled,
    );
    
    match crate::ai_engine::call_ai_pub(&ctx.gemini_key, &ctx.gemini_model, &prompt, 0.3, 2048, true).await {
        Ok(response) => {
            // Parse JSON response
            let clean = response.trim().trim_start_matches("```json").trim_start_matches("```").trim_end_matches("```").trim();
            
            match serde_json::from_str::<Vec<serde_json::Value>>(clean) {
                Ok(decisions) => {
                    for decision in decisions {
                        let ticket = decision["ticket"].as_i64().unwrap_or(0);
                        let action = decision["action"].as_str().unwrap_or("HOLD").to_uppercase();
                        let reasoning = decision["reasoning"].as_str().unwrap_or("").to_string();
                        
                        // Find matching position
                        let pos = ctx.positions.iter().find(|p| p.ticket == ticket);
                        let pos = match pos {
                            Some(p) => p,
                            None => continue,
                        };
                        
                        let (hedge_dir, hedge_lot) = if action == "HEDGE" && ctx.hedge_enabled {
                            let dir = if pos.direction == "BUY" { "SELL" } else { "BUY" };
                            (Some(dir.to_string()), Some(pos.volume))
                        } else {
                            (None, None)
                        };
                        
                        let emoji = match action.as_str() {
                            "HOLD" => "⏳",
                            "CLOSE" => "🔴",
                            "HEDGE" => "🛡️",
                            "PARTIAL_CLOSE" => "📊",
                            "MODIFY_SL" => "🔒",
                            _ => "❓",
                        };
                        
                        info!("{} [Position Manager] #{} {} → {} | {}", emoji, ticket, pos.direction, action, reasoning);
                        
                        let _ = log_tx.send(serde_json::json!({
                            "type": "agent_log", "symbol": ctx.symbol, "agent": "position_manager", "status": "running",
                            "message": format!("{} #{} {} {:.2}lot P&L:${:.2} → {} | {}",
                                emoji, ticket, pos.direction, pos.volume, pos.pnl, action, reasoning)
                        }).to_string());
                        
                        // Discord alert
                        if ctx.discord_alert && !ctx.discord_channel_order.is_empty() && action != "HOLD" {
                            crate::discord_bot::send_to_channel(&ctx.discord_channel_order, &format!(
                                "{} **Position Manager**\n\n📊 {} **{}** #{}\n💰 {} {:.2} lots @ {:.5}\n📈 P&L: **${:.2}**\n\n🎯 Action: **{}**\n📝 {}",
                                emoji, pos.direction, pos.symbol, ticket,
                                pos.direction, pos.volume, pos.open_price,
                                pos.pnl,
                                action, reasoning
                            )).await;
                        }
                        
                        results.push(ManageResult {
                            action: action.clone(),
                            ticket,
                            symbol: pos.symbol.clone(),
                            reasoning,
                            hedge_direction: hedge_dir,
                            hedge_lot,
                        });
                    }
                }
                Err(e) => {
                    warn!("❌ [Position Manager] Failed to parse AI response: {} | Raw: {}", e, clean);
                    let _ = log_tx.send(serde_json::json!({
                        "type": "agent_log", "symbol": ctx.symbol, "agent": "position_manager", "status": "done",
                        "message": format!("AI ตอบรูปแบบผิด — ไม่ดำเนินการ | {}", e)
                    }).to_string());
                }
            }
        }
        Err(e) => {
            warn!("❌ [Position Manager] AI call failed: {}", e);
            let _ = log_tx.send(serde_json::json!({
                "type": "agent_log", "symbol": ctx.symbol, "agent": "position_manager", "status": "done",
                "message": format!("AI ไม่สามารถวิเคราะห์ได้: {}", e)
            }).to_string());
            
            // Fallback: auto-hedge if loss > threshold
            if ctx.hedge_enabled {
                for pos in &ctx.positions {
                    if pos.pnl < -ctx.max_loss_usd {
                        let hedge_dir = if pos.direction == "BUY" { "SELL" } else { "BUY" };
                        info!("🛡️ [Position Manager] Auto-hedge #{} (loss ${:.2} > threshold ${:.2})",
                            pos.ticket, pos.pnl.abs(), ctx.max_loss_usd);
                        
                        results.push(ManageResult {
                            action: "HEDGE".to_string(),
                            ticket: pos.ticket,
                            symbol: pos.symbol.clone(),
                            reasoning: format!("Auto-hedge: ขาดทุน ${:.2} เกินเกณฑ์ ${:.2}", pos.pnl.abs(), ctx.max_loss_usd),
                            hedge_direction: Some(hedge_dir.to_string()),
                            hedge_lot: Some(pos.volume),
                        });
                        
                        if ctx.discord_alert && !ctx.discord_channel_order.is_empty() {
                            crate::discord_bot::send_to_channel(&ctx.discord_channel_order, &format!(
                                "🛡️ **Auto-Hedge (Fallback)**\n\n📊 {} **{}** #{}\n💰 Loss: **${:.2}** > Threshold: ${:.2}\n\n🔄 Hedging with {} {:.2} lots",
                                pos.direction, pos.symbol, pos.ticket,
                                pos.pnl.abs(), ctx.max_loss_usd,
                                hedge_dir, pos.volume
                            )).await;
                        }
                    }
                }
            }
        }
    }
    
    // Final summary
    let actions_summary: Vec<String> = results.iter()
        .filter(|r| r.action != "HOLD")
        .map(|r| format!("#{} {}", r.ticket, r.action))
        .collect();
    
    let summary = if actions_summary.is_empty() {
        "ทุกออเดอร์ปกติ — HOLD ทั้งหมด".to_string()
    } else {
        format!("Actions: {}", actions_summary.join(", "))
    };
    
    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": ctx.symbol, "agent": "position_manager", "status": "done",
        "message": format!("สรุป: {} ออเดอร์ | P&L: ${:.2} | {}", ctx.positions.len(), total_pnl, summary)
    }).to_string());
    
    results
}
