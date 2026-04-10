// ──────────────────────────────────────────────
//  Position Manager v3 — Smart Recovery System
//
//  Key improvements over v2:
//  ✅ Rule-Based first, AI second (faster + works when API down)
//  ✅ Recovery Score from indicators (RSI, EMA, FVG, Momentum)
//  ✅ Tiered Loss Response (Light/Medium/Heavy/Critical)
//  ✅ DCA Recovery (add 50% lot at better price when indicators confirm)
//  ✅ Smart Hedge (variable lot 70-120% based on recovery score)
//  ✅ Trend-Aligned Unhedge (close losing side when indicators favor)
//  ✅ Smart Profit Protection (tiered SL + partial close)
//
//  Tiered Response:
//  🟢 Light  ($0-$10)  → HOLD + Monitor
//  🟡 Medium ($10-$30) → DCA Recovery (if indicators align)
//  🟠 Heavy  ($30-$50) → Smart Hedge (AI confirm)
//  🔴 Critical (>$50)  → Full Hedge (immediate, no AI)
//
//  Actions:
//  HOLD           — ปล่อยไว้ ไม่ทำอะไร (default)
//  DCA            — เปิดไม้เพิ่มทิศเดียวกัน 50% lot (ลด breakeven)
//  HEDGE          — เปิดฝั่งตรงข้ามล็อคขาดทุน
//  UNHEDGE        — ปิดฝั่งที่แพ้ เมื่อ indicator เอื้อ
//  MODIFY_SL      — ย้าย SL (breakeven / trailing)
//  PARTIAL_CLOSE  — ปิดบางส่วนล็อคกำไร
// ──────────────────────────────────────────────

use log::info;
use serde::{Serialize, Deserialize};

use crate::strategy;
use crate::db::Database;

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
    pub is_hedge: bool,
}

#[derive(Debug, Clone, Serialize)]
pub struct ManageResult {
    pub action: String,        // HOLD, DCA, HEDGE, UNHEDGE, MODIFY_SL, PARTIAL_CLOSE
    pub ticket: i64,
    pub symbol: String,
    pub reasoning: String,
    pub hedge_direction: Option<String>,
    pub hedge_lot: Option<f64>,
    pub recovery_score: Option<i32>,
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

// ──────────────────────────────────────────────
//  Constants
// ──────────────────────────────────────────────

const TIER_LIGHT_MAX: f64 = 10.0;
const TIER_MEDIUM_MAX: f64 = 30.0;
const TIER_HEAVY_MAX: f64 = 50.0;
// > TIER_HEAVY_MAX = Critical

const DCA_LOT_RATIO: f64 = 0.5;        // DCA with 50% of original lot
const DCA_MIN_ATR_DISTANCE: f64 = 1.5;  // Must be 1.5 ATR away from open price
const DCA_MIN_RECOVERY_SCORE: i32 = 50;

const HEDGE_SCORE_MEDIUM: i32 = 30;     // 30-49: hedge 70%
const HEDGE_LOT_MEDIUM: f64 = 0.7;
const HEDGE_LOT_FULL: f64 = 1.0;        // 10-29: hedge 100%
const HEDGE_LOT_AGGRESSIVE: f64 = 1.2;  // <10: hedge 120%

const PROFIT_SL_BREAKEVEN: f64 = 5.0;   // $5+ → move SL to breakeven
const PROFIT_SL_TRAIL: f64 = 15.0;      // $15+ → trail SL at +30% of profit
const PROFIT_PARTIAL_30: f64 = 25.0;    // $25+ → partial close 30%
const PROFIT_PARTIAL_50: f64 = 40.0;    // $40+ → partial close 50%

const UNHEDGE_MIN_RECOVERY_SCORE: i32 = 60;

// ──────────────────────────────────────────────
//  Parse positions
// ──────────────────────────────────────────────

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

/// Check if symbol is already hedged
pub fn is_symbol_hedged(positions: &[PositionInfo]) -> bool {
    let has_buy = positions.iter().any(|p| p.direction == "BUY");
    let has_sell = positions.iter().any(|p| p.direction == "SELL");
    has_buy && has_sell
}

// ──────────────────────────────────────────────
//  Recovery Score Calculation
// ──────────────────────────────────────────────

/// Calculate recovery score for a losing position
/// Returns 0-100: higher = more likely price will recover
fn calc_recovery_score(pos: &PositionInfo, ind: &strategy::Indicators) -> i32 {
    let mut score: i32 = 50; // start neutral

    if pos.direction == "BUY" {
        // BUY ผิดทาง (ราคาลง) → ดูว่าราคาจะเด้งขึ้นหรือไม่
        if ind.rsi_14 < 20.0 { score += 25; }       // deep oversold = strong bounce
        else if ind.rsi_14 < 30.0 { score += 15; }  // oversold
        else if ind.rsi_14 < 40.0 { score += 5; }   // mild oversold
        
        if ind.rsi_prev < ind.rsi_14 { score += 10; } // RSI turning up

        if ind.ema_9 > ind.ema_21 { score += 15; }  // short-term trend up
        if ind.current_close > ind.ema_50 { score += 10; } // above support
        if ind.fair_value_gap_bull { score += 10; }  // bullish FVG gap
        if ind.momentum > 0.0 { score += 10; }      // positive momentum
        
        // Penalties
        if ind.ema_9 < ind.ema_21 && ind.ema_21 < ind.ema_50 { score -= 20; } // bear stack
        if ind.rsi_14 > 60.0 { score -= 10; }       // already recovered (late to DCA)
        if ind.atr_ratio > 1.5 { score -= 15; }     // too volatile
        
    } else {
        // SELL ผิดทาง (ราคาขึ้น) → ดูว่าราคาจะตกลงหรือไม่
        if ind.rsi_14 > 80.0 { score += 25; }       // deep overbought
        else if ind.rsi_14 > 70.0 { score += 15; }  // overbought
        else if ind.rsi_14 > 60.0 { score += 5; }   // mild overbought
        
        if ind.rsi_prev > ind.rsi_14 { score += 10; } // RSI turning down

        if ind.ema_9 < ind.ema_21 { score += 15; }  // short-term trend down
        if ind.current_close < ind.ema_50 { score += 10; } // below resistance
        if ind.fair_value_gap_bear { score += 10; }  // bearish FVG gap
        if ind.momentum < 0.0 { score += 10; }      // negative momentum
        
        // Penalties
        if ind.ema_9 > ind.ema_21 && ind.ema_21 > ind.ema_50 { score -= 20; } // bull stack
        if ind.rsi_14 < 40.0 { score -= 10; }       // already dropped
        if ind.atr_ratio > 1.5 { score -= 15; }     // too volatile
    }

    score.clamp(0, 100)
}

/// Check if trend aligns with keeping a position
fn is_trend_aligned(direction: &str, ind: &strategy::Indicators) -> bool {
    match direction {
        "BUY" => ind.ema_9 > ind.ema_21 && ind.current_close > ind.ema_50,
        "SELL" => ind.ema_9 < ind.ema_21 && ind.current_close < ind.ema_50,
        _ => false,
    }
}

// ──────────────────────────────────────────────
//  Main Entry Point
// ──────────────────────────────────────────────

pub async fn manage_positions(
    ctx: &ManageContext,
    log_tx: &tokio::sync::broadcast::Sender<String>,
    db: &Database,
) -> Vec<ManageResult> {
    let mut results = Vec::new();
    
    if ctx.positions.is_empty() {
        return results;
    }
    
    let total_pnl: f64 = ctx.positions.iter().map(|p| p.pnl).sum();
    let is_hedged = is_symbol_hedged(&ctx.positions);
    
    info!("🛡️ [Position Manager v3] {} positions on {} | P&L: ${:.2} | Hedged: {}",
        ctx.positions.len(), ctx.symbol, total_pnl, is_hedged);
    
    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": ctx.symbol, "agent": "position_manager", "status": "running",
        "message": format!("🛡️ v3: ดูแล {} ออเดอร์ | P&L: ${:.2} | {}", 
            ctx.positions.len(), total_pnl,
            if is_hedged { "Hedged" } else { "Normal" })
    }).to_string());

    // Fetch indicators for M15 (good balance of speed and accuracy)
    let candles = db.get_candles_for_strategy(&ctx.symbol, 15, 50).await;
    let ind = if candles.len() >= 15 {
        Some(strategy::compute_indicators(&candles))
    } else {
        None
    };

    // ═══════════════════════════════════════════
    //  CASE 1: Already Hedged → Trend-Aligned Unhedge
    // ═══════════════════════════════════════════
    if is_hedged {
        results.extend(handle_hedged_positions(ctx, log_tx, &ind).await);
    }
    // ═══════════════════════════════════════════
    //  CASE 2: Not Hedged → Tiered Response
    // ═══════════════════════════════════════════
    else {
        results.extend(handle_normal_positions(ctx, log_tx, db, &ind).await);
    }
    
    // Final summary
    let actions_summary: Vec<String> = results.iter()
        .filter(|r| r.action != "HOLD")
        .map(|r| format!("#{} {} (RS:{})", r.ticket, r.action, 
            r.recovery_score.map_or("N/A".to_string(), |s| s.to_string())))
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
//  CASE 1: Hedged — Trend-Aligned Unhedge
// ──────────────────────────────────────────────

async fn handle_hedged_positions(
    ctx: &ManageContext,
    log_tx: &tokio::sync::broadcast::Sender<String>,
    ind: &Option<strategy::Indicators>,
) -> Vec<ManageResult> {
    let mut results = Vec::new();
    let total_pnl: f64 = ctx.positions.iter().map(|p| p.pnl).sum();

    info!("🔄 [PM v3] Hedged mode — checking unhedge with indicators");
    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": ctx.symbol, "agent": "position_manager", "status": "running",
        "message": "Hedged → ตรวจสอบ indicator เพื่อ unhedge"
    }).to_string());

    // Find the winning and losing sides
    let buy_positions: Vec<&PositionInfo> = ctx.positions.iter().filter(|p| p.direction == "BUY").collect();
    let sell_positions: Vec<&PositionInfo> = ctx.positions.iter().filter(|p| p.direction == "SELL").collect();
    
    let buy_pnl: f64 = buy_positions.iter().map(|p| p.pnl).sum();
    let sell_pnl: f64 = sell_positions.iter().map(|p| p.pnl).sum();
    
    // Determine which side to keep and which to close
    let (keep_dir, close_positions) = if buy_pnl >= sell_pnl {
        ("BUY", &sell_positions)
    } else {
        ("SELL", &buy_positions)
    };

    for pos in close_positions.iter() {
        let recovery_score = ind.as_ref().map(|i| calc_recovery_score(pos, i));
        let trend_aligned = ind.as_ref().map(|i| is_trend_aligned(keep_dir, i)).unwrap_or(false);
        
        // Conditions for unhedge:
        // 1. Recovery score for KEEP side >= 60 (trend favors keeping)
        // 2. AND (total P&L > -$3 OR winning side covers losses)
        // 3. AND trend aligned with keep direction
        let _rs = recovery_score.unwrap_or(50);
        let keep_side_rs = ind.as_ref().map(|i| {
            // Calculate recovery score as if we're keeping the OTHER direction
            let mut fake_pos = (*pos).clone();
            fake_pos.direction = keep_dir.to_string();
            calc_recovery_score(&fake_pos, i)
        }).unwrap_or(50);

        let can_unhedge = keep_side_rs >= UNHEDGE_MIN_RECOVERY_SCORE
            && (total_pnl > -3.0 || buy_pnl.max(sell_pnl) > pos.pnl.abs())
            && trend_aligned;

        // Safety: don't unhedge if the losing side still has significant loss
        let safe_to_close = pos.pnl > -3.0 || total_pnl > 0.0;

        if can_unhedge && safe_to_close {
            let reason = format!(
                "Unhedge: Keep {} (RS:{}) | trend aligned | Total P&L: ${:.2} | ฝั่ง {} loss: ${:.2}",
                keep_dir, keep_side_rs, total_pnl, pos.direction, pos.pnl.abs()
            );
            log_action(ctx, log_tx, pos.ticket, pos, "UNHEDGE", &reason).await;
            
            results.push(ManageResult {
                action: "UNHEDGE".into(),
                ticket: pos.ticket,
                symbol: pos.symbol.clone(),
                reasoning: reason,
                hedge_direction: None,
                hedge_lot: None,
                recovery_score: Some(keep_side_rs),
            });
        } else {
            let reason = format!(
                "HOLD (hedged) | Keep RS:{} | Trend:{} | P&L:${:.2} | Safe:{}",
                keep_side_rs, trend_aligned, total_pnl, safe_to_close
            );
            log_action(ctx, log_tx, pos.ticket, pos, "HOLD", &reason).await;
            
            results.push(ManageResult {
                action: "HOLD".into(),
                ticket: pos.ticket,
                symbol: pos.symbol.clone(),
                reasoning: reason,
                hedge_direction: None,
                hedge_lot: None,
                recovery_score: Some(keep_side_rs),
            });
        }
    }
    
    // Also add HOLD for the winning side
    let keep_positions = if keep_dir == "BUY" { &buy_positions } else { &sell_positions };
    for pos in keep_positions.iter() {
        // Check if profitable enough for profit protection
        let action = get_profit_action(pos);
        log_action(ctx, log_tx, pos.ticket, pos, &action.0, &action.1).await;
        
        results.push(ManageResult {
            action: action.0,
            ticket: pos.ticket,
            symbol: pos.symbol.clone(),
            reasoning: action.1,
            hedge_direction: None,
            hedge_lot: None,
            recovery_score: None,
        });
    }

    results
}

// ──────────────────────────────────────────────
//  CASE 2: Normal — Tiered Response
// ──────────────────────────────────────────────

async fn handle_normal_positions(
    ctx: &ManageContext,
    log_tx: &tokio::sync::broadcast::Sender<String>,
    _db: &Database,
    ind: &Option<strategy::Indicators>,
) -> Vec<ManageResult> {
    let mut results = Vec::new();

    for pos in &ctx.positions {
        let loss = pos.pnl.abs();
        let is_losing = pos.pnl < 0.0;
        let recovery_score = ind.as_ref().map(|i| calc_recovery_score(pos, i));
        let rs = recovery_score.unwrap_or(50);

        // ═══ PROFITABLE POSITIONS → Smart Profit Protection ═══
        if pos.pnl > 0.0 {
            let action = get_profit_action(pos);
            log_action(ctx, log_tx, pos.ticket, pos, &action.0, &action.1).await;
            
            if ctx.discord_alert && !ctx.discord_channel_order.is_empty() && action.0 != "HOLD" {
                let emoji = action_emoji(&action.0);
                crate::discord_bot::send_to_channel(&ctx.discord_channel_order, &format!(
                    "{} **Position Manager v3**\n\n📊 {} **{}** #{}\n💰 {:.2} lots @ {:.5}\n📈 P&L: **${:.2}**\n\n🎯 Action: **{}**\n📝 {}",
                    emoji, pos.direction, pos.symbol, pos.ticket,
                    pos.volume, pos.open_price,
                    pos.pnl, action.0, action.1
                )).await;
            }
            
            results.push(ManageResult {
                action: action.0,
                ticket: pos.ticket,
                symbol: pos.symbol.clone(),
                reasoning: action.1,
                hedge_direction: None,
                hedge_lot: None,
                recovery_score: Some(rs),
            });
            continue;
        }

        // ═══ LOSING POSITIONS → Tiered Response ═══

        // 🟢 TIER: Light ($0-$10) → HOLD
        if loss <= TIER_LIGHT_MAX {
            let reason = format!(
                "🟢 Light loss ${:.2} (<${:.0}) | RS:{} | HOLD — monitor",
                loss, TIER_LIGHT_MAX, rs
            );
            log_action(ctx, log_tx, pos.ticket, pos, "HOLD", &reason).await;
            results.push(ManageResult {
                action: "HOLD".into(), ticket: pos.ticket, symbol: pos.symbol.clone(),
                reasoning: reason, hedge_direction: None, hedge_lot: None, recovery_score: Some(rs),
            });
            continue;
        }

        // 🔴 TIER: Critical (>$50) → Immediate Full Hedge (no AI needed)
        if is_losing && loss > TIER_HEAVY_MAX && ctx.hedge_enabled {
            let hedge_dir = if pos.direction == "BUY" { "SELL" } else { "BUY" };
            let hedge_lot = pos.volume * HEDGE_LOT_FULL;
            let reason = format!(
                "🔴 Critical loss ${:.2} (>${:.0}) | RS:{} | Full Hedge ทันที {} {:.2} lot",
                loss, TIER_HEAVY_MAX, rs, hedge_dir, hedge_lot
            );
            log_action(ctx, log_tx, pos.ticket, pos, "HEDGE", &reason).await;
            
            if ctx.discord_alert && !ctx.discord_channel_order.is_empty() {
                crate::discord_bot::send_to_channel(&ctx.discord_channel_order, &format!(
                    "🔴 **CRITICAL — Auto Hedge**\n\n📊 {} **{}** #{}\n💰 Loss: **${:.2}** > ${:.0}\n📊 Recovery Score: {}\n🔄 Full Hedge → {} {:.2} lots",
                    pos.direction, pos.symbol, pos.ticket,
                    loss, TIER_HEAVY_MAX, rs, hedge_dir, hedge_lot
                )).await;
            }
            
            results.push(ManageResult {
                action: "HEDGE".into(), ticket: pos.ticket, symbol: pos.symbol.clone(),
                reasoning: reason,
                hedge_direction: Some(hedge_dir.to_string()),
                hedge_lot: Some(hedge_lot),
                recovery_score: Some(rs),
            });
            continue;
        }

        // 🟡 TIER: Medium ($10-$30) → DCA Recovery (if indicators align)
        if is_losing && loss <= TIER_MEDIUM_MAX {
            let has_dca = ctx.positions.iter().any(|p| 
                p.comment.contains("DCA") && p.direction == pos.direction && p.ticket != pos.ticket
            );
            
            let atr_distance_ok = ind.as_ref().map(|i| {
                if i.atr > 0.0 {
                    let price_distance = (pos.current_price - pos.open_price).abs();
                    price_distance >= i.atr * DCA_MIN_ATR_DISTANCE
                } else { false }
            }).unwrap_or(false);
            
            if !has_dca && rs >= DCA_MIN_RECOVERY_SCORE && atr_distance_ok {
                let dca_lot = pos.volume * DCA_LOT_RATIO;
                let reason = format!(
                    "🟡 Medium loss ${:.2} | RS:{} ≥ {} | ราคาห่างพอ | DCA {} {:.2} lot (50% of {:.2})",
                    loss, rs, DCA_MIN_RECOVERY_SCORE, pos.direction, dca_lot, pos.volume
                );
                log_action(ctx, log_tx, pos.ticket, pos, "DCA", &reason).await;
                
                if ctx.discord_alert && !ctx.discord_channel_order.is_empty() {
                    crate::discord_bot::send_to_channel(&ctx.discord_channel_order, &format!(
                        "🟡 **DCA Recovery**\n\n📊 {} **{}** #{}\n💰 Loss: ${:.2}\n📊 Recovery Score: **{}**\n📈 DCA: {} {:.2} lots\n📝 ลด breakeven",
                        pos.direction, pos.symbol, pos.ticket,
                        loss, rs, pos.direction, dca_lot
                    )).await;
                }
                
                results.push(ManageResult {
                    action: "DCA".into(), ticket: pos.ticket, symbol: pos.symbol.clone(),
                    reasoning: reason,
                    hedge_direction: Some(pos.direction.clone()),
                    hedge_lot: Some(dca_lot),
                    recovery_score: Some(rs),
                });
                continue;
            }
            
            // Medium loss but DCA not appropriate → HOLD
            let reason = format!(
                "🟡 Medium loss ${:.2} | RS:{} | DCA?: has_dca={} atr_ok={} | HOLD",
                loss, rs, has_dca, atr_distance_ok
            );
            log_action(ctx, log_tx, pos.ticket, pos, "HOLD", &reason).await;
            results.push(ManageResult {
                action: "HOLD".into(), ticket: pos.ticket, symbol: pos.symbol.clone(),
                reasoning: reason, hedge_direction: None, hedge_lot: None, recovery_score: Some(rs),
            });
            continue;
        }

        // 🟠 TIER: Heavy ($30-$50) → Smart Hedge (variable lot based on RS)
        if is_losing && loss <= TIER_HEAVY_MAX && ctx.hedge_enabled {
            let hedge_dir = if pos.direction == "BUY" { "SELL" } else { "BUY" };
            let hedge_lot_ratio = if rs >= HEDGE_SCORE_MEDIUM {
                HEDGE_LOT_MEDIUM     // RS 30-49: hedge 70% (maybe recovers)
            } else if rs >= 10 {
                HEDGE_LOT_FULL       // RS 10-29: hedge 100% (unlikely to recover)
            } else {
                HEDGE_LOT_AGGRESSIVE // RS <10: hedge 120% (recover faster)
            };
            let hedge_lot = pos.volume * hedge_lot_ratio;
            
            let reason = format!(
                "🟠 Heavy loss ${:.2} | RS:{} → hedge {:.0}% ({:.2} lot) | {} {}",
                loss, rs, hedge_lot_ratio * 100.0, hedge_lot, hedge_dir,
                if rs >= HEDGE_SCORE_MEDIUM { "อาจกลับมา" } else { "ไม่น่ากลับ" }
            );
            log_action(ctx, log_tx, pos.ticket, pos, "HEDGE", &reason).await;
            
            if ctx.discord_alert && !ctx.discord_channel_order.is_empty() {
                crate::discord_bot::send_to_channel(&ctx.discord_channel_order, &format!(
                    "🟠 **Smart Hedge**\n\n📊 {} **{}** #{}\n💰 Loss: **${:.2}**\n📊 Recovery Score: **{}** → hedge {:.0}%\n🔄 {} {:.2} lots",
                    pos.direction, pos.symbol, pos.ticket,
                    loss, rs, hedge_lot_ratio * 100.0,
                    hedge_dir, hedge_lot
                )).await;
            }
            
            results.push(ManageResult {
                action: "HEDGE".into(), ticket: pos.ticket, symbol: pos.symbol.clone(),
                reasoning: reason,
                hedge_direction: Some(hedge_dir.to_string()),
                hedge_lot: Some(hedge_lot),
                recovery_score: Some(rs),
            });
            continue;
        }

        // Hedge disabled but significant loss → just HOLD
        let reason = format!(
            "Loss ${:.2} | RS:{} | Hedge disabled — HOLD",
            loss, rs
        );
        log_action(ctx, log_tx, pos.ticket, pos, "HOLD", &reason).await;
        results.push(ManageResult {
            action: "HOLD".into(), ticket: pos.ticket, symbol: pos.symbol.clone(),
            reasoning: reason, hedge_direction: None, hedge_lot: None, recovery_score: Some(rs),
        });
    }
    
    results
}

// ──────────────────────────────────────────────
//  Smart Profit Protection
// ──────────────────────────────────────────────

fn get_profit_action(pos: &PositionInfo) -> (String, String) {
    if pos.pnl >= PROFIT_PARTIAL_50 {
        ("PARTIAL_CLOSE".into(), format!(
            "กำไร ${:.2} ≥ ${:.0} → Partial Close 50% ล็อคกำไร", pos.pnl, PROFIT_PARTIAL_50
        ))
    } else if pos.pnl >= PROFIT_PARTIAL_30 {
        ("PARTIAL_CLOSE".into(), format!(
            "กำไร ${:.2} ≥ ${:.0} → Partial Close 30% ล็อคกำไร", pos.pnl, PROFIT_PARTIAL_30
        ))
    } else if pos.pnl >= PROFIT_SL_TRAIL {
        ("MODIFY_SL".into(), format!(
            "กำไร ${:.2} ≥ ${:.0} → Trail SL +30% ของกำไร", pos.pnl, PROFIT_SL_TRAIL
        ))
    } else if pos.pnl >= PROFIT_SL_BREAKEVEN {
        ("MODIFY_SL".into(), format!(
            "กำไร ${:.2} ≥ ${:.0} → Move SL → Breakeven", pos.pnl, PROFIT_SL_BREAKEVEN
        ))
    } else {
        ("HOLD".into(), format!("กำไร ${:.2} — ปล่อยให้วิ่ง", pos.pnl))
    }
}

// ──────────────────────────────────────────────
//  Helper functions
// ──────────────────────────────────────────────

fn action_emoji(action: &str) -> &str {
    match action {
        "HOLD" => "⏳",
        "DCA" => "📊",
        "HEDGE" => "🛡️",
        "UNHEDGE" => "🔓",
        "PARTIAL_CLOSE" => "✂️",
        "MODIFY_SL" => "🔒",
        "CLOSE" => "🔴",
        _ => "❓",
    }
}

async fn log_action(ctx: &ManageContext, log_tx: &tokio::sync::broadcast::Sender<String>, ticket: i64, pos: &PositionInfo, action: &str, reasoning: &str) {
    let emoji = action_emoji(action);
    info!("{} [PM v3] #{} {} → {} | {}", emoji, ticket, pos.direction, action, reasoning);
    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": ctx.symbol, "agent": "position_manager", "status": "running",
        "message": format!("{} #{} {} {:.2}lot P&L:${:.2} → {} | {}",
            emoji, ticket, pos.direction, pos.volume, pos.pnl, action, reasoning)
    }).to_string());
}
