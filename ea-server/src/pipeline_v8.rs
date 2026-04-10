// ──────────────────────────────────────────────
//  Pipeline v8: Server-First Strategy Scanner
//  3-Stage Decision Engine:
//    1. Server Scan: 10 Strategies × 5 TF (M5/M15/M30/H1/H4) → Best Signal
//    2. Gemma 4 Cloud: Validate + History Check → APPROVE/REJECT
//    3. Gemini Cloud: Final Confirm + News/Calendar → APPROVE/REJECT → Execute
// ──────────────────────────────────────────────

use log::{info, warn};
use tokio::sync::broadcast;

use crate::db::Database;
use crate::ai_engine;
use crate::strategy;

// ──────────────────────────────────────────────
//  Types
// ──────────────────────────────────────────────

#[derive(Clone)]
pub struct PipelineV8Context {
    pub symbol: String,
    pub balance: f64,
    pub equity: f64,
    pub open_positions: usize,
    pub positions_detail: Vec<serde_json::Value>,
    pub gemini_key: String,
    pub gemini_model: String,
    pub job_config: serde_json::Value,
    pub discord_alert: bool,
    pub discord_channel_order: String,
    pub global_news: Option<ai_engine::NewsResult>,
    pub global_calendar: Option<ai_engine::CalendarResult>,
}

/// TF confluence data
#[derive(Debug, Clone, serde::Serialize)]
pub struct TfConfluence {
    pub agree_count: usize,
    pub total_tfs: usize,
    pub details: Vec<TfDetail>,
}

#[derive(Debug, Clone, serde::Serialize)]
pub struct TfDetail {
    pub timeframe: String,
    pub direction: String,
    pub confidence: f64,
    pub strategy: String,
}

/// The best signal selected by server scan
#[derive(Debug, Clone, serde::Serialize)]
pub struct BestSignal {
    pub strategy_name: String,
    pub direction: String,
    pub confidence: f64,
    pub reason: String,
    pub best_timeframe: String,
    pub score: f64,
    pub tf_confluence: TfConfluence,
    pub indicator_summary: String,
    pub selection_reasoning: String,
}

/// Server scan result
#[derive(Debug, Clone, serde::Serialize)]
pub struct ServerScanResult {
    pub strategies_scanned: usize,
    pub timeframes_scanned: usize,
    pub total_signals: usize,
    pub buy_signals: usize,
    pub sell_signals: usize,
    pub best_signal: Option<BestSignal>,
    pub all_signals: Vec<String>,
    pub scan_time_ms: u128,
}

/// Final pipeline result
#[derive(Debug, Clone, serde::Serialize)]
pub struct PipelineV8Result {
    pub decision: String,
    pub confidence: f64,
    pub lot_size: f64,
    pub strategy_name: String,
    pub timeframe: String,
    pub reasoning: String,
    pub server_scan: ServerScanResult,
    pub gemma_verdict: String,
    pub gemini_verdict: String,
}

/// History context for AI
#[derive(Debug, Clone, serde::Serialize)]
pub struct HistoryData {
    pub symbol_win_rate: f64,
    pub symbol_total_trades: i64,
    pub strategy_win_rate: f64,
    pub strategy_total_trades: i64,
    pub session_name: String,
    pub session_win_rate: f64,
    pub recent_streak: i32,
    pub recent_decisions: Vec<serde_json::Value>,
    pub avg_pnl: f64,
}

// ──────────────────────────────────────────────
//  Constants
// ──────────────────────────────────────────────

const TIMEFRAMES: &[(&str, i64, i64)] = &[
    ("M5",  5,   50),
    ("M15", 15,  50),
    ("M30", 30,  50),
    ("H1",  60,  50),
    ("H4",  240, 30),
];

const MIN_CONFIDENCE: f64 = 65.0;
const MIN_CANDLES: usize = 20;

// ──────────────────────────────────────────────
//  Main Entry Point
// ──────────────────────────────────────────────

pub async fn run_pipeline_v8(
    ctx: &PipelineV8Context,
    db: &Database,
    log_tx: &broadcast::Sender<String>,
) -> PipelineV8Result {
    let sym = &ctx.symbol;

    info!("🔥 [Pipeline v8] Scanning {}...", sym);
    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": sym, "agent": "pipeline_v8", "status": "running",
        "message": format!("🔥 Pipeline v8: เริ่ม scan {} — 10 กลยุทธ์ × 5 TF...", sym)
    }).to_string());

    // ═══════════════════════════════════════════════
    //  Stage 1: Server Strategy Scan
    // ═══════════════════════════════════════════════

    let scan = server_strategy_scan(sym, db, log_tx).await;

    let _ = log_tx.send(serde_json::json!({
        "type": "pipeline_v8_scan", "symbol": sym, "scan": &scan
    }).to_string());

    let best = match &scan.best_signal {
        Some(s) => s.clone(),
        None => {
            let msg = format!("⏸️ Scan {}: BUY:{} SELL:{} — ไม่มีสัญญาณผ่าน {:.0}%",
                sym, scan.buy_signals, scan.sell_signals, MIN_CONFIDENCE);
            let _ = log_tx.send(serde_json::json!({
                "type": "agent_log", "symbol": sym, "agent": "pipeline_v8", "status": "done",
                "message": &msg
            }).to_string());
            return build_hold_result(scan, &msg);
        }
    };

    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": sym, "agent": "pipeline_v8", "status": "running",
        "message": format!("✅ Stage 1: {} {} — Score {:.0}% | {} ({}) | TF Confluence: {}/{}",
            best.direction, sym, best.score, best.strategy_name, best.best_timeframe,
            best.tf_confluence.agree_count, best.tf_confluence.total_tfs)
    }).to_string());

    // ═══════════════════════════════════════════════
    //  Fetch History (used by both Gemma and Gemini)
    // ═══════════════════════════════════════════════

    let history = fetch_history(sym, &best.strategy_name, db).await;

    // Check disabled stages from job config
    let disabled_stages: Vec<String> = ctx.job_config["disabled_stages"]
        .as_array()
        .map(|arr| arr.iter().filter_map(|v| v.as_str().map(String::from)).collect())
        .unwrap_or_default();
    let gemma_disabled = disabled_stages.iter().any(|s| s == "gemma");
    let gemini_disabled = disabled_stages.iter().any(|s| s == "gemini");

    // ═══════════════════════════════════════════════
    //  Stage 2: Gemma 4 Cloud Validate
    // ═══════════════════════════════════════════════

    let (_gemma_approved, gemma_reason) = if gemma_disabled {
        // Skip Gemma — auto-approve and notify UI
        info!("⏭️ [Pipeline v8] Gemma DISABLED — skipping to next stage");
        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": sym, "agent": "gemma_filter", "status": "done",
            "message": "⏭️ Gemma 4 ปิดใช้งาน — ข้ามไปขั้นตอนถัดไป"
        }).to_string());
        (true, "SKIP (disabled)".to_string())
    } else {
        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": sym, "agent": "gemma_filter", "status": "running",
            "message": format!("🏠 Gemma 4: ตรวจสอบ {} {} (Score {:.0}%) — กลยุทธ์ {}...",
                best.direction, sym, best.score, best.strategy_name)
        }).to_string());

        let gemma = gemma_validate_v8(&ctx.gemini_key, sym, &best, &history, log_tx).await;

        if !gemma.0 {
            let reason = &gemma.1;
            let _ = log_tx.send(serde_json::json!({
                "type": "agent_log", "symbol": sym, "agent": "gemma_filter", "status": "done",
                "message": format!("❌ Gemma REJECT: {}", reason)
            }).to_string());

            if ctx.discord_alert && !ctx.discord_channel_order.is_empty() {
                crate::discord_bot::send_to_channel(&ctx.discord_channel_order, &format!(
                    "🏠 **Gemma Reject**\n📊 {} **{}**\n🎯 Score: {:.0}%\n📈 กลยุทธ์: {} ({})\n📜 ประวัติ: WR {:.0}% ({} trades)\n❌ {}",
                    best.direction, sym, best.score, best.strategy_name, best.best_timeframe,
                    history.symbol_win_rate, history.symbol_total_trades, reason
                )).await;
            }

            return PipelineV8Result {
                decision: "HOLD".into(), confidence: best.score, lot_size: 0.0,
                strategy_name: best.strategy_name, timeframe: best.best_timeframe,
                reasoning: format!("Gemma rejected: {}", reason),
                server_scan: scan,
                gemma_verdict: format!("REJECT: {}", reason),
                gemini_verdict: "SKIP".into(),
            };
        }

        let reason = gemma.1.clone();
        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": sym, "agent": "gemma_filter", "status": "done",
            "message": format!("✅ Gemma APPROVE: {}", reason)
        }).to_string());
        (true, reason)
    };

    // ═══════════════════════════════════════════════
    //  Stage 3: Gemini Final Confirm
    // ═══════════════════════════════════════════════

    let (_gemini_approved, gemini_reason, gemini_confidence) = if gemini_disabled {
        // Skip Gemini — auto-approve with server score
        info!("⏭️ [Pipeline v8] Gemini DISABLED — using server scan result directly");
        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": sym, "agent": "gemini_confirm", "status": "done",
            "message": "⏭️ Gemini ปิดใช้งาน — ใช้ผลจาก Server Scan โดยตรง"
        }).to_string());
        (true, "SKIP (disabled)".to_string(), best.score)
    } else {
        let gemma_label = if gemma_disabled { "Gemma ปิดใช้งาน — ไม่มีการตรวจสอบ" } else { &gemma_reason };
        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": sym, "agent": "gemini_confirm", "status": "running",
            "message": format!("☁️ Gemini: ยืนยัน {} {} — {}...",
                best.direction, sym, if gemma_disabled { "ข้าม Gemma" } else { "Gemma เห็นด้วย" })
        }).to_string());

        // Build candle data for Gemini (multi-TF)
        let mut tf_candle_summaries = Vec::new();
        for &(tf_name, tf_min, count) in TIMEFRAMES {
            let candles = db.get_candles_for_strategy(sym, tf_min, count).await;
            if candles.len() >= 5 {
                let recent = &candles[candles.len().saturating_sub(15)..];
                let ohlc: Vec<String> = recent.iter().map(|c| {
                    format!("O:{:.5} H:{:.5} L:{:.5} C:{:.5}", c.open, c.high, c.low, c.close)
                }).collect();
                let ind = strategy::compute_indicators(&candles);
                tf_candle_summaries.push(format!(
                    "=== {} ({} candles) ===\nRSI:{:.1} EMA9:{:.5} EMA21:{:.5} EMA50:{:.5}\nBB: {:.5}/{:.5}/{:.5}\n{}\n",
                    tf_name, candles.len(), ind.rsi_14, ind.ema_9, ind.ema_21, ind.ema_50,
                    ind.bb_upper, ind.bb_middle, ind.bb_lower,
                    ohlc.join("\n")
                ));
            }
        }

        let gemini = gemini_confirm_v8(
            &ctx.gemini_key, &ctx.gemini_model, sym,
            &best, gemma_label, &history,
            &tf_candle_summaries.join("\n"),
            &ctx.global_news, &ctx.global_calendar,
            ctx.balance, ctx.equity, ctx.open_positions,
            log_tx,
        ).await;

        if !gemini.0 {
            let reason = &gemini.1;
            let _ = log_tx.send(serde_json::json!({
                "type": "agent_log", "symbol": sym, "agent": "gemini_confirm", "status": "done",
                "message": format!("❌ Gemini REJECT: {}", reason)
            }).to_string());

            if ctx.discord_alert && !ctx.discord_channel_order.is_empty() {
                crate::discord_bot::send_to_channel(&ctx.discord_channel_order, &format!(
                    "☁️ **Gemini Reject**\n📊 {} **{}**\n🎯 Score: {:.0}%\n📈 {} ({})\n🏠 Gemma: {}\n❌ Gemini: {}",
                    best.direction, sym, best.score, best.strategy_name, best.best_timeframe,
                    gemma_reason, reason
                )).await;
            }

            return PipelineV8Result {
                decision: "HOLD".into(), confidence: best.score, lot_size: 0.0,
                strategy_name: best.strategy_name, timeframe: best.best_timeframe,
                reasoning: format!("Gemini rejected: {}", reason),
                server_scan: scan,
                gemma_verdict: if gemma_disabled { "SKIP (disabled)".into() } else { format!("APPROVE: {}", gemma_reason) },
                gemini_verdict: format!("REJECT: {}", reason),
            };
        }

        (true, gemini.1.clone(), gemini.2)
    };

    // ═══════════════════════════════════════════════
    //  Final: Calculate Lot + Return
    // ═══════════════════════════════════════════════

    let final_confidence = if gemini_disabled {
        best.score // Use server score directly when Gemini is disabled
    } else {
        (best.score * 0.4 + gemini_confidence * 0.6).clamp(0.0, 100.0)
    };

    let fallback_lot = ctx.job_config["lot_size"].as_f64().unwrap_or(0.01);
    let lot_size = if ctx.job_config["lot_scale"].as_bool().unwrap_or(false) {
        if final_confidence >= 85.0 { fallback_lot * 3.0 }
        else if final_confidence >= 70.0 { fallback_lot * 2.0 }
        else { fallback_lot }
    } else {
        fallback_lot
    };

    let gemma_label = if gemma_disabled { "SKIP (disabled)" } else { &gemma_reason };
    let gemini_label = if gemini_disabled { "SKIP (disabled)".to_string() } else { format!("{} ({:.0}%)", gemini_reason, gemini_confidence) };

    let reasoning = format!(
        "🔥 Pipeline v8\n📈 กลยุทธ์: {} ({}) — Score {:.0}%\nTF Confluence: {}/{}\n🏠 Gemma: {}\n☁️ Gemini: {}\n💰 Final: {:.0}% → Lot: {:.2}",
        best.strategy_name, best.best_timeframe, best.score,
        best.tf_confluence.agree_count, best.tf_confluence.total_tfs,
        gemma_label, gemini_label,
        final_confidence, lot_size
    );

    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": sym, "agent": "pipeline_v8", "status": "done",
        "message": format!("🔥 {} {} — {:.0}% lot:{:.2} | {} ({})",
            best.direction, sym, final_confidence, lot_size, best.strategy_name, best.best_timeframe)
    }).to_string());

    if ctx.discord_alert && !ctx.discord_channel_order.is_empty() {
        crate::discord_bot::send_to_channel(&ctx.discord_channel_order, &format!(
            "🔥 **Pipeline v8 — Signal Ready**\n\n📊 **{} {}**\n🎯 Confidence: **{:.0}%**\n💰 Lot: {:.2}\n\n📈 กลยุทธ์: {} ({})\nScore: {:.0}% | TF: {}/{}\n\n🏠 Gemma: {}\n☁️ Gemini: {}\n\n📝 เหตุผลที่เลือก: {}",
            best.direction, sym, final_confidence, lot_size,
            best.strategy_name, best.best_timeframe, best.score,
            best.tf_confluence.agree_count, best.tf_confluence.total_tfs,
            gemma_label, gemini_label,
            best.selection_reasoning
        )).await;
    }

    info!("🔥 [Pipeline v8] Final: {} {} → {:.0}% lot:{:.2}", sym, best.direction, final_confidence, lot_size);

    PipelineV8Result {
        decision: best.direction.clone(),
        confidence: final_confidence,
        lot_size,
        strategy_name: best.strategy_name.clone(),
        timeframe: best.best_timeframe.clone(),
        reasoning,
        server_scan: scan,
        gemma_verdict: if gemma_disabled { "SKIP (disabled)".into() } else { format!("APPROVE: {}", gemma_reason) },
        gemini_verdict: if gemini_disabled { "SKIP (disabled)".into() } else { format!("APPROVE: {} ({:.0}%)", gemini_reason, gemini_confidence) },
    }
}

// ──────────────────────────────────────────────
//  Stage 1: Server Strategy Scan
// ──────────────────────────────────────────────

async fn server_strategy_scan(
    symbol: &str,
    db: &Database,
    log_tx: &broadcast::Sender<String>,
) -> ServerScanResult {
    let scan_start = std::time::Instant::now();
    let mut all_signals: Vec<(String, String, String, f64, String, String)> = Vec::new(); // (strategy, tf, direction, confidence, reason, indicator_summary)
    let mut all_scan_details: Vec<String> = Vec::new();
    let mut buy_count = 0usize;
    let mut sell_count = 0usize;

    // Fetch performance data for scoring
    let perf = db.get_symbol_performance(symbol, 30).await;
    let symbol_win_rate = perf["win_rate"].as_f64().unwrap_or(50.0);
    let symbol_total_trades = perf["total_trades"].as_i64().unwrap_or(0);
    let recent_streak = db.get_recent_streak(symbol).await;

    let utc_hour = chrono::Utc::now().hour() as i32;
    let (session_name, session_start, session_end) = if utc_hour >= 0 && utc_hour < 8 {
        ("Asia", 0, 8)
    } else if utc_hour >= 8 && utc_hour < 16 {
        ("London", 8, 16)
    } else {
        ("New York", 16, 24)
    };
    let session_wr = db.get_session_performance(symbol, session_start, session_end, 30).await;

    // Scan each TF
    for &(tf_name, tf_min, candle_count) in TIMEFRAMES {
        let candles = db.get_candles_for_strategy(symbol, tf_min, candle_count).await;
        if candles.len() < MIN_CANDLES {
            all_scan_details.push(format!("{}: ข้อมูลไม่พอ ({} แท่ง)", tf_name, candles.len()));
            continue;
        }

        let indicators = strategy::compute_indicators(&candles);

        for &strat_name in strategy::ALL_STRATEGIES {
            let result = strategy::evaluate_strategy(strat_name, &indicators);
            let dir = match result.signal {
                strategy::Signal::Buy => { buy_count += 1; "BUY" }
                strategy::Signal::Sell => { sell_count += 1; "SELL" }
                strategy::Signal::None => {
                    all_scan_details.push(format!("{}/{}: HOLD", tf_name, strat_name));
                    continue;
                }
            };
            all_scan_details.push(format!("✅ {}/{}: {} {:.0}%", tf_name, strat_name, dir, result.confidence));
            all_signals.push((
                strat_name.to_string(), tf_name.to_string(), dir.to_string(),
                result.confidence, result.reason.clone(), result.indicator_summary.clone()
            ));
        }
    }

    let total_signals = all_signals.len();

    // Score each signal
    let mut scored: Vec<(f64, usize)> = Vec::new(); // (score, index)
    for (i, (strat, tf, dir, conf, _reason, _ind)) in all_signals.iter().enumerate() {
        let mut score = *conf;

        // TF Confluence bonus: count how many TFs agree with this direction
        let tf_agree_count = all_signals.iter()
            .filter(|s| s.2 == *dir && s.1 != *tf)
            .map(|s| &s.1)
            .collect::<std::collections::HashSet<_>>()
            .len();
        let tf_bonus = (tf_agree_count as f64) * 5.0;  // +5% per agreeing TF
        score += tf_bonus;

        // History bonus/penalty
        if symbol_total_trades >= 10 {
            if symbol_win_rate > 60.0 { score += (symbol_win_rate - 50.0) * 0.3; }
            else if symbol_win_rate < 40.0 { score -= (50.0 - symbol_win_rate) * 0.5; }
        }

        // Strategy-specific performance
        let (strat_wr, strat_count) = db.get_strategy_performance(symbol, strat, 30).await;
        if strat_count >= 5 {
            if strat_wr > 60.0 { score += (strat_wr - 50.0) * 0.2; }
            else if strat_wr < 40.0 { score -= (50.0 - strat_wr) * 0.3; }
        }

        // Session bonus
        if session_wr > 55.0 { score += 3.0; }
        else if session_wr < 35.0 { score -= 5.0; }

        // Streak dampening
        if recent_streak < -3 { score -= 10.0; }
        if recent_streak > 5 { score -= 5.0; }

        score = score.clamp(0.0, 100.0);
        scored.push((score, i));
    }

    // Sort by score descending → pick the best
    scored.sort_by(|a, b| b.0.partial_cmp(&a.0).unwrap_or(std::cmp::Ordering::Equal));

    let best_signal = if let Some(&(best_score, best_idx)) = scored.first() {
        if best_score >= MIN_CONFIDENCE {
            let sig = &all_signals[best_idx];
            let (strat, tf, dir, conf, reason, ind_summary) = sig;

            // Build TF confluence detail
            let tf_details: Vec<TfDetail> = all_signals.iter()
                .filter(|s| s.2 == *dir)
                .map(|s| TfDetail {
                    timeframe: s.1.clone(),
                    direction: s.2.clone(),
                    confidence: s.3,
                    strategy: s.0.clone(),
                })
                .collect();
            let agree_tf_count = tf_details.iter().map(|d| &d.timeframe)
                .collect::<std::collections::HashSet<_>>().len();
            let tf_confluence = TfConfluence {
                agree_count: agree_tf_count,
                total_tfs: TIMEFRAMES.len(),
                details: tf_details,
            };

            // Build selection reasoning
            let second_best = scored.get(1).map(|(s, i)| {
                let ss = &all_signals[*i];
                format!("อันดับ 2: {}/{} {} ({:.0}%)", ss.1, ss.0, ss.2, s)
            }).unwrap_or_default();

            let selection_reasoning = format!(
                "เลือก {}/{} เพราะ: Score สูงสุด {:.0}% (Base Conf {:.0}% + TF Confluence {}/{} + Symbol WR {:.0}% + Session {} {:.0}% + Streak {}). เหตุผลกลยุทธ์: {} | {}",
                tf, strat, best_score, conf, agree_tf_count, TIMEFRAMES.len(),
                symbol_win_rate, session_name, session_wr, recent_streak,
                reason, second_best
            );

            Some(BestSignal {
                strategy_name: strat.clone(),
                direction: dir.clone(),
                confidence: *conf,
                reason: reason.clone(),
                best_timeframe: tf.clone(),
                score: best_score,
                tf_confluence,
                indicator_summary: ind_summary.clone(),
                selection_reasoning,
            })
        } else {
            None
        }
    } else {
        None
    };

    let scan_time = scan_start.elapsed().as_millis();

    ServerScanResult {
        strategies_scanned: strategy::ALL_STRATEGIES.len() * TIMEFRAMES.len(),
        timeframes_scanned: TIMEFRAMES.len(),
        total_signals,
        buy_signals: buy_count,
        sell_signals: sell_count,
        best_signal,
        all_signals: all_scan_details,
        scan_time_ms: scan_time,
    }
}

// ──────────────────────────────────────────────
//  Stage 2: Gemma 4 Validate
// ──────────────────────────────────────────────

async fn gemma_validate_v8(
    gemini_key: &str,
    symbol: &str,
    signal: &BestSignal,
    history: &HistoryData,
    log_tx: &broadcast::Sender<String>,
) -> (bool, String) {
    let prompt = format!(
r#"You are a quick trade signal validator for EA-24. Answer ONLY "APPROVE" or "REJECT" followed by 1 short reason (under 50 words) in Thai.

## Signal from Server (เลือกโดยอัลกอริทึม)
- Symbol: {symbol}
- Direction: {dir}
- Strategy: {strat} (Timeframe: {tf})
- Score: {score:.0}% (Base Confidence: {conf:.0}%)
- TF Confluence: {tf_agree}/{tf_total} timeframes เห็นด้วย
- เหตุผลที่เลือก: {selection}

## Indicators
{indicators}

## ประวัติคู่เงินนี้ 30 วัน
- Win Rate: {wr:.0}% ({trades} trades)
- Strategy Win Rate: {strat_wr:.0}% ({strat_trades} trades)
- Avg PnL: ${avg_pnl:.2}
- Session: {session} (WR {session_wr:.0}%)
- Streak: {streak}

## 5 ออเดอร์ล่าสุด
{recent}

## Rules
- APPROVE if signal aligns with trend & indicators reasonable & history supports
- REJECT if BUY with RSI>80 or SELL with RSI<20
- REJECT if signal conflicts with strong trend
- REJECT if this strategy has poor win rate (<35%) on this symbol
- REJECT if 3+ consecutive losses (be very strict)
- When in doubt, APPROVE

Answer ONLY: APPROVE or REJECT + 1 line Thai reason"#,
        symbol = symbol,
        dir = signal.direction,
        strat = signal.strategy_name,
        tf = signal.best_timeframe,
        score = signal.score,
        conf = signal.confidence,
        tf_agree = signal.tf_confluence.agree_count,
        tf_total = signal.tf_confluence.total_tfs,
        selection = signal.selection_reasoning,
        indicators = signal.indicator_summary,
        wr = history.symbol_win_rate,
        trades = history.symbol_total_trades,
        strat_wr = history.strategy_win_rate,
        strat_trades = history.strategy_total_trades,
        avg_pnl = history.avg_pnl,
        session = history.session_name,
        session_wr = history.session_win_rate,
        streak = history.recent_streak,
        recent = format_recent_decisions(&history.recent_decisions),
    );

    match ai_engine::call_ai_pub(gemini_key, "gemma-4-31b-it", &prompt, 0.2, 100, false).await {
        Ok(response) => {
            let clean = response.trim().to_uppercase();
            let approved = clean.starts_with("APPROVE");
            let reason = response.trim().to_string();
            info!("🏠 [Gemma v8] {} {} → {} — {}", signal.direction, symbol,
                if approved { "APPROVE" } else { "REJECT" }, reason);
            let _ = log_tx.send(serde_json::json!({
                "type": "agent_log_verbose", "symbol": symbol, "agent": "gemma_filter_v8",
                "prompt": prompt, "response": response.clone()
            }).to_string());
            (approved, reason)
        }
        Err(e) => {
            warn!("🏠 [Gemma v8] Error: {} — Auto-approving", e);
            (true, format!("Auto-approve (API Error: {})", e))
        }
    }
}

// ──────────────────────────────────────────────
//  Stage 3: Gemini Final Confirm
// ──────────────────────────────────────────────

#[allow(clippy::too_many_arguments)]
async fn gemini_confirm_v8(
    gemini_key: &str,
    model: &str,
    symbol: &str,
    signal: &BestSignal,
    gemma_reason: &str,
    history: &HistoryData,
    chart_data: &str,
    news: &Option<ai_engine::NewsResult>,
    calendar: &Option<ai_engine::CalendarResult>,
    balance: f64,
    equity: f64,
    open_positions: usize,
    log_tx: &broadcast::Sender<String>,
) -> (bool, String, f64) {
    let news_summary = news.as_ref().map(|n| {
        format!("Sentiment: {} — {}", n.sentiment, n.summary)
    }).unwrap_or_else(|| "ไม่มีข้อมูลข่าว".to_string());

    let calendar_summary = calendar.as_ref().map(|c| {
        if c.high_impact_soon {
            format!("⚠️ {}", c.warning)
        } else {
            "✅ ไม่มีข่าวสำคัญใกล้ๆ".to_string()
        }
    }).unwrap_or_else(|| "ไม่มีข้อมูล".to_string());

    let drawdown = if balance > 0.0 { ((balance - equity) / balance) * 100.0 } else { 0.0 };

    let prompt = format!(
r#"You are a professional fund manager making a FINAL trading decision. Respond REASONING in Thai only.

## Signal (approved by both Server Algorithm AND Gemma 4 AI)
- Symbol: {symbol}
- Direction: {dir}
- Strategy: {strat} (Timeframe: {tf})
- Server Score: {score:.0}% | TF Confluence: {tf_agree}/{tf_total}
- เหตุผลอัลกอริทึม: {reason}
- Gemma 4 verdict: {gemma_reason}

## ประวัติคู่เงิน
- Win Rate: {wr:.0}% ({trades} trades) | Strategy WR: {strat_wr:.0}%
- Avg PnL: ${avg_pnl:.2} | Session {session}: {session_wr:.0}% | Streak: {streak}

## สถานะพอร์ต
- Balance: ${balance:.2} | Equity: ${equity:.2} | Drawdown: {dd:.2}%
- Open Positions: {positions}/5

## ข่าว
{news}

## ปฏิทินเศรษฐกิจ
{calendar}

## กราฟ (Multi-Timeframe OHLC)
{chart}

## Instructions
1. Verify signal aligns with news + chart patterns + portfolio risk
2. REJECT if high-impact news within 30 minutes
3. REJECT if drawdown > 8%
4. REJECT if open positions >= 5
5. REJECT if news clearly conflicts with trade direction
6. Otherwise APPROVE with your confidence level

Respond EXACTLY:
DECISION: [APPROVE/REJECT]
CONFIDENCE: [0-100]
REASONING: [2-3 sentences in Thai explaining your decision]"#,
        symbol = symbol,
        dir = signal.direction,
        strat = signal.strategy_name,
        tf = signal.best_timeframe,
        score = signal.score,
        tf_agree = signal.tf_confluence.agree_count,
        tf_total = signal.tf_confluence.total_tfs,
        reason = signal.reason,
        gemma_reason = gemma_reason,
        wr = history.symbol_win_rate,
        trades = history.symbol_total_trades,
        strat_wr = history.strategy_win_rate,
        avg_pnl = history.avg_pnl,
        session = history.session_name,
        session_wr = history.session_win_rate,
        streak = history.recent_streak,
        balance = balance,
        equity = equity,
        dd = drawdown,
        positions = open_positions,
        news = news_summary,
        calendar = calendar_summary,
        chart = chart_data,
    );

    match ai_engine::call_ai_pub(gemini_key, model, &prompt, 0.2, 400, false).await {
        Ok(response) => {
            let _ = log_tx.send(serde_json::json!({
                "type": "agent_log_verbose", "symbol": symbol, "agent": "gemini_confirm_v8",
                "prompt": prompt, "response": response.clone()
            }).to_string());

            let mut decision = "REJECT".to_string();
            let mut confidence = 50.0;
            let mut reasoning = String::new();

            for line in response.lines() {
                let l = line.trim();
                if l.starts_with("DECISION:") {
                    let v = l.replace("DECISION:", "").trim().to_uppercase();
                    if v.contains("APPROVE") { decision = "APPROVE".into(); }
                }
                if l.starts_with("CONFIDENCE:") {
                    let v: String = l.replace("CONFIDENCE:", "").trim().chars()
                        .filter(|c| c.is_ascii_digit() || *c == '.').collect();
                    confidence = v.parse().unwrap_or(50.0);
                }
                if l.starts_with("REASONING:") {
                    reasoning = l.replace("REASONING:", "").trim().to_string();
                }
            }
            if reasoning.is_empty() { reasoning = response.chars().take(200).collect(); }

            let approved = decision == "APPROVE";
            info!("☁️ [Gemini v8] {} {} → {} ({:.0}%) — {}", signal.direction, symbol,
                decision, confidence, reasoning);

            let _ = log_tx.send(serde_json::json!({
                "type": "agent_log", "symbol": symbol, "agent": "gemini_confirm", "status": "done",
                "message": format!("{} {} ({:.0}%) — {}", if approved { "✅" } else { "❌" }, decision, confidence, reasoning)
            }).to_string());

            (approved, reasoning, confidence)
        }
        Err(e) => {
            warn!("☁️ [Gemini v8] Error: {}", e);
            let _ = log_tx.send(serde_json::json!({
                "type": "agent_log", "symbol": symbol, "agent": "gemini_confirm", "status": "error",
                "message": format!("❌ Error: {}", e)
            }).to_string());
            (false, format!("Error: {}", e), 0.0)
        }
    }
}

// ──────────────────────────────────────────────
//  Helper Functions
// ──────────────────────────────────────────────

async fn fetch_history(symbol: &str, strategy: &str, db: &Database) -> HistoryData {
    let perf = db.get_symbol_performance(symbol, 30).await;
    let recent_decisions = db.get_recent_decisions_context(symbol, 5).await;
    let recent_streak = db.get_recent_streak(symbol).await;
    let (strat_wr, strat_count) = db.get_strategy_performance(symbol, strategy, 30).await;

    let utc_hour = chrono::Utc::now().hour() as i32;
    let (session_name, ss, se) = if utc_hour >= 0 && utc_hour < 8 {
        ("Asia", 0, 8)
    } else if utc_hour >= 8 && utc_hour < 16 {
        ("London", 8, 16)
    } else {
        ("New York", 16, 24)
    };
    let session_wr = db.get_session_performance(symbol, ss, se, 30).await;

    HistoryData {
        symbol_win_rate: perf["win_rate"].as_f64().unwrap_or(50.0),
        symbol_total_trades: perf["total_trades"].as_i64().unwrap_or(0),
        strategy_win_rate: strat_wr,
        strategy_total_trades: strat_count,
        session_name: session_name.to_string(),
        session_win_rate: session_wr,
        recent_streak,
        recent_decisions,
        avg_pnl: perf["avg_pnl"].as_f64().unwrap_or(0.0),
    }
}

fn format_recent_decisions(decisions: &[serde_json::Value]) -> String {
    if decisions.is_empty() {
        return "ยังไม่มีประวัติ".to_string();
    }
    decisions.iter().take(5).map(|d| {
        format!("{} conf:{:.0}% → {} (${:.2})",
            d["direction"].as_str().unwrap_or("?"),
            d["confidence"].as_f64().unwrap_or(0.0),
            d["outcome"].as_str().unwrap_or("?"),
            d["pnl"].as_f64().unwrap_or(0.0))
    }).collect::<Vec<_>>().join(" | ")
}

fn build_hold_result(scan: ServerScanResult, reason: &str) -> PipelineV8Result {
    PipelineV8Result {
        decision: "HOLD".into(),
        confidence: 0.0,
        lot_size: 0.0,
        strategy_name: String::new(),
        timeframe: String::new(),
        reasoning: reason.to_string(),
        server_scan: scan,
        gemma_verdict: "SKIP".into(),
        gemini_verdict: "SKIP".into(),
    }
}

use chrono::Timelike;
