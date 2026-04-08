// ──────────────────────────────────────────────
//  Smart Order Pipeline v8
//  7-Stage Decision Engine:
//    1. Data Collection
//    2. Weighted Strategy Evaluation (10 strategies)
//    2.5. Multi-Timeframe Alignment Check [NEW]
//    3. History-Aware Scoring
//    4. Gemma 4 Local Pre-Filter
//    5. Gemini Cloud Confirmation
//    6. ATR Volatility Gate + Risk Gate & Execution [ENHANCED]
// ──────────────────────────────────────────────

use log::info;
use tokio::sync::broadcast;

use crate::db::Database;
use crate::ai_engine;

use crate::strategy;

/// Pipeline context — all data needed for the decision
#[derive(Clone)]
pub struct PipelineContext {
    pub symbol: String,
    pub balance: f64,
    pub equity: f64,
    pub open_positions: usize,
    pub positions_detail: Vec<serde_json::Value>,
    pub gemini_key: String,
    pub gemini_model: String,
    pub tavily_key: String,
    pub ai_mode: String,
    pub disabled_agents: Vec<String>,
    pub global_news: Option<ai_engine::NewsResult>,
    pub job_config: serde_json::Value,
    pub discord_alert: bool,
    pub discord_channel_order: String,
}

/// Result from each pipeline stage
#[derive(Debug, Clone, serde::Serialize)]
pub struct StageResult {
    pub stage: String,
    pub passed: bool,
    pub message: String,
    pub confidence_delta: f64,
}

/// Final pipeline result
#[derive(Debug, Clone, serde::Serialize)]
pub struct PipelineResult {
    pub decision: String,
    pub confidence: f64,
    pub lot_size: f64,
    pub reasoning: String,
    pub stages: Vec<StageResult>,
    pub history_context: HistoryContext,
    pub gemma_verdict: String,
    pub gemini_verdict: String,
    pub multi_agent: Option<ai_engine::MultiAgentResult>,
}

#[derive(Debug, Clone, serde::Serialize)]
pub struct HistoryContext {
    pub symbol_win_rate: f64,
    pub symbol_total_trades: i64,
    pub strategy_win_rate: f64,
    pub session_name: String,
    pub session_win_rate: f64,
    pub recent_streak: i32,
    pub confidence_adjustment: f64,
}

// ──────────────────────────────────────────────
//  Main Pipeline Entry Point
// ──────────────────────────────────────────────

pub async fn run_smart_pipeline(
    ctx: &PipelineContext,
    db: &Database,
    log_tx: &broadcast::Sender<String>,
) -> PipelineResult {
    let sym = &ctx.symbol;
    let mut stages: Vec<StageResult> = Vec::new();

    info!("🔥 [Pipeline v8] Starting Smart Order Pipeline for {}...", sym);
    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": sym, "agent": "pipeline", "status": "running",
        "message": format!("🔥 [Pipeline v8] เริ่มวิเคราะห์ {} ด้วย 7-Stage Smart Pipeline...", sym)
    }).to_string());

    // ═══════════════════════════════════════════════
    //  Stage 1: Data Collection
    // ═══════════════════════════════════════════════
    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": sym, "agent": "pipeline", "status": "running",
        "message": "📊 Stage 1/6: รวบรวมข้อมูล Candles + ประวัติการเทรด..."
    }).to_string());

    let candles_m5 = db.get_candles_for_strategy(sym, 5, 50).await;
    let candles_m15 = db.get_candles_for_strategy(sym, 15, 50).await;
    let candles_h1 = db.get_candles_for_strategy(sym, 60, 50).await;
    let candles_h4 = db.get_candles_for_strategy(sym, 240, 30).await;

    let perf = db.get_symbol_performance(sym, 30).await;
    let recent_decisions = db.get_recent_decisions_context(sym, 10).await;
    let recent_streak = db.get_recent_streak(sym).await;

    let symbol_total_trades = perf["total_trades"].as_i64().unwrap_or(0);
    let symbol_win_rate = perf["win_rate"].as_f64().unwrap_or(50.0);

    stages.push(StageResult {
        stage: "Data Collection".into(),
        passed: true,
        message: format!("M5:{} M15:{} H1:{} H4:{} แท่ง | ประวัติ: {} ออเดอร์ (WR: {:.0}%) | Streak: {}",
            candles_m5.len(), candles_m15.len(), candles_h1.len(), candles_h4.len(),
            symbol_total_trades, symbol_win_rate, recent_streak),
        confidence_delta: 0.0,
    });

    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": sym, "agent": "pipeline", "status": "running",
        "message": format!("✅ Stage 1: ข้อมูลพร้อม — ประวัติ {} ออเดอร์, WR {:.0}%, Streak {}", symbol_total_trades, symbol_win_rate, recent_streak)
    }).to_string());

    // ═══════════════════════════════════════════════
    //  Stage 2: Strategy Evaluation (10 Strategies)
    // ═══════════════════════════════════════════════
    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": sym, "agent": "pipeline", "status": "running",
        "message": "🔢 Stage 2/7: Weighted Strategy Evaluation (10 กลยุทธ์, ระบบ Tier-weighted)..."
    }).to_string());

    // Use M15 as primary for strategy evaluation
    let primary_candles = if candles_m15.len() >= 50 { &candles_m15 }
        else if candles_m5.len() >= 50 { &candles_m5 }
        else if candles_h1.len() >= 50 { &candles_h1 }
        else { &candles_m5 };

    if primary_candles.len() < 20 {
        let msg = format!("⏭️ ข้อมูลแท่งเทียนไม่เพียงพอ ({} แท่ง) — ข้ามการวิเคราะห์", primary_candles.len());
        stages.push(StageResult { stage: "Strategy Evaluation".into(), passed: false, message: msg.clone(), confidence_delta: 0.0 });
        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": sym, "agent": "pipeline", "status": "done", "message": msg
        }).to_string());

        return PipelineResult {
            decision: "HOLD".into(), confidence: 0.0, lot_size: 0.0,
            reasoning: "ข้อมูล candle ไม่เพียงพอ".into(), stages,
            history_context: build_empty_history(),
            gemma_verdict: "SKIP".into(), gemini_verdict: "SKIP".into(),
            multi_agent: None,
        };
    }

    let indicators = strategy::compute_indicators(primary_candles);
    
    // Run all 10 strategies and collect signals
    let mut buy_signals: Vec<(String, f64)> = Vec::new();
    let mut sell_signals: Vec<(String, f64)> = Vec::new();
    let mut buy_weighted_score: f64 = 0.0;
    let mut sell_weighted_score: f64 = 0.0;
    let mut strategy_details = Vec::new();

    for &strat_name in strategy::ALL_STRATEGIES {
        let result = strategy::evaluate_strategy(strat_name, &indicators);
        match result.signal {
            strategy::Signal::Buy => {
                buy_signals.push((strat_name.to_string(), result.confidence));
                strategy_details.push(format!("✅ {}: BUY {:.0}%", strat_name, result.confidence));
            }
            strategy::Signal::Sell => {
                sell_signals.push((strat_name.to_string(), result.confidence));
                strategy_details.push(format!("✅ {}: SELL {:.0}%", strat_name, result.confidence));
            }
            strategy::Signal::None => {
                strategy_details.push(format!("⬜ {}: HOLD", strat_name));
            }
        }
    }

    // ─── Weighted Strategy Voting ───
    // Tier 1 (weight 1.5x): SMC, ICT — structure-based, most reliable
    // Tier 2 (weight 1.2x): Fibonacci, Trend Rider, Momentum Surge, Pullback Sniper
    // Tier 3 (weight 1.0x): Others
    let strategy_weights: std::collections::HashMap<&str, f64> = [
        ("SMC", 1.5), ("ICT", 1.5),
        ("Fibonacci", 1.2), ("Trend Rider", 1.2), ("Momentum Surge", 1.2), ("Pullback Sniper", 1.2),
        ("Session Sniper", 1.0), ("Bollinger Squeeze", 1.0), ("Reversal Catcher", 1.0), ("Fractal Breakout", 1.0),
    ].iter().cloned().collect();

    for &strat_name in strategy::ALL_STRATEGIES {
        let result = strategy::evaluate_strategy(strat_name, &indicators);
        let w = *strategy_weights.get(strat_name).unwrap_or(&1.0);
        match result.signal {
            strategy::Signal::Buy => {
                buy_signals.push((strat_name.to_string(), result.confidence));
                buy_weighted_score += result.confidence * w;
                strategy_details.push(format!("✅ {}(x{:.1}): BUY {:.0}%", strat_name, w, result.confidence));
            }
            strategy::Signal::Sell => {
                sell_signals.push((strat_name.to_string(), result.confidence));
                sell_weighted_score += result.confidence * w;
                strategy_details.push(format!("✅ {}(x{:.1}): SELL {:.0}%", strat_name, w, result.confidence));
            }
            strategy::Signal::None => {
                strategy_details.push(format!("⬜ {}: HOLD", strat_name));
            }
        }
    }

    let buy_avg_conf = if !buy_signals.is_empty() {
        buy_signals.iter().map(|s| s.1).sum::<f64>() / buy_signals.len() as f64
    } else { 0.0 };
    let sell_avg_conf = if !sell_signals.is_empty() {
        sell_signals.iter().map(|s| s.1).sum::<f64>() / sell_signals.len() as f64
    } else { 0.0 };

    // Dominant direction: weighted score must be ≥1.2x of opponent (stronger gate than v7)
    let (base_direction, base_confidence, top_strategy) = if buy_weighted_score >= sell_weighted_score * 1.2 && buy_avg_conf > 55.0 {
        let top = buy_signals.iter().max_by(|a, b| a.1.partial_cmp(&b.1).unwrap()).unwrap();
        ("BUY".to_string(), buy_avg_conf, top.0.clone())
    } else if sell_weighted_score >= buy_weighted_score * 1.2 && sell_avg_conf > 55.0 {
        let top = sell_signals.iter().max_by(|a, b| a.1.partial_cmp(&b.1).unwrap()).unwrap();
        ("SELL".to_string(), sell_avg_conf, top.0.clone())
    } else {
        stages.push(StageResult {
            stage: "Strategy Evaluation".into(), passed: false,
            message: format!("ไม่มี dominant direction (BUY:{} SELL:{}, WScore B:{:.0} S:{:.0})",
                buy_signals.len(), sell_signals.len(), buy_weighted_score, sell_weighted_score),
            confidence_delta: 0.0,
        });
        let msg = format!("⏭️ ไม่มีสัญญาณชัดเจน | BUY:{} SELL:{} | WScore B:{:.0} S:{:.0}",
            buy_signals.len(), sell_signals.len(), buy_weighted_score, sell_weighted_score);
        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": sym, "agent": "pipeline", "status": "done", "message": msg
        }).to_string());
        return PipelineResult {
            decision: "HOLD".into(), confidence: 0.0, lot_size: 0.0,
            reasoning: "ไม่มี weighted strategy signal ชัดเจน".into(), stages,
            history_context: build_empty_history(),
            gemma_verdict: "SKIP".into(), gemini_verdict: "SKIP".into(),
            multi_agent: None,
        };
    };

    stages.push(StageResult {
        stage: "Strategy Evaluation".into(), passed: true,
        message: format!("{} ({:.0}%) Weighted B:{:.0} S:{:.0} — {} signals | Top: {}",
            base_direction, base_confidence, buy_weighted_score, sell_weighted_score,
            if base_direction == "BUY" { buy_signals.len() } else { sell_signals.len() }, top_strategy),
        confidence_delta: 0.0,
    });

    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": sym, "agent": "pipeline", "status": "running",
        "message": format!("✅ Stage 2: {} ({:.0}%) [WScore B:{:.0} S:{:.0}] — {} สัญญาณ | Top: {}\n{}",
            base_direction, base_confidence, buy_weighted_score, sell_weighted_score,
            if base_direction == "BUY" { buy_signals.len() } else { sell_signals.len() },
            top_strategy, strategy_details.join("\n"))
    }).to_string());

    // ═══════════════════════════════════════════════
    //  Stage 2.5: Multi-Timeframe Trend Alignment [NEW]
    // ═══════════════════════════════════════════════
    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": sym, "agent": "pipeline", "status": "running",
        "message": "📐 Stage 2.5/7: Multi-Timeframe Trend Alignment (H1/H4)..."
    }).to_string());

    let mtf_adj = compute_mtf_alignment(&base_direction, &candles_h1, &candles_h4);
    let mtf_adjusted_confidence = (base_confidence + mtf_adj.adjustment).clamp(0.0, 100.0);

    stages.push(StageResult {
        stage: "MTF Alignment".into(),
        passed: mtf_adj.adjustment >= 0.0,
        message: format!("H1:{} H4:{} → δ{:+.0} ({:.0}%→{:.0}%)",
            mtf_adj.h1_trend, mtf_adj.h4_trend, mtf_adj.adjustment, base_confidence, mtf_adjusted_confidence),
        confidence_delta: mtf_adj.adjustment,
    });

    if mtf_adj.adjustment <= -15.0 {
        let msg = format!("⏭️ MTF Conflict รุนแรง H1:{} H4:{} vs {} — ข้าม",
            mtf_adj.h1_trend, mtf_adj.h4_trend, base_direction);
        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": sym, "agent": "pipeline", "status": "done", "message": msg
        }).to_string());
        return PipelineResult {
            decision: "HOLD".into(), confidence: mtf_adjusted_confidence, lot_size: 0.0,
            reasoning: msg, stages, history_context: build_empty_history(),
            gemma_verdict: "SKIP".into(), gemini_verdict: "SKIP".into(),
            multi_agent: None,
        };
    }

    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": sym, "agent": "pipeline", "status": "running",
        "message": format!("📐 Stage 2.5: MTF H1:{} H4:{} → Confidence δ{:+.0} ({:.0}%→{:.0}%)",
            mtf_adj.h1_trend, mtf_adj.h4_trend, mtf_adj.adjustment, base_confidence, mtf_adjusted_confidence)
    }).to_string());

    let base_confidence = mtf_adjusted_confidence;

    // ═══════════════════════════════════════════════
    //  Stage 3: History-Aware Scoring
    // ═══════════════════════════════════════════════
    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": sym, "agent": "pipeline", "status": "running",
        "message": "📜 Stage 3/7: ปรับ Confidence ตามประวัติการเทรด..."
    }).to_string());

    let (strategy_wr, strategy_count) = db.get_strategy_performance(sym, &ctx.ai_mode, 30).await;

    // Detect current session
    let utc_hour = chrono::Utc::now().hour() as i32;
    let (session_name, session_start, session_end) = if utc_hour >= 0 && utc_hour < 8 {
        ("Asia", 0, 8)
    } else if utc_hour >= 8 && utc_hour < 16 {
        ("London", 8, 16)
    } else {
        ("New York", 16, 24)
    };
    let session_wr = db.get_session_performance(sym, session_start, session_end, 30).await;

    let confidence_adj = adjust_confidence_from_history(
        base_confidence, symbol_win_rate, strategy_wr,
        session_wr, recent_streak, symbol_total_trades, strategy_count,
    );
    let adjusted_confidence = (base_confidence + confidence_adj).clamp(0.0, 100.0);

    let history_ctx = HistoryContext {
        symbol_win_rate,
        symbol_total_trades,
        strategy_win_rate: strategy_wr,
        session_name: session_name.to_string(),
        session_win_rate: session_wr,
        recent_streak,
        confidence_adjustment: confidence_adj,
    };

    stages.push(StageResult {
        stage: "History-Aware Scoring".into(),
        passed: adjusted_confidence >= 55.0,
        message: format!("Base {:.0}% → Adjusted {:.0}% (δ{:+.0}) | Symbol WR:{:.0}% Strategy WR:{:.0}% Session({}): {:.0}% Streak:{}",
            base_confidence, adjusted_confidence, confidence_adj,
            symbol_win_rate, strategy_wr, session_name, session_wr, recent_streak),
        confidence_delta: confidence_adj,
    });

    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": sym, "agent": "pipeline", "status": "running",
        "message": format!("📜 Stage 3: Confidence {:.0}% → {:.0}% (δ{:+.0})\n  Symbol WR: {:.0}% ({} trades)\n  Strategy WR: {:.0}% ({} trades)\n  Session {}: {:.0}%\n  Streak: {}",
            base_confidence, adjusted_confidence, confidence_adj,
            symbol_win_rate, symbol_total_trades, strategy_wr, strategy_count,
            session_name, session_wr, recent_streak)
    }).to_string());

    // Check threshold
    let min_confidence = ctx.job_config["min_confidence"].as_f64().unwrap_or(55.0);
    if adjusted_confidence < min_confidence {
        let msg = format!("⏭️ Confidence {:.0}% ต่ำกว่า threshold {:.0}% — ข้าม", adjusted_confidence, min_confidence);
        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": sym, "agent": "pipeline", "status": "done", "message": msg
        }).to_string());

        if ctx.discord_alert && !ctx.discord_channel_order.is_empty() {
            crate::discord_bot::send_to_channel(&ctx.discord_channel_order, &format!(
                "⏭️ <b>Pipeline Skip</b>\n\n📊 {} {}\n🎯 Confidence: {:.0}% < {:.0}%\n📜 History WR: {:.0}%\n⚡ Streak: {}",
                base_direction, sym, adjusted_confidence, min_confidence, symbol_win_rate, recent_streak
            )).await;
        }

        return PipelineResult {
            decision: "HOLD".into(), confidence: adjusted_confidence, lot_size: 0.0,
            reasoning: format!("Confidence {:.0}% ต่ำกว่า threshold {:.0}%", adjusted_confidence, min_confidence),
            stages, history_context: history_ctx,
            gemma_verdict: "SKIP".into(), gemini_verdict: "SKIP".into(),
            multi_agent: None,
        };
    }

    // ═══════════════════════════════════════════════
    //  Stage 4: Gemma 4 Local Pre-Filter (Free, Fast)
    // ═══════════════════════════════════════════════
    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": sym, "agent": "pipeline", "status": "running",
        "message": "🏠 Stage 4/7: Gemma 4 Pre-Filter..."
    }).to_string());

    let history_summary = format!(
        "Last 30d: {} trades, WR {:.0}%, AvgPnL ${:.2}, Streak {}",
        symbol_total_trades, symbol_win_rate,
        perf["avg_pnl"].as_f64().unwrap_or(0.0), recent_streak
    );

    let recent_decisions_str = recent_decisions.iter().take(5).map(|d| {
        format!("{} conf:{:.0}% → {} (${:.2})",
            d["direction"].as_str().unwrap_or("?"),
            d["confidence"].as_f64().unwrap_or(0.0),
            d["outcome"].as_str().unwrap_or("?"),
            d["pnl"].as_f64().unwrap_or(0.0))
    }).collect::<Vec<_>>().join(" | ");

    let (gemma_approved, gemma_reason) = ai_engine::gemma_quick_validate(
        &ctx.gemini_key, sym, &base_direction, &indicators, &history_summary, &recent_decisions_str, log_tx
    ).await;

    stages.push(StageResult {
        stage: "Gemma Pre-Filter".into(),
        passed: gemma_approved,
        message: format!("{} — {}", if gemma_approved { "✅ APPROVE" } else { "❌ REJECT" }, gemma_reason),
        confidence_delta: 0.0,
    });

    if !gemma_approved {
        let msg = format!("🏠 Gemma REJECT {} {} — {}", base_direction, sym, gemma_reason);
        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": sym, "agent": "pipeline", "status": "done", "message": msg
        }).to_string());

        if ctx.discord_alert && !ctx.discord_channel_order.is_empty() {
            crate::discord_bot::send_to_channel(&ctx.discord_channel_order, &format!(
                "🏠 <b>Gemma Reject</b>\n\n📊 {} {}\n🎯 Confidence: {:.0}%\n❌ {}", 
                base_direction, sym, adjusted_confidence, gemma_reason
            )).await;
        }

        return PipelineResult {
            decision: "HOLD".into(), confidence: adjusted_confidence, lot_size: 0.0,
            reasoning: format!("Gemma rejected: {}", gemma_reason), stages,
            history_context: history_ctx,
            gemma_verdict: format!("REJECT: {}", gemma_reason),
            gemini_verdict: "SKIP".into(),
            multi_agent: None,
        };
    }

    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": sym, "agent": "pipeline", "status": "running",
        "message": format!("✅ Stage 4: Gemma APPROVE — {}", gemma_reason)
    }).to_string());

    // ═══════════════════════════════════════════════
    //  Stage 5: Gemini Cloud Confirmation (Full Analysis)
    // ═══════════════════════════════════════════════
    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": sym, "agent": "pipeline", "status": "running",
        "message": "☁️ Stage 5/7: Gemini Multi-Agent Analysis..."
    }).to_string());

    let multi_tf_candles = vec![
        ("M5", candles_m5.clone()),
        ("M15", candles_m15.clone()),
        ("H1", candles_h1.clone()),
        ("H4", candles_h4.clone()),
    ];

    let multi_agent_result = ai_engine::run_all_agents_multi_tf(
        &ctx.gemini_key, &ctx.gemini_model, &ctx.tavily_key,
        sym, &multi_tf_candles,
        ctx.balance, ctx.equity, ctx.open_positions, 5, 10.0, false,
        &ctx.ai_mode, &ctx.disabled_agents,
        ctx.global_news.clone(),
        log_tx,
    ).await;

    let gemini_decision = &multi_agent_result.final_decision;
    let gemini_confidence = multi_agent_result.confidence;
    let gemini_reasoning = &multi_agent_result.reasoning;

    // Gemini must agree with the direction
    let gemini_agrees = (gemini_decision == "BUY" && base_direction == "BUY")
        || (gemini_decision == "SELL" && base_direction == "SELL");

    stages.push(StageResult {
        stage: "Gemini Confirmation".into(),
        passed: gemini_agrees,
        message: format!("{} ({:.0}%) — {}", gemini_decision, gemini_confidence,
            if gemini_agrees { "✅ สอดคล้อง" } else { "❌ ขัดกัน" }),
        confidence_delta: 0.0,
    });

    if !gemini_agrees {
        let msg = format!("☁️ Gemini ไม่เห็นด้วย: {} vs Pipeline {} — {}", gemini_decision, base_direction, gemini_reasoning);
        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": sym, "agent": "pipeline", "status": "done", "message": msg
        }).to_string());

        if ctx.discord_alert && !ctx.discord_channel_order.is_empty() {
            crate::discord_bot::send_to_channel(&ctx.discord_channel_order, &format!(
                "☁️ <b>Gemini Disagree</b>\n\n📊 Pipeline: {} vs Gemini: {}\n🎯 {} ({:.0}%)\n❌ {}",
                base_direction, gemini_decision, sym, gemini_confidence, gemini_reasoning
            )).await;
        }

        return PipelineResult {
            decision: "HOLD".into(), confidence: adjusted_confidence, lot_size: 0.0,
            reasoning: format!("Gemini ไม่เห็นด้วย: {} (Pipeline ต้องการ {})", gemini_decision, base_direction),
            stages, history_context: history_ctx,
            gemma_verdict: format!("APPROVE: {}", gemma_reason),
            gemini_verdict: format!("{}: {}", gemini_decision, gemini_reasoning),
            multi_agent: Some(multi_agent_result),
        };
    }

    // Blend confidences: weighted average (pipeline 40% + gemini 60%)
    let final_confidence = (adjusted_confidence * 0.4 + gemini_confidence * 0.6).clamp(0.0, 100.0);

    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": sym, "agent": "pipeline", "status": "running",
        "message": format!("✅ Stage 5: Gemini {} ({:.0}%) — Final blend: {:.0}%", gemini_decision, gemini_confidence, final_confidence)
    }).to_string());

    // ═══════════════════════════════════════════════
    //  Stage 6: Final Risk Gate
    // ═══════════════════════════════════════════════
    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": sym, "agent": "pipeline", "status": "running",
        "message": "🛡️ Stage 6/7: ATR Volatility Gate + Risk Gate + News & Correlation..."
    }).to_string());

    // ─── ATR Volatility Gate [NEW in v8] ───
    // Reuse indicators already computed in Stage 2 (from primary_candles)
    let atr_ratio = indicators.atr_ratio;
    let (atr_blocked, atr_reason) = if atr_ratio < 0.5 {
        (true, format!("ตลาดนิ่ง/Sideways (ATR ratio={:.2} < 0.5) — ไม่เหมาะออกไม้", atr_ratio))
    } else if atr_ratio > 2.5 {
        (true, format!("Volatility spike (ATR ratio={:.2} > 2.5) — อาจเป็น News หรือ High-spread", atr_ratio))
    } else {
        (false, format!("ATR ratio={:.2} อยู่ในช่วงปกติ", atr_ratio))
    };

    if atr_blocked {
        stages.push(StageResult {
            stage: "ATR Volatility Gate".into(), passed: false,
            message: format!("🚫 {}", atr_reason),
            confidence_delta: 0.0,
        });
        let msg = format!("🚫 ATR Gate Block — {}", atr_reason);
        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": sym, "agent": "pipeline", "status": "done", "message": msg
        }).to_string());
        if ctx.discord_alert && !ctx.discord_channel_order.is_empty() {
            crate::discord_bot::send_to_channel(&ctx.discord_channel_order, &format!(
                "🚫 <b>ATR Volatility Gate</b>\n\n📊 {} {}\n📉 {}",
                base_direction, sym, atr_reason
            )).await;
        }
        return PipelineResult {
            decision: "HOLD".into(), confidence: final_confidence, lot_size: 0.0,
            reasoning: format!("ATR Volatility Gate: {}", atr_reason), stages, history_context: history_ctx,
            gemma_verdict: format!("APPROVE: {}", gemma_reason),
            gemini_verdict: format!("{}: {}", gemini_decision, gemini_reasoning),
            multi_agent: Some(multi_agent_result),
        };
    }

    stages.push(StageResult {
        stage: "ATR Volatility Gate".into(), passed: true,
        message: format!("✅ {}", atr_reason),
        confidence_delta: 0.0,
    });

    // News avoidance
    let news_warnings = ai_engine::check_upcoming_high_impact_news(log_tx).await;
    let sym_upper = sym.to_uppercase();
    let relevant_news: Vec<_> = news_warnings.iter().filter(|w| {
        let country = w.event_country.to_uppercase();
        match country.as_str() {
            "USD" => sym_upper.contains("USD") || sym_upper.contains("XAU") || sym_upper.contains("BTC"),
            "EUR" => sym_upper.contains("EUR"),
            "GBP" => sym_upper.contains("GBP"),
            "JPY" => sym_upper.contains("JPY"),
            "AUD" => sym_upper.contains("AUD"),
            "CAD" => sym_upper.contains("CAD"),
            "CHF" => sym_upper.contains("CHF"),
            _ => false,
        }
    }).collect();

    if !relevant_news.is_empty() {
        let event_name = &relevant_news[0].event_title;
        let mins = relevant_news[0].minutes_until;
        let msg = format!("📅 ข่าวสำคัญ {} ในอีก {} นาที — ข้ามการเทรด", event_name, mins);
        stages.push(StageResult { stage: "Risk Gate".into(), passed: false, message: msg.clone(), confidence_delta: 0.0 });

        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": sym, "agent": "pipeline", "status": "done", "message": msg
        }).to_string());

        if ctx.discord_alert && !ctx.discord_channel_order.is_empty() {
            crate::discord_bot::send_to_channel(&ctx.discord_channel_order, &format!(
                "📅 <b>News Avoidance</b>\n\n📊 {} {}\n📰 {} ในอีก {} นาที\n🛑 ไม่เปิดออเดอร์ใหม่",
                base_direction, sym, event_name, mins
            )).await;
        }

        return PipelineResult {
            decision: "HOLD".into(), confidence: final_confidence, lot_size: 0.0,
            reasoning: msg, stages, history_context: history_ctx,
            gemma_verdict: format!("APPROVE: {}", gemma_reason),
            gemini_verdict: format!("{}: {}", gemini_decision, gemini_reasoning),
            multi_agent: Some(multi_agent_result),
        };
    }

    // Correlation check
    let correlation = ai_engine::run_correlation_check(
        &[(sym.clone(), base_direction.clone(), 0.01)],
        &ctx.positions_detail,
        log_tx,
    );

    if correlation.should_reduce {
        let warn_msg = correlation.warnings.join(", ");
        stages.push(StageResult {
            stage: "Risk Gate".into(), passed: false,
            message: format!("🔗 Over-exposure detected: {}", warn_msg),
            confidence_delta: -10.0,
        });
        // Don't block, just reduce confidence
        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": sym, "agent": "pipeline", "status": "running",
            "message": format!("⚠️ Correlation warning: {} — ลด confidence", warn_msg)
        }).to_string());
    }

    // Dynamic 5-Level Lot Scaling (v8)
    let fallback_lot = ctx.job_config["lot_size"].as_f64().unwrap_or(0.01);
    // Streak penalty: ลด lot เมื่อ losing streak
    let streak_penalty = if recent_streak <= -3 { 0.5 } else { 1.0 };
    let scaled_lot = if ctx.job_config["lot_scale"].as_bool().unwrap_or(false) {
        let scale = if final_confidence >= 90.0 && recent_streak >= 0 { 3.0 }
            else if final_confidence >= 80.0 { 2.0 }
            else if final_confidence >= 70.0 { 1.5 }
            else if final_confidence >= 60.0 { 1.0 }
            else { 0.5 }; // low confidence → reduce lot
        (fallback_lot * scale * streak_penalty).max(0.01)
    } else {
        (fallback_lot * streak_penalty).max(0.01)
    };

    stages.push(StageResult {
        stage: "Risk Gate".into(), passed: true,
        message: format!("✅ ผ่านทุกเงื่อนไข — {} {:.0}% lot: {:.2}", base_direction, final_confidence, scaled_lot),
        confidence_delta: 0.0,
    });

    // Build stage summary for Telegram
    let stage_summary = stages.iter().enumerate().map(|(i, s)| {
        format!("{}. {} {} — {}", i + 1, if s.passed { "✅" } else { "❌" }, s.stage, s.message)
    }).collect::<Vec<_>>().join("\n");

    // Final Telegram alert for successful pipeline
    if ctx.discord_alert && !ctx.discord_channel_order.is_empty() {
        crate::discord_bot::send_to_channel(&ctx.discord_channel_order, &format!(
            "🔥 <b>Pipeline v8 — Signal Ready</b>\n\n\
            📊 <b>{} {}</b>\n\
            🎯 Confidence: <b>{:.0}%</b>\n\
            💰 Lot: {:.2}\n\n\
            📜 <b>ประวัติ:</b>\n\
            Win Rate: {:.0}% ({} trades)\n\
            Session {}: {:.0}%\n\
            Streak: {}\n\n\
            🏠 Gemma: {}\n\
            ☁️ Gemini: {} ({:.0}%)\n\n\
            <b>Pipeline Stages:</b>\n{}\n\n\
            📝 {}",
            base_direction, sym, final_confidence, scaled_lot,
            symbol_win_rate, symbol_total_trades,
            session_name, session_wr, recent_streak,
            gemma_reason, gemini_decision, gemini_confidence,
            stage_summary, gemini_reasoning
        )).await;
    }

    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": sym, "agent": "pipeline", "status": "done",
        "message": format!("🏁 Pipeline v8 สำเร็จ: {} {} ({:.0}%) lot: {:.2}\n{}", 
            base_direction, sym, final_confidence, scaled_lot, stage_summary)
    }).to_string());

    info!("🔥 [Pipeline v8] Final: {} {} → {} ({:.0}%) lot: {:.2}", sym, base_direction, base_direction, final_confidence, scaled_lot);

    PipelineResult {
        decision: base_direction,
        confidence: final_confidence,
        lot_size: scaled_lot,
        reasoning: format!("{}\n\nPipeline Stages:\n{}", gemini_reasoning, stage_summary),
        stages,
        history_context: history_ctx,
        gemma_verdict: format!("APPROVE: {}", gemma_reason),
        gemini_verdict: format!("{}: {}", gemini_decision, gemini_reasoning),
        multi_agent: Some(multi_agent_result),
    }
}

// ──────────────────────────────────────────────
//  Multi-Timeframe Alignment [NEW in v8]
// ──────────────────────────────────────────────

struct MtfAlignment {
    h1_trend: String,
    h4_trend: String,
    adjustment: f64,
}

fn infer_trend(candles: &[crate::strategy::Candle]) -> &'static str {
    if candles.len() < 21 { return "UNKNOWN"; }
    let closes: Vec<f64> = candles.iter().map(|c| c.close).collect();
    let n = closes.len();
    // Quick EMA9 vs EMA21 from last close values
    let ema9_sum: f64 = closes[n.saturating_sub(9)..].iter().sum::<f64>() / 9.0_f64.min(n as f64);
    let ema21_sum: f64 = closes[n.saturating_sub(21)..].iter().sum::<f64>() / 21.0_f64.min(n as f64);
    if ema9_sum > ema21_sum * 1.0001 { "BULL" }
    else if ema9_sum < ema21_sum * 0.9999 { "BEAR" }
    else { "NEUTRAL" }
}

fn compute_mtf_alignment(
    direction: &str,
    candles_h1: &[crate::strategy::Candle],
    candles_h4: &[crate::strategy::Candle],
) -> MtfAlignment {
    let h1_trend = infer_trend(candles_h1);
    let h4_trend = infer_trend(candles_h4);

    let h1_align = match (direction, h1_trend) {
        ("BUY", "BULL") | ("SELL", "BEAR") => true,
        ("BUY", "BEAR") | ("SELL", "BULL") => false,
        _ => true, // NEUTRAL or UNKNOWN — don't penalize
    };
    let h4_align = match (direction, h4_trend) {
        ("BUY", "BULL") | ("SELL", "BEAR") => true,
        ("BUY", "BEAR") | ("SELL", "BULL") => false,
        _ => true,
    };

    let adjustment = match (h1_align, h4_align) {
        (true, true)   =>  10.0,  // Both align — boost
        (true, false)  =>  -10.0, // H4 conflicts — moderate penalty
        (false, true)  =>  -5.0,  // H1 conflicts — small penalty
        (false, false) =>  -20.0, // Both conflict — heavy penalty (will trigger HOLD)
    };

    MtfAlignment {
        h1_trend: h1_trend.to_string(),
        h4_trend: h4_trend.to_string(),
        adjustment,
    }
}

// ──────────────────────────────────────────────
//  History-Aware Confidence Adjustment Algorithm
// ──────────────────────────────────────────────

fn adjust_confidence_from_history(
    _base_confidence: f64,
    symbol_win_rate: f64,
    strategy_win_rate: f64,
    session_win_rate: f64,
    recent_streak: i32,
    symbol_total_trades: i64,
    strategy_total_trades: i64,
) -> f64 {
    let mut adjustment = 0.0;

    // Only adjust if we have enough data (min 10 trades)
    if symbol_total_trades >= 10 {
        // Symbol mastery bonus/penalty (+/- 15%)
        if symbol_win_rate > 60.0 { adjustment += (symbol_win_rate - 50.0) * 0.3; }
        else if symbol_win_rate < 40.0 { adjustment -= (50.0 - symbol_win_rate) * 0.5; }
    }

    if strategy_total_trades >= 10 {
        // Strategy effectiveness (+/- 10%)
        if strategy_win_rate > 60.0 { adjustment += (strategy_win_rate - 50.0) * 0.2; }
        else if strategy_win_rate < 40.0 { adjustment -= (50.0 - strategy_win_rate) * 0.3; }
    }

    // Session awareness (+/- 5%)
    if session_win_rate > 55.0 { adjustment += 3.0; }
    else if session_win_rate < 35.0 { adjustment -= 5.0; }

    // Win/Loss streak dampening
    if recent_streak < -3 { adjustment -= 10.0; }   // 3+ consecutive losses → cool down
    if recent_streak > 5 { adjustment -= 5.0; }      // overtrade protection after win streak

    adjustment.clamp(-20.0, 20.0)
}

fn build_empty_history() -> HistoryContext {
    HistoryContext {
        symbol_win_rate: 50.0, symbol_total_trades: 0,
        strategy_win_rate: 50.0, session_name: "Unknown".into(),
        session_win_rate: 50.0, recent_streak: 0,
        confidence_adjustment: 0.0,
    }
}

use chrono::Timelike;
