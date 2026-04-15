// ──────────────────────────────────────────────
//  Pipeline v9: Server-First Strategy Scanner
//  Upgrades from v8:
//    • Parallel TF scan (tokio::join!)
//    • Smart TF weighting (H4=2.0x … M5=0.8x)
//    • Volatility gate (ATR ratio filter)
//    • Single AI call (merge Gemma+Gemini → 1 call)
//    • Directional consensus filter (60/40 rule)
//
//  3-Stage Decision Engine:
//    1. Server Scan: 10 Strategies × 5 TF → Best Signal (parallel)
//    2. AI Confirm: Single call with full context → APPROVE/REJECT
//    3. Execute
// ──────────────────────────────────────────────

use log::{info, warn};
use tokio::sync::broadcast;

use crate::db::Database;
use crate::ai_engine;
use crate::strategy;

use std::collections::HashMap;
use std::sync::{LazyLock, Mutex};

// ── AI Call Cache: ป้องกันเรียก AI ซ้ำสำหรับสัญญาณเดิม ──
#[derive(Clone)]
struct LastAiCall {
    direction: String,
    strategy: String,
    timeframe: String,
    score: f64,
    timestamp: std::time::Instant,
}

static AI_CALL_CACHE: LazyLock<Mutex<HashMap<String, LastAiCall>>> =
    LazyLock::new(|| Mutex::new(HashMap::new()));

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

/// Ranked signal for top-N display
#[derive(Debug, Clone, serde::Serialize)]
pub struct TopSignal {
    pub rank: usize,
    pub strategy_name: String,
    pub timeframe: String,
    pub direction: String,
    pub score: f64,
    pub base_confidence: f64,
    pub reason: String,
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
    pub top_signals: Vec<TopSignal>,
    pub all_signals: Vec<String>,
    pub scan_time_ms: u128,
    pub atr_ratio: f64,
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

// (name, minutes, candle_count, weight)
const TIMEFRAMES: &[(&str, i64, i64, f64)] = &[
    ("M5",  5,   50, 0.8),
    ("M15", 15,  50, 1.0),
    ("M30", 30,  50, 1.2),
    ("H1",  60,  50, 1.5),
    ("H4",  240, 30, 2.0),
];

const MIN_CONFIDENCE_NORMAL: f64 = 55.0;
const MIN_CONFIDENCE_LOW_VOL: f64 = 65.0;
const MIN_CONFIDENCE_HIGH_VOL: f64 = 50.0;
const MIN_CANDLES: usize = 10;
const MIN_SCORE_FOR_AI: f64 = 65.0;       // ── Score Gate: ต่ำกว่านี้ไม่ต้องถาม AI
const AI_DEDUP_SECS: u64 = 300;            // ── Signal Dedup: สัญญาณเดิมภายใน 5 นาทีไม่ถามซ้ำ
const FLIP_SCORE_DELTA: f64 = 15.0;        // ── Direction Lock: ต้อง score สูงกว่าเดิม 15% ถึงจะกลับทิศได้
const DIRECTION_LOCK_SECS: u64 = 600;      // ── ล็อคทิศทาง 10 นาที

// ──────────────────────────────────────────────
//  Main Entry Point
// ──────────────────────────────────────────────

pub async fn run_pipeline_v8(
    ctx: &PipelineV8Context,
    db: &Database,
    log_tx: &broadcast::Sender<String>,
) -> PipelineV8Result {
    let sym = &ctx.symbol;

    info!("🔥 [Pipeline v9] Scanning {}...", sym);
    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": sym, "agent": "pipeline_v8", "status": "running",
        "message": format!("🔥 Pipeline v9: เริ่ม scan {} — 10 กลยุทธ์ × 5 TF (Parallel)...", sym)
    }).to_string());

    // ═══════════════════════════════════════════════
    //  Stage 1: Server Strategy Scan (PARALLEL)
    // ═══════════════════════════════════════════════

    let scan = server_strategy_scan(sym, db, log_tx).await;

    let _ = log_tx.send(serde_json::json!({
        "type": "pipeline_v8_scan", "symbol": sym, "scan": &scan
    }).to_string());

    // Dynamic MIN_CONFIDENCE based on volatility
    let min_conf = if scan.atr_ratio > 1.5 {
        MIN_CONFIDENCE_HIGH_VOL
    } else if scan.atr_ratio < 0.5 {
        MIN_CONFIDENCE_LOW_VOL
    } else {
        MIN_CONFIDENCE_NORMAL
    };

    let best = match &scan.best_signal {
        Some(s) if s.score >= min_conf => s.clone(),
        Some(s) => {
            let msg = format!("⏸️ Scan {}: Best score {:.0}% < threshold {:.0}% (ATR ratio: {:.2})",
                sym, s.score, min_conf, scan.atr_ratio);
            let _ = log_tx.send(serde_json::json!({
                "type": "agent_log", "symbol": sym, "agent": "pipeline_v8", "status": "done",
                "message": &msg
            }).to_string());
            return build_hold_result(scan, &msg);
        }
        None => {
            let msg = format!("⏸️ Scan {}: BUY:{} SELL:{} — ไม่มีสัญญาณผ่าน {:.0}%",
                sym, scan.buy_signals, scan.sell_signals, min_conf);
            let _ = log_tx.send(serde_json::json!({
                "type": "agent_log", "symbol": sym, "agent": "pipeline_v8", "status": "done",
                "message": &msg
            }).to_string());
            return build_hold_result(scan, &msg);
        }
    };

    // ═══════════════════════════════════════════════
    //  Directional Consensus Filter (60/40 rule)
    // ═══════════════════════════════════════════════
    let total_directional = scan.buy_signals + scan.sell_signals;
    if total_directional >= 4 {
        let dominant = scan.buy_signals.max(scan.sell_signals) as f64;
        let ratio = dominant / total_directional as f64;
        if ratio < 0.60 {
            let msg = format!("⏸️ {} indecisive: BUY:{} SELL:{} (ratio {:.0}% < 60%) — ตลาดไม่ชัดเจน",
                sym, scan.buy_signals, scan.sell_signals, ratio * 100.0);
            let _ = log_tx.send(serde_json::json!({
                "type": "agent_log", "symbol": sym, "agent": "pipeline_v8", "status": "done",
                "message": &msg
            }).to_string());
            return build_hold_result(scan, &msg);
        }
    }

    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": sym, "agent": "pipeline_v8", "status": "running",
        "message": format!("✅ Stage 1: {} {} — Score {:.0}% | {} ({}) | TF Confluence: {}/{} | ATR ratio: {:.2}",
            best.direction, sym, best.score, best.strategy_name, best.best_timeframe,
            best.tf_confluence.agree_count, best.tf_confluence.total_tfs, scan.atr_ratio)
    }).to_string());

    // ═══════════════════════════════════════════════
    //  GATE 1: Score Gate — ไม่ถึง 65% ไม่ต้องถาม AI
    // ═══════════════════════════════════════════════
    if best.score < MIN_SCORE_FOR_AI {
        let msg = format!("⏭️ Score {:.0}% < {:.0}% — ข้ามการเรียก AI (ประหยัด API)",
            best.score, MIN_SCORE_FOR_AI);
        info!("🛡️ [Pipeline v9] {}", msg);
        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": sym, "agent": "pipeline_v8", "status": "done",
            "message": &msg
        }).to_string());
        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": sym, "agent": "gemma_filter", "status": "done",
            "message": "⏭️ ข้าม — Score ต่ำเกินไป"
        }).to_string());
        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": sym, "agent": "gemini_confirm", "status": "done",
            "message": "⏭️ ข้าม — Score ต่ำเกินไป"
        }).to_string());
        return build_hold_result(scan, &msg);
    }

    // ═══════════════════════════════════════════════
    //  GATE 2: Signal Dedup — สัญญาณเดิมไม่ถามซ้ำ
    // ═══════════════════════════════════════════════
    {
        let cache = AI_CALL_CACHE.lock().unwrap();
        if let Some(last) = cache.get(sym.as_str()) {
            let elapsed = last.timestamp.elapsed().as_secs();
            if elapsed < AI_DEDUP_SECS
                && last.direction == best.direction
                && last.strategy == best.strategy_name
                && last.timeframe == best.best_timeframe
            {
                let msg = format!(
                    "⏭️ สัญญาณเดิม ({} {} {}) — ถามไปแล้ว {}s ที่แล้ว (dedup {}s)",
                    best.direction, best.strategy_name, best.best_timeframe,
                    elapsed, AI_DEDUP_SECS
                );
                info!("🛡️ [Pipeline v9] {}", msg);
                let _ = log_tx.send(serde_json::json!({
                    "type": "agent_log", "symbol": sym, "agent": "pipeline_v8", "status": "done",
                    "message": &msg
                }).to_string());
                let _ = log_tx.send(serde_json::json!({
                    "type": "agent_log", "symbol": sym, "agent": "gemma_filter", "status": "done",
                    "message": "⏭️ ข้าม — สัญญาณเดิม"
                }).to_string());
                let _ = log_tx.send(serde_json::json!({
                    "type": "agent_log", "symbol": sym, "agent": "gemini_confirm", "status": "done",
                    "message": "⏭️ ข้าม — สัญญาณเดิม"
                }).to_string());
                return build_hold_result(scan, &msg);
            }
        }
    } // drop lock

    // ═══════════════════════════════════════════════
    //  GATE 3: Direction Lock — ห้ามกลับทิศง่ายๆ
    // ═══════════════════════════════════════════════
    {
        let cache = AI_CALL_CACHE.lock().unwrap();
        if let Some(last) = cache.get(sym.as_str()) {
            let elapsed = last.timestamp.elapsed().as_secs();
            // ถ้ายังอยู่ในช่วงล็อค และทิศทางกลับกัน
            if elapsed < DIRECTION_LOCK_SECS && last.direction != best.direction {
                let score_diff = best.score - last.score;
                if score_diff < FLIP_SCORE_DELTA {
                    let msg = format!(
                        "⛔ Direction Lock: กลับทิศ {} → {} แต่ score ต่างแค่ {:.0} ({:.0}% vs {:.0}%) — ต้อง ≥{:.0}% ถึงจะกลับทิศได้ (ล็อคอีก {}s)",
                        last.direction, best.direction, score_diff,
                        best.score, last.score, FLIP_SCORE_DELTA, DIRECTION_LOCK_SECS - elapsed
                    );
                    info!("🛡️ [Pipeline v9] {}", msg);
                    let _ = log_tx.send(serde_json::json!({
                        "type": "agent_log", "symbol": sym, "agent": "pipeline_v8", "status": "done",
                        "message": &msg
                    }).to_string());
                    let _ = log_tx.send(serde_json::json!({
                        "type": "agent_log", "symbol": sym, "agent": "gemma_filter", "status": "done",
                        "message": "⛔ ข้าม — Direction Lock"
                    }).to_string());
                    let _ = log_tx.send(serde_json::json!({
                        "type": "agent_log", "symbol": sym, "agent": "gemini_confirm", "status": "done",
                        "message": "⛔ ข้าม — Direction Lock"
                    }).to_string());
                    return build_hold_result(scan, &msg);
                } else {
                    info!("🔄 [Pipeline v9] Direction flip allowed: {} → {} (score diff {:.0}% ≥ {:.0}%)",
                        last.direction, best.direction, score_diff, FLIP_SCORE_DELTA);
                }
            }
        }
    } // drop lock

    // ═══════════════════════════════════════════════
    //  Fetch History (parallel with candle prep)
    // ═══════════════════════════════════════════════

    let history = fetch_history(sym, &best.strategy_name, db).await;

    // Check disabled stages from job config
    let disabled_stages: Vec<String> = ctx.job_config["disabled_stages"]
        .as_array()
        .map(|arr| arr.iter().filter_map(|v| v.as_str().map(String::from)).collect())
        .unwrap_or_default();
    let _gemma_disabled = disabled_stages.iter().any(|s| s == "gemma");
    let gemini_disabled = disabled_stages.iter().any(|s| s == "gemini");
    let use_single_ai = !disabled_stages.iter().any(|s| s == "single_ai_off");

    // ═══════════════════════════════════════════════
    //  Stage 2: AI Confirm (Single Call — merged Gemma+Gemini)
    // ═══════════════════════════════════════════════

    let (_ai_approved, ai_reason, ai_confidence) = if gemini_disabled {
        // Skip AI entirely — use server score directly
        info!("⏭️ [Pipeline v9] AI DISABLED — using server scan result directly");
        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": sym, "agent": "gemini_confirm", "status": "done",
            "message": "⏭️ AI ปิดใช้งาน — ใช้ผลจาก Server Scan โดยตรง"
        }).to_string());
        (true, "SKIP (disabled)".to_string(), best.score)
    } else if use_single_ai {
        // ═══ SINGLE AI CALL (v9 default) ═══
        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": sym, "agent": "gemma_filter", "status": "done",
            "message": "⚡ v9 Mode: Single AI Call — Gemma merged into Gemini"
        }).to_string());
        
        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": sym, "agent": "gemini_confirm", "status": "running",
            "message": format!("☁️ AI Confirm: {} {} — Score {:.0}%...", best.direction, sym, best.score)
        }).to_string());

        // Build candle data for AI (multi-TF)
        let tf_candle_summaries = build_tf_candle_summaries(sym, db).await;

        let result = ai_confirm_single(
            &ctx.gemini_key, &ctx.gemini_model, sym,
            &best, &history,
            &tf_candle_summaries,
            &ctx.global_news, &ctx.global_calendar,
            ctx.balance, ctx.equity, ctx.open_positions,
            log_tx,
        ).await;

        if !result.0 {
            let reason = &result.1;
            let _ = log_tx.send(serde_json::json!({
                "type": "agent_log", "symbol": sym, "agent": "gemini_confirm", "status": "done",
                "message": format!("❌ AI REJECT: {}", reason)
            }).to_string());

            if ctx.discord_alert && !ctx.discord_channel_order.is_empty() {
                crate::discord_bot::send_to_channel(&ctx.discord_channel_order, &format!(
                    "☁️ **AI Reject (v9 Single)**\n📊 {} **{}**\n🎯 Score: {:.0}%\n📈 {} ({})\n📜 WR {:.0}% ({} trades)\n❌ {}",
                    best.direction, sym, best.score, best.strategy_name, best.best_timeframe,
                    history.symbol_win_rate, history.symbol_total_trades, reason
                )).await;
            }

            return PipelineV8Result {
                decision: "HOLD".into(), confidence: best.score, lot_size: 0.0,
                strategy_name: best.strategy_name, timeframe: best.best_timeframe,
                reasoning: format!("AI rejected: {}", reason),
                server_scan: scan,
                gemma_verdict: "MERGED".into(),
                gemini_verdict: format!("REJECT: {}", reason),
            };
        }

        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": sym, "agent": "gemini_confirm", "status": "done",
            "message": format!("✅ AI APPROVE ({:.0}%): {}", result.2, result.1)
        }).to_string());

        (true, result.1.clone(), result.2)
    } else {
        // ═══ LEGACY 2-STAGE (Gemma → Gemini) ═══
        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": sym, "agent": "gemma_filter", "status": "running",
            "message": format!("🏠 Gemma 4: ตรวจสอบ {} {} (Score {:.0}%) — กลยุทธ์ {}...",
                best.direction, sym, best.score, best.strategy_name)
        }).to_string());

        let gemma_data_sources: Vec<String> = ctx.job_config["gemma_data_sources"]
            .as_array()
            .map(|arr| arr.iter().filter_map(|v| v.as_str().map(String::from)).collect())
            .unwrap_or_else(|| vec!["indicators".into(), "trade_history".into(), "strategy_wr".into(), "session".into(), "streak".into(), "recent_orders".into()]);

        let gemma = gemma_validate_v8(&ctx.gemini_key, sym, &best, &history, &gemma_data_sources, log_tx).await;

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

        let gemma_reason = gemma.1.clone();
        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": sym, "agent": "gemma_filter", "status": "done",
            "message": format!("✅ Gemma APPROVE: {}", gemma_reason)
        }).to_string());

        // Stage 3: Gemini
        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": sym, "agent": "gemini_confirm", "status": "running",
            "message": format!("☁️ Gemini: ยืนยัน {} {} — Gemma เห็นด้วย...", best.direction, sym)
        }).to_string());

        let tf_candle_summaries = build_tf_candle_summaries(sym, db).await;

        let gemini = gemini_confirm_v8(
            &ctx.gemini_key, &ctx.gemini_model, sym,
            &best, &gemma_reason, &history,
            &tf_candle_summaries,
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
                gemma_verdict: format!("APPROVE: {}", gemma_reason),
                gemini_verdict: format!("REJECT: {}", reason),
            };
        }

        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": sym, "agent": "gemini_confirm", "status": "done",
            "message": format!("✅ Gemini APPROVE ({:.0}%): {}", gemini.2, gemini.1)
        }).to_string());

        (true, gemini.1.clone(), gemini.2)
    };

    // ═══════════════════════════════════════════════
    //  Save to Dedup Cache (ป้องกันเรียก AI ซ้ำ)
    // ═══════════════════════════════════════════════
    {
        let mut cache = AI_CALL_CACHE.lock().unwrap();
        cache.insert(sym.to_string(), LastAiCall {
            direction: best.direction.clone(),
            strategy: best.strategy_name.clone(),
            timeframe: best.best_timeframe.clone(),
            score: best.score,
            timestamp: std::time::Instant::now(),
        });
    }

    // ═══════════════════════════════════════════════
    //  Final: Calculate Lot + Return
    // ═══════════════════════════════════════════════

    let final_confidence = if gemini_disabled {
        best.score
    } else {
        (best.score * 0.4 + ai_confidence * 0.6).clamp(0.0, 100.0)
    };

    let fallback_lot = ctx.job_config["lot_size"].as_f64().unwrap_or(0.01);
    let lot_size = if ctx.job_config["lot_scale"].as_bool().unwrap_or(false) {
        if final_confidence >= 85.0 { fallback_lot * 3.0 }
        else if final_confidence >= 70.0 { fallback_lot * 2.0 }
        else { fallback_lot }
    } else {
        fallback_lot
    };

    let ai_label = if gemini_disabled { "SKIP (disabled)".to_string() } else { format!("{} ({:.0}%)", ai_reason, ai_confidence) };

    let reasoning = format!(
        "🔥 Pipeline v9\n📈 กลยุทธ์: {} ({}) — Score {:.0}%\nTF Confluence: {}/{}\nATR Ratio: {:.2}\n☁️ AI: {}\n💰 Final: {:.0}% → Lot: {:.2}",
        best.strategy_name, best.best_timeframe, best.score,
        best.tf_confluence.agree_count, best.tf_confluence.total_tfs,
        scan.atr_ratio,
        ai_label,
        final_confidence, lot_size
    );

    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": sym, "agent": "pipeline_v8", "status": "done",
        "message": format!("🔥 {} {} — {:.0}% lot:{:.2} | {} ({}) | ATR:{:.2}",
            best.direction, sym, final_confidence, lot_size, best.strategy_name, best.best_timeframe, scan.atr_ratio)
    }).to_string());

    if ctx.discord_alert && !ctx.discord_channel_order.is_empty() {
        crate::discord_bot::send_to_channel(&ctx.discord_channel_order, &format!(
            "🔥 **Pipeline v9 — Signal Ready**\n\n📊 **{} {}**\n🎯 Confidence: **{:.0}%**\n💰 Lot: {:.2}\n\n📈 กลยุทธ์: {} ({})\nScore: {:.0}% | TF: {}/{} | ATR: {:.2}\n\n☁️ AI: {}\n\n📝 เหตุผลที่เลือก: {}",
            best.direction, sym, final_confidence, lot_size,
            best.strategy_name, best.best_timeframe, best.score,
            best.tf_confluence.agree_count, best.tf_confluence.total_tfs, scan.atr_ratio,
            ai_label,
            best.selection_reasoning
        )).await;

        // ═══ Send chart image to Discord ═══
        {
            let mem = db.mem_candles.read().await;
            if let Some(candle_map) = mem.get(sym.as_str()) {
                let candles: Vec<crate::strategy::Candle> = candle_map.values().rev().take(60).cloned().collect::<Vec<_>>().into_iter().rev().collect();
                if candles.len() >= 10 {
                    if let Some(img) = crate::chart_gen::generate_candlestick_chart(
                        sym, &candles, &best.direction, &best.strategy_name, &best.best_timeframe, best.score,
                    ) {
                        let filename = format!("{}_{}.bmp", sym.to_lowercase(), chrono::Utc::now().format("%H%M%S"));
                        crate::discord_bot::send_chart_to_channel(
                            &ctx.discord_channel_order,
                            &format!("📊 {} {} — {} ({})", best.direction, sym, best.strategy_name, best.best_timeframe),
                            &img,
                            &filename,
                        ).await;
                    }
                }
            }
        }
    }

    info!("🔥 [Pipeline v9] Final: {} {} → {:.0}% lot:{:.2}", sym, best.direction, final_confidence, lot_size);

    PipelineV8Result {
        decision: best.direction.clone(),
        confidence: final_confidence,
        lot_size,
        strategy_name: best.strategy_name.clone(),
        timeframe: best.best_timeframe.clone(),
        reasoning,
        server_scan: scan,
        gemma_verdict: if use_single_ai { "MERGED".into() } else { format!("APPROVE: {}", ai_reason) },
        gemini_verdict: if gemini_disabled { "SKIP (disabled)".into() } else { format!("APPROVE: {} ({:.0}%)", ai_reason, ai_confidence) },
    }
}

// ──────────────────────────────────────────────
//  Stage 1: Server Strategy Scan (PARALLEL)
// ──────────────────────────────────────────────

async fn server_strategy_scan(
    symbol: &str,
    db: &Database,
    _log_tx: &broadcast::Sender<String>,
) -> ServerScanResult {
    let scan_start = std::time::Instant::now();

    // ═══ PARALLEL: Fetch all TF candles + performance data simultaneously ═══
    let (candle_results, perf, recent_streak, session_data) = tokio::join!(
        // Fetch candles for all 5 TFs in parallel
        async {
            let (r0, r1, r2, r3, r4) = tokio::join!(
                db.get_candles_for_strategy(symbol, TIMEFRAMES[0].1, TIMEFRAMES[0].2),
                db.get_candles_for_strategy(symbol, TIMEFRAMES[1].1, TIMEFRAMES[1].2),
                db.get_candles_for_strategy(symbol, TIMEFRAMES[2].1, TIMEFRAMES[2].2),
                db.get_candles_for_strategy(symbol, TIMEFRAMES[3].1, TIMEFRAMES[3].2),
                db.get_candles_for_strategy(symbol, TIMEFRAMES[4].1, TIMEFRAMES[4].2)
            );
            vec![
                (TIMEFRAMES[0].0, r0, TIMEFRAMES[0].3),
                (TIMEFRAMES[1].0, r1, TIMEFRAMES[1].3),
                (TIMEFRAMES[2].0, r2, TIMEFRAMES[2].3),
                (TIMEFRAMES[3].0, r3, TIMEFRAMES[3].3),
                (TIMEFRAMES[4].0, r4, TIMEFRAMES[4].3),
            ]
        },
        // Fetch performance data
        db.get_symbol_performance(symbol, 30),
        // Fetch streak
        db.get_recent_streak(symbol),
        // Fetch session info
        async {
            let utc_hour = chrono::Utc::now().hour() as i32;
            let (session_name, ss, se) = if utc_hour >= 0 && utc_hour < 8 {
                ("Asia", 0, 8)
            } else if utc_hour >= 8 && utc_hour < 16 {
                ("London", 8, 16)
            } else {
                ("New York", 16, 24)
            };
            let wr = db.get_session_performance(symbol, ss, se, 30).await;
            (session_name, wr)
        }
    );

    let symbol_win_rate = perf["win_rate"].as_f64().unwrap_or(50.0);
    let symbol_total_trades = perf["total_trades"].as_i64().unwrap_or(0);
    let (session_name, session_wr) = session_data;

    // candle_results is already a Vec from the parallel fetch
    let all_candle_data = candle_results;

    let mut all_signals: Vec<(String, String, String, f64, String, String, f64)> = Vec::new(); // (strategy, tf, direction, confidence, reason, indicator_summary, tf_weight)
    let mut all_scan_details: Vec<String> = Vec::new();
    let mut buy_count = 0usize;
    let mut sell_count = 0usize;
    let mut max_atr_ratio: f64 = 1.0;

    // Evaluate strategies on each TF
    for (tf_name, candles, tf_weight) in &all_candle_data {
        if candles.len() < MIN_CANDLES {
            all_scan_details.push(format!("{}: ข้อมูลไม่พอ ({} แท่ง)", tf_name, candles.len()));
            continue;
        }

        let indicators = strategy::compute_indicators(candles);
        
        // Track ATR ratio for volatility gate
        if indicators.atr_ratio > max_atr_ratio {
            max_atr_ratio = indicators.atr_ratio;
        }

        for &strat_name in strategy::ALL_STRATEGIES {
            let result = strategy::evaluate_strategy(strat_name, &indicators);
            let dir = match result.signal {
                strategy::Signal::Buy => { buy_count += 1; "BUY" }
                strategy::Signal::Sell => { sell_count += 1; "SELL" }
                strategy::Signal::OneUsdFeed => { "1USD" }
                strategy::Signal::None => {
                    all_scan_details.push(format!("{}/{}: HOLD", tf_name, strat_name));
                    continue;
                }
            };
            all_scan_details.push(format!("✅ {}/{}: {} {:.0}% (w:{:.1}x)", tf_name, strat_name, dir, result.confidence, tf_weight));
            all_signals.push((
                strat_name.to_string(), tf_name.to_string(), dir.to_string(),
                result.confidence, result.reason.clone(), result.indicator_summary.clone(),
                *tf_weight,
            ));
        }
    }

    let total_signals = all_signals.len();

    // Score each signal with SMART TF WEIGHTING
    let mut scored: Vec<(f64, usize)> = Vec::new();
    for (i, (strat, tf, dir, conf, _reason, _ind, tf_weight)) in all_signals.iter().enumerate() {
        let mut score = *conf;

        // TF Confluence bonus with WEIGHTING
        let mut tf_agree_weight = 0.0f64;
        let tf_agree_set: std::collections::HashSet<&String> = all_signals.iter()
            .filter(|s| s.2 == *dir && s.1 != *tf)
            .map(|s| &s.1)
            .collect();
        let _tf_agree_count = tf_agree_set.len();
        
        // Weighted confluence: higher TF agreement counts more
        for agreeing_sig in all_signals.iter().filter(|s| s.2 == *dir && s.1 != *tf) {
            tf_agree_weight += agreeing_sig.6 * 4.0; // weight × 4 per agreeing signal
        }
        // Deduplicate TF weight (count unique TFs)
        score += tf_agree_weight.min(30.0); // cap at +30

        // Apply TF weight to base score
        score *= 0.7 + (*tf_weight * 0.15); // H4=1.0, M5=0.82

        // History bonus/penalty (relaxed penalties)
        if symbol_total_trades >= 10 {
            if symbol_win_rate > 55.0 { score += (symbol_win_rate - 50.0) * 0.4; }
            else if symbol_win_rate < 35.0 { score -= (50.0 - symbol_win_rate) * 0.3; }
        }

        // Strategy-specific performance (relaxed)
        let (strat_wr, strat_count) = db.get_strategy_performance(symbol, strat, 30).await;
        if strat_count >= 5 {
            if strat_wr > 55.0 { score += (strat_wr - 50.0) * 0.3; }
            else if strat_wr < 30.0 { score -= (50.0 - strat_wr) * 0.2; }
        }

        // Session bonus (relaxed)
        if session_wr > 55.0 { score += 5.0; }
        else if session_wr < 30.0 { score -= 3.0; }

        // Streak dampening (relaxed)
        if recent_streak < -5 { score -= 5.0; }
        if recent_streak > 8 { score -= 3.0; }

        score = score.clamp(0.0, 100.0);
        scored.push((score, i));
    }

    // Sort by score descending
    scored.sort_by(|a, b| b.0.partial_cmp(&a.0).unwrap_or(std::cmp::Ordering::Equal));

    // Build top 2 signals for dashboard display
    let top_signals: Vec<TopSignal> = scored.iter().take(2).enumerate().map(|(rank, &(score, idx))| {
        let sig = &all_signals[idx];
        TopSignal {
            rank: rank + 1,
            strategy_name: sig.0.clone(),
            timeframe: sig.1.clone(),
            direction: sig.2.clone(),
            score,
            base_confidence: sig.3,
            reason: sig.4.clone(),
        }
    }).collect();

    let best_signal = if let Some(&(best_score, best_idx)) = scored.first() {
        // Note: MIN_CONFIDENCE check is done in the main function with volatility gate
        if best_score >= MIN_CONFIDENCE_HIGH_VOL { // Use lowest threshold here, real check is in main
            let sig = &all_signals[best_idx];
            let (strat, tf, dir, conf, reason, ind_summary, _tw) = sig;

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
                "เลือก {}/{} เพราะ: Score สูงสุด {:.0}% (Base Conf {:.0}% + TF Weighted Confluence {}/{} + Symbol WR {:.0}% + Session {} {:.0}% + Streak {}). เหตุผลกลยุทธ์: {} | {}",
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
    info!("⚡ [Pipeline v9] Scan completed in {}ms ({} signals from {} checks) ATR ratio: {:.2}",
        scan_time, total_signals, strategy::ALL_STRATEGIES.len() * TIMEFRAMES.len(), max_atr_ratio);

    ServerScanResult {
        strategies_scanned: strategy::ALL_STRATEGIES.len() * TIMEFRAMES.len(),
        timeframes_scanned: TIMEFRAMES.len(),
        total_signals,
        buy_signals: buy_count,
        sell_signals: sell_count,
        best_signal,
        top_signals,
        all_signals: all_scan_details,
        scan_time_ms: scan_time,
        atr_ratio: max_atr_ratio,
    }
}

// ──────────────────────────────────────────────
//  Build TF candle summaries (shared by both AI modes)
// ──────────────────────────────────────────────

async fn build_tf_candle_summaries(symbol: &str, db: &Database) -> String {
    let mut summaries = Vec::new();
    for &(tf_name, tf_min, count, _weight) in TIMEFRAMES {
        let candles = db.get_candles_for_strategy(symbol, tf_min, count).await;
        if candles.len() >= 5 {
            let recent = &candles[candles.len().saturating_sub(15)..];
            let ohlc: Vec<String> = recent.iter().map(|c| {
                format!("O:{:.5} H:{:.5} L:{:.5} C:{:.5}", c.open, c.high, c.low, c.close)
            }).collect();
            let ind = strategy::compute_indicators(&candles);
            summaries.push(format!(
                "=== {} ({} candles) ===\nRSI:{:.1} EMA9:{:.5} EMA21:{:.5} EMA50:{:.5}\nBB: {:.5}/{:.5}/{:.5}\n{}\n",
                tf_name, candles.len(), ind.rsi_14, ind.ema_9, ind.ema_21, ind.ema_50,
                ind.bb_upper, ind.bb_middle, ind.bb_lower,
                ohlc.join("\n")
            ));
        }
    }
    summaries.join("\n")
}

// ──────────────────────────────────────────────
//  Stage 2 (v9): Single AI Confirm
// ──────────────────────────────────────────────

#[allow(clippy::too_many_arguments)]
async fn ai_confirm_single(
    gemini_key: &str,
    model: &str,
    symbol: &str,
    signal: &BestSignal,
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
r#"You are a professional fund manager making a trading decision. This is a SINGLE-STEP validation. Respond REASONING in Thai only.

## Signal from Server Algorithm (10 strategies × 5 timeframes scanned)
- Symbol: {symbol}
- Direction: {dir}
- Strategy: {strat} (Timeframe: {tf})
- Server Score: {score:.0}% | TF Confluence: {tf_agree}/{tf_total}
- เหตุผลอัลกอริทึม: {reason}
- Indicators: {indicators}

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

## Validation Rules (เน้น APPROVE — ปฏิเสธเฉพาะกรณีอันตรายจริงๆ)
1. Signal ผ่าน Server Scan แล้ว (10 กลยุทธ์ × 5 TF) — ควร APPROVE เป็นค่าเริ่มต้น
2. CHECK indicators: REJECT ONLY if BUY with RSI>85 or SELL with RSI<15
3. CHECK history: REJECT ONLY if strategy WR < 25% on this symbol
4. CHECK news: REJECT ONLY if high-impact news within 15 minutes (NFP, FOMC, CPI)
5. CHECK portfolio: REJECT ONLY if drawdown > 15% or positions >= 8
6. CHECK streak: REJECT ONLY if 5+ consecutive losses
7. DEFAULT: APPROVE — when in doubt, always APPROVE

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
        indicators = signal.indicator_summary,
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
                "type": "agent_log_verbose", "symbol": symbol, "agent": "ai_confirm_v9",
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
            info!("☁️ [AI v9] {} {} → {} ({:.0}%) — {}", signal.direction, symbol,
                decision, confidence, reasoning);

            (approved, reasoning, confidence)
        }
        Err(e) => {
            warn!("☁️ [AI v9] Error: {} — Auto-approving", e);
            let _ = log_tx.send(serde_json::json!({
                "type": "agent_log", "symbol": symbol, "agent": "gemini_confirm", "status": "error",
                "message": format!("❌ Error: {} — Auto-approve", e)
            }).to_string());
            (true, format!("Auto-approve (API Error: {})", e), 60.0)
        }
    }
}

// ──────────────────────────────────────────────
//  Legacy Stage 2: Gemma 4 Validate (for 2-stage mode)
// ──────────────────────────────────────────────

async fn gemma_validate_v8(
    gemini_key: &str,
    symbol: &str,
    signal: &BestSignal,
    history: &HistoryData,
    _data_sources: &[String],
    log_tx: &broadcast::Sender<String>,
) -> (bool, String) {
    info!("🏠 [Gemma v8] Data Organizer: จัดเรียงข้อมูล {} {}", signal.direction, symbol);

    // Gemma 4 = Data Organizer: จัดเรียงข้อมูลจาก top 2 กลยุทธ์
    // ตัดข้อมูลที่ไม่จำเป็นออก ส่งเฉพาะสิ่งสำคัญให้ Gemini ตัดสินใจ
    let prompt = format!(
r#"คุณเป็น Data Organizer สำหรับระบบเทรด EA-24

หน้าที่: จัดเรียงข้อมูลให้กระชับที่สุด เพื่อส่งให้ AI ตัดสินใจเทรด
ตอบเป็นภาษาไทย สรุปสั้นๆ ไม่เกิน 80 คำ

## ข้อมูลจาก Server Scan
- คู่เงิน: {symbol}
- ทิศทาง: {dir}
- กลยุทธ์หลัก: {strat} ({tf}) — Score {score:.0}%
- TF ที่เห็นด้วย: {tf_agree}/{tf_total}
- Indicators: {ind}

## ประวัติ
- Win Rate {symbol}: {wr:.0}% ({trades} trades)
- กลยุทธ์ {strat} WR: {strat_wr:.0}%
- Session {session}: {session_wr:.0}%
- Streak: {streak}

## คำสั่ง
สรุปข้อมูลข้างต้นให้กระชับ เน้น:
1. ทิศทางและเหตุผลหลัก
2. จุดแข็ง/จุดอ่อนของสัญญาณนี้
3. ความเสี่ยงที่ควรระวัง

ตอบ:
SUMMARY: [สรุปข้อมูลกระชับ]"#,
        symbol = symbol,
        dir = signal.direction,
        strat = signal.strategy_name,
        tf = signal.best_timeframe,
        score = signal.score,
        tf_agree = signal.tf_confluence.agree_count,
        tf_total = signal.tf_confluence.total_tfs,
        ind = signal.indicator_summary,
        wr = history.symbol_win_rate,
        trades = history.symbol_total_trades,
        strat_wr = history.strategy_win_rate,
        session = history.session_name,
        session_wr = history.session_win_rate,
        streak = history.recent_streak,
    );

    match ai_engine::call_ai_pub(gemini_key, "gemma-4-31b-it", &prompt, 0.2, 150, false).await {
        Ok(response) => {
            let summary = response.trim().to_string();
            info!("🏠 [Gemma v8] Data organized for {} — {}", symbol, summary.chars().take(100).collect::<String>());
            let _ = log_tx.send(serde_json::json!({
                "type": "agent_log_verbose", "symbol": symbol, "agent": "gemma_filter_v8",
                "prompt": prompt, "response": response.clone()
            }).to_string());
            // Always APPROVE — Gemma is data organizer, not judge
            (true, summary)
        }
        Err(e) => {
            warn!("🏠 [Gemma v8] Error: {} — ส่งข้อมูลดิบให้ Gemini", e);
            // Fallback: ส่งสรุปข้อมูลดิบไปเลย
            let raw_summary = format!(
                "{} {} | {} ({}) | Score {:.0}% | WR {:.0}% | TF {}/{} | {} | Streak {}",
                signal.direction, symbol, signal.strategy_name, signal.best_timeframe,
                signal.score, history.symbol_win_rate,
                signal.tf_confluence.agree_count, signal.tf_confluence.total_tfs,
                history.session_name, history.recent_streak,
            );
            (true, raw_summary)
        }
    }
}

// ──────────────────────────────────────────────
//  Legacy Stage 3: Gemini Final Confirm (for 2-stage mode)
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

## Instructions (เน้น APPROVE — ปฏิเสธเฉพาะกรณีอันตรายจริงๆ)
1. Signal ผ่านมา 2 ด่านแล้ว (Server + Gemma) — ควร APPROVE เป็นค่าเริ่มต้น
2. REJECT ONLY if high-impact news within 15 minutes (NFP, FOMC, CPI level)
3. REJECT ONLY if drawdown > 15%
4. REJECT ONLY if open positions >= 8
5. REJECT ONLY if news STRONGLY and DIRECTLY conflicts with trade direction
6. DEFAULT: APPROVE with your confidence level — เมื่อไม่มีเหตุผลชัดเจนในการปฏิเสธ ให้ APPROVE

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
