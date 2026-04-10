// ──────────────────────────────────────────────
//  Position Manager v2 — AI Portfolio Guardian
//  
//  Design Philosophy:
//  ❌ ห้ามปิดออเดอร์ที่ขาดทุน (ไม่ CLOSE)
//  ✅ แก้ไม้ด้วย HEDGE (เปิดฝั่งตรงข้าม)
//  ✅ รอราคากลับ → ปิดฝั่งที่แพ้ (Unhedge)
//  ✅ MODIFY_SL เมื่อกำไรดี → ล็อคกำไร
//
//  Actions:
//  HOLD           — ปล่อยไว้ ไม่ทำอะไร (default)
//  HEDGE          — เปิดฝั่งตรงข้ามล็อคขาดทุน
//  UNHEDGE        — ปิดฝั่งที่แพ้ เมื่อราคากลับมา
//  MODIFY_SL      — ย้าย SL เข้า breakeven/trailing
//  PARTIAL_CLOSE  — ปิด 50% เมื่อกำไรดีมาก
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
    pub is_hedge: bool,      // true if this is a hedge position
}

#[derive(Debug, Clone, Serialize)]
pub struct ManageResult {
    pub action: String,        // HOLD, HEDGE, UNHEDGE, MODIFY_SL, PARTIAL_CLOSE
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
        
        // Check if this is a hedge position by comment
        let comment = p["comment"].as_str().unwrap_or("").to_string();
        let is_hedge = comment.contains("HEDGE") || comment.contains("hedge");
        
        Some(PositionInfo {
            ticket: p["ticket"].as_i64().unwrap_or(0),
            symbol: sym.to_string(),
            direction: direction.to_string(),
            volume: p["volume"].as_f64().unwrap_or(0.0),
            open_price: p["open_price"].as_f64().unwrap_or(p["price_open"].as_f64().unwrap_or(0.0)),
            current_price: p["current_price"].as_f64().unwrap_or(p["price_current"].as_f64().unwrap_or(0.0)),
            pnl: p["pnl"].as_f64().unwrap_or(p["profit"].as_f64().unwrap_or(0.0)),
            swap: p["swap"].as_f64().unwrap_or(0.0),
            comment,
            is_hedge,
        })
    }).collect()
}

/// Check if symbol is already hedged (has both BUY and SELL)
pub fn is_symbol_hedged(positions: &[PositionInfo]) -> bool {
    let has_buy = positions.iter().any(|p| p.direction == "BUY");
    let has_sell = positions.iter().any(|p| p.direction == "SELL");
    has_buy && has_sell
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
    let is_hedged = is_symbol_hedged(&ctx.positions);
    let original_positions: Vec<&PositionInfo> = ctx.positions.iter().filter(|p| !p.is_hedge).collect();
    let hedge_positions: Vec<&PositionInfo> = ctx.positions.iter().filter(|p| p.is_hedge).collect();
    
    info!("🛡️ [Position Manager v2] {} positions on {} | P&L: ${:.2} | Hedged: {} | Threshold: ${:.2}",
        ctx.positions.len(), ctx.symbol, total_pnl, is_hedged, ctx.max_loss_usd);
    
    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": ctx.symbol, "agent": "position_manager", "status": "running",
        "message": format!("ดูแล {} ออเดอร์ | P&L: ${:.2} | {}", 
            ctx.positions.len(), total_pnl,
            if is_hedged { "Hedged" } else { "Normal" })
    }).to_string());
    
    // ═══════════════════════════════════════════
    //  CASE 1: Already Hedged — Check if can unhedge
    // ═══════════════════════════════════════════
    if is_hedged {
        info!("🔄 [Position Manager v2] Symbol is hedged — checking if can unhedge");
        
        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": ctx.symbol, "agent": "position_manager", "status": "running",
            "message": "สถานะ: Hedged — กำลังตรวจสอบว่าปิดฝั่งแพ้ได้หรือไม่"
        }).to_string());
        
        // Build position summary for AI
        let pos_summary = build_position_summary(&ctx.positions);
        
        let prompt = format!(
r#"You are a CONSERVATIVE AI portfolio manager. This symbol is currently HEDGED (has both BUY and SELL positions).

## Hedged Positions on {symbol}
{positions}

## Portfolio: Balance ${balance:.2} | Equity ${equity:.2} | Total P&L: ${total_pnl:.2}

## YOUR ONLY JOB: Decide if it's safe to UNHEDGE (close the losing side)

Rules:
1. DEFAULT = HOLD — ถ้าไม่แน่ใจ ให้ HOLD ทั้งหมด
2. UNHEDGE (ปิดฝั่งที่แพ้) เฉพาะเมื่อ:
   - ราคากลับมาใกล้จุดเปิดของฝั่งที่แพ้ (loss < $3)
   - หรือ ฝั่งที่ชนะกำไรพอชดเชยฝั่งที่แพ้ (net P&L > 0)
   - หรือ Total P&L ของทั้ง 2 ฝั่ง > $0
3. ห้าม CLOSE ออเดอร์ที่กำลังชนะ
4. ห้ามเปิดออเดอร์ใหม่ — ใช้ HOLD หรือ UNHEDGE เท่านั้น

For UNHEDGE: specify the ticket of the LOSING position to close.

Respond JSON array:
[{{"ticket": 12345, "action": "HOLD", "reasoning": "เหตุผลภาษาไทย"}}]"#,
            symbol = ctx.symbol,
            positions = pos_summary,
            balance = ctx.balance,
            equity = ctx.equity,
            total_pnl = total_pnl,
        );
        
        match call_ai_safe(&ctx.gemini_key, &ctx.gemini_model, &prompt).await {
            Ok(decisions) => {
                for (ticket, action, reasoning, pos) in parse_decisions(&decisions, &ctx.positions) {
                    let mut final_action = action.clone();
                    let mut final_reason = reasoning.clone();
                    
                    // Safety: Only allow UNHEDGE on losing hedge positions
                    if final_action == "UNHEDGE" || final_action == "CLOSE" {
                        // Only allow closing if this is a hedge position OR if net P&L > 0
                        if total_pnl < -3.0 && !pos.is_hedge {
                            final_action = "HOLD".to_string();
                            final_reason = format!("(Safety) Total P&L ${:.2} ยังติดลบ — รอให้กลับก่อน", total_pnl);
                        } else if pos.pnl < -3.0 {
                            final_action = "HOLD".to_string();
                            final_reason = format!("(Safety) ฝั่งนี้ยังขาดทุน ${:.2} — รอให้ loss < $3", pos.pnl.abs());
                        }
                    }
                    
                    log_action(&ctx, log_tx, ticket, &pos, &final_action, &final_reason).await;
                    
                    results.push(ManageResult {
                        action: final_action,
                        ticket,
                        symbol: pos.symbol.clone(),
                        reasoning: final_reason,
                        hedge_direction: None,
                        hedge_lot: None,
                    });
                }
            }
            Err(e) => {
                // AI failed — just HOLD everything when hedged
                warn!("❌ [Position Manager v2] AI failed in hedged mode: {}", e);
                let _ = log_tx.send(serde_json::json!({
                    "type": "agent_log", "symbol": ctx.symbol, "agent": "position_manager", "status": "running",
                    "message": format!("AI ไม่ตอบ — HOLD ทั้งหมด (hedged safe)")
                }).to_string());
            }
        }
    }
    // ═══════════════════════════════════════════
    //  CASE 2: Not Hedged — Normal monitoring
    // ═══════════════════════════════════════════
    else {
        let pos_summary = build_position_summary(&ctx.positions);
        
        let prompt = format!(
r#"You are a CONSERVATIVE AI portfolio manager. Your job is to PROTECT positions. ห้ามปิดออเดอร์ที่ขาดทุน

## Open Positions on {symbol}
{positions}

## Portfolio: Balance ${balance:.2} | Equity ${equity:.2} | Total P&L: ${total_pnl:.2}
## Max Loss for Hedge: ${max_loss:.2} | Hedge Enabled: {hedge_enabled}

## RULES (ห้ามละเมิด)
1. **DEFAULT = HOLD** — 90% ของเวลาต้อง HOLD
2. **ห้าม CLOSE ออเดอร์ที่ขาดทุน** — ห้ามเด็ดขาด ไม่ว่าจะขาดทุนเท่าไร
3. **ห้าม CLOSE ออเดอร์ที่กำไรน้อยกว่า $10** — ปล่อยให้กำไรวิ่ง
4. HEDGE เฉพาะเมื่อ: ขาดทุนออเดอร์ > ${max_loss:.2} AND hedge = true
5. MODIFY_SL เมื่อ: กำไร > $10 → ย้าย SL เข้า breakeven
6. PARTIAL_CLOSE เมื่อ: กำไร > $20 → ปิด 50% ล็อคกำไร

## Actions
- **HOLD**: ปล่อยไว้ (ใช้เกือบทุกกรณี)
- **HEDGE**: เปิดฝั่งตรงข้ามล็อคขาดทุน (เฉพาะขาดทุนเกิน threshold)
- **MODIFY_SL**: ย้าย SL (เฉพาะกำไรดี)
- **PARTIAL_CLOSE**: ปิดบางส่วน (เฉพาะกำไรดีมาก)

Respond JSON array:
[{{"ticket": 12345, "action": "HOLD", "reasoning": "เหตุผลภาษาไทย"}}]"#,
            symbol = ctx.symbol,
            positions = pos_summary,
            balance = ctx.balance,
            equity = ctx.equity,
            total_pnl = total_pnl,
            max_loss = ctx.max_loss_usd,
            hedge_enabled = ctx.hedge_enabled,
        );
        
        match call_ai_safe(&ctx.gemini_key, &ctx.gemini_model, &prompt).await {
            Ok(decisions) => {
                for (ticket, action, reasoning, pos) in parse_decisions(&decisions, &ctx.positions) {
                    let mut final_action = action.clone();
                    let mut final_reason = reasoning.clone();
                    
                    // ═══════════════════════════════════════
                    //  SAFETY GUARDS — ป้องกัน AI ทำผิด
                    // ═══════════════════════════════════════
                    
                    // ABSOLUTE BLOCK: ห้าม CLOSE ทุกกรณี (ใช้ HEDGE แทน)
                    if final_action == "CLOSE" {
                        if pos.pnl < 0.0 {
                            // ขาดทุน → ห้ามปิด
                            final_action = "HOLD".to_string();
                            final_reason = format!("(Safety) ห้ามปิดออเดอร์ขาดทุน ${:.2} — HOLD", pos.pnl.abs());
                        } else if pos.pnl < 10.0 {
                            // กำไรน้อย → ปล่อยวิ่ง
                            final_action = "HOLD".to_string();
                            final_reason = format!("(Safety) กำไร ${:.2} ยังน้อย — ปล่อยให้วิ่ง", pos.pnl);
                        }
                        // กำไร >= $10 → OK ให้ปิดได้ (but convert to PARTIAL_CLOSE)
                        if final_action == "CLOSE" && pos.pnl >= 10.0 {
                            final_action = "PARTIAL_CLOSE".to_string();
                            final_reason = format!("กำไร ${:.2} — ปิดบางส่วนล็อคกำไร", pos.pnl);
                        }
                    }
                    
                    // HEDGE guards
                    if final_action == "HEDGE" {
                        if !ctx.hedge_enabled {
                            final_action = "HOLD".to_string();
                            final_reason = "Hedge ปิดใช้งาน — HOLD".to_string();
                        } else if pos.pnl >= 0.0 {
                            final_action = "HOLD".to_string();
                            final_reason = "ออเดอร์กำไรอยู่ — ไม่ต้อง Hedge".to_string();
                        } else if pos.pnl.abs() < ctx.max_loss_usd {
                            final_action = "HOLD".to_string();
                            final_reason = format!("ขาดทุน ${:.2} ยังไม่ถึงเกณฑ์ ${:.2}", pos.pnl.abs(), ctx.max_loss_usd);
                        }
                    }
                    
                    // PARTIAL_CLOSE guards
                    if final_action == "PARTIAL_CLOSE" && pos.pnl < 10.0 {
                        final_action = "HOLD".to_string();
                        final_reason = format!("กำไร ${:.2} ยังไม่พอ partial close ($10+)", pos.pnl);
                    }
                    
                    // MODIFY_SL guards
                    if final_action == "MODIFY_SL" && pos.pnl < 5.0 {
                        final_action = "HOLD".to_string();
                        final_reason = format!("กำไร ${:.2} ยังไม่พอย้าย SL ($5+)", pos.pnl);
                    }
                    
                    // Build hedge details if needed
                    let (hedge_dir, hedge_lot) = if final_action == "HEDGE" {
                        let dir = if pos.direction == "BUY" { "SELL" } else { "BUY" };
                        (Some(dir.to_string()), Some(pos.volume))
                    } else {
                        (None, None)
                    };
                    
                    log_action(&ctx, log_tx, ticket, &pos, &final_action, &final_reason).await;
                    
                    // Discord notification for non-HOLD actions
                    if ctx.discord_alert && !ctx.discord_channel_order.is_empty() && final_action != "HOLD" {
                        let emoji = action_emoji(&final_action);
                        crate::discord_bot::send_to_channel(&ctx.discord_channel_order, &format!(
                            "{} **Position Manager**\n\n📊 {} **{}** #{}\n💰 {:.2} lots @ {:.5}\n📈 P&L: **${:.2}**\n\n🎯 Action: **{}**\n📝 {}",
                            emoji, pos.direction, pos.symbol, ticket,
                            pos.volume, pos.open_price,
                            pos.pnl, final_action, final_reason
                        )).await;
                    }
                    
                    results.push(ManageResult {
                        action: final_action,
                        ticket,
                        symbol: pos.symbol.clone(),
                        reasoning: final_reason,
                        hedge_direction: hedge_dir,
                        hedge_lot,
                    });
                }
            }
            Err(e) => {
                warn!("❌ [Position Manager v2] AI failed: {}", e);
                let _ = log_tx.send(serde_json::json!({
                    "type": "agent_log", "symbol": ctx.symbol, "agent": "position_manager", "status": "running",
                    "message": format!("AI ไม่ตอบ — HOLD ทั้งหมด")
                }).to_string());
                
                // Fallback: auto-hedge only if loss > threshold
                if ctx.hedge_enabled {
                    for pos in &ctx.positions {
                        if pos.pnl < -ctx.max_loss_usd && !pos.is_hedge {
                            let hedge_dir = if pos.direction == "BUY" { "SELL" } else { "BUY" };
                            info!("🛡️ [Fallback] Auto-hedge #{} loss ${:.2} > ${:.2}", pos.ticket, pos.pnl.abs(), ctx.max_loss_usd);
                            
                            results.push(ManageResult {
                                action: "HEDGE".to_string(),
                                ticket: pos.ticket,
                                symbol: pos.symbol.clone(),
                                reasoning: format!("(Fallback) ขาดทุน ${:.2} เกินเกณฑ์ — auto hedge", pos.pnl.abs()),
                                hedge_direction: Some(hedge_dir.to_string()),
                                hedge_lot: Some(pos.volume),
                            });
                            
                            if ctx.discord_alert && !ctx.discord_channel_order.is_empty() {
                                crate::discord_bot::send_to_channel(&ctx.discord_channel_order, &format!(
                                    "🛡️ **Auto-Hedge (Fallback)**\n\n📊 {} **{}** #{}\n💰 Loss: **${:.2}** > ${:.2}\n🔄 Hedging {} {:.2} lots",
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
    }
    
    // Final summary
    let actions_summary: Vec<String> = results.iter()
        .filter(|r| r.action != "HOLD")
        .map(|r| format!("#{} {}", r.ticket, r.action))
        .collect();
    
    let summary = if actions_summary.is_empty() {
        "HOLD ทั้งหมด — ปกติดี".to_string()
    } else {
        format!("Actions: {}", actions_summary.join(", "))
    };
    
    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": ctx.symbol, "agent": "position_manager", "status": "done",
        "message": format!("สรุป: {} ออเดอร์ | P&L: ${:.2} | {}", ctx.positions.len(), total_pnl, summary)
    }).to_string());
    
    results
}

// ──────────────────────────────────────────────
//  Helper functions
// ──────────────────────────────────────────────

fn build_position_summary(positions: &[PositionInfo]) -> String {
    let mut s = String::new();
    for (i, p) in positions.iter().enumerate() {
        let tag = if p.is_hedge { " [HEDGE]" } else { "" };
        s.push_str(&format!(
            "#{} Ticket:{} {} {:.2} lots @ {:.5} → {:.5} | P&L: ${:.2} | Swap: ${:.2}{}\n",
            i+1, p.ticket, p.direction, p.volume, p.open_price, p.current_price,
            p.pnl, p.swap, tag
        ));
    }
    s
}

fn action_emoji(action: &str) -> &str {
    match action {
        "HOLD" => "⏳",
        "HEDGE" => "🛡️",
        "UNHEDGE" => "🔓",
        "PARTIAL_CLOSE" => "📊",
        "MODIFY_SL" => "🔒",
        "CLOSE" => "🔴",
        _ => "❓",
    }
}

async fn call_ai_safe(key: &str, model: &str, prompt: &str) -> Result<Vec<serde_json::Value>, String> {
    let response = crate::ai_engine::call_ai_pub(key, model, prompt, 0.2, 2048, true).await?;
    let clean = response.trim().trim_start_matches("```json").trim_start_matches("```").trim_end_matches("```").trim();
    serde_json::from_str::<Vec<serde_json::Value>>(clean)
        .map_err(|e| format!("JSON parse error: {} | Raw: {}", e, &clean[..clean.len().min(200)]))
}

fn parse_decisions<'a>(decisions: &[serde_json::Value], positions: &'a [PositionInfo]) -> Vec<(i64, String, String, &'a PositionInfo)> {
    decisions.iter().filter_map(|d| {
        let ticket = d["ticket"].as_i64().unwrap_or(0);
        let action = d["action"].as_str().unwrap_or("HOLD").to_uppercase();
        let reasoning = d["reasoning"].as_str().unwrap_or("").to_string();
        let pos = positions.iter().find(|p| p.ticket == ticket)?;
        Some((ticket, action, reasoning, pos))
    }).collect()
}

async fn log_action(ctx: &ManageContext, log_tx: &tokio::sync::broadcast::Sender<String>, ticket: i64, pos: &PositionInfo, action: &str, reasoning: &str) {
    let emoji = action_emoji(action);
    info!("{} [Position Manager v2] #{} {} → {} | {}", emoji, ticket, pos.direction, action, reasoning);
    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": ctx.symbol, "agent": "position_manager", "status": "running",
        "message": format!("{} #{} {} {:.2}lot P&L:${:.2} → {} | {}",
            emoji, ticket, pos.direction, pos.volume, pos.pnl, action, reasoning)
    }).to_string());
}
