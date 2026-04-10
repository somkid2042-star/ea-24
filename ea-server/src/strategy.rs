// ──────────────────────────────────────────────
//  Strategy Engine — Server-side signal generator
//  10 strategies + Auto mode
//  Calculates indicators from DB tick data,
//  evaluates strategies, sends open_trade commands
// ──────────────────────────────────────────────

use std::collections::HashMap;
use std::sync::Arc;
use log::{info, warn, error};
use tokio::sync::{broadcast, RwLock};
use chrono::Timelike;

use crate::db::Database;
use crate::EaState;

/// Candle data aggregated from ticks
#[derive(Debug, Clone)]
#[allow(dead_code)]
pub struct Candle {
    pub time: i64,
    pub open: f64,
    pub high: f64,
    pub low: f64,
    pub close: f64,
}

/// Extended indicator values for a symbol
#[derive(Debug, Clone, Default)]
#[allow(dead_code)]
pub struct Indicators {
    // Core
    pub rsi_14: f64,
    pub ema_9: f64,
    pub ema_21: f64,
    pub ema_50: f64,
    pub ema_200: f64,
    pub bb_upper: f64,
    pub bb_middle: f64,
    pub bb_lower: f64,
    pub prev_ema_9: f64,
    pub prev_ema_21: f64,
    pub prev_close: f64,
    pub current_close: f64,
    pub current_high: f64,
    pub current_low: f64,
    pub current_open: f64,
    // Fibonacci
    pub fib_high: f64,
    pub fib_low: f64,
    pub fib_382: f64,
    pub fib_500: f64,
    pub fib_618: f64,
    // SMC / ICT
    pub swing_high: f64,
    pub swing_low: f64,
    pub prev_swing_high: f64,
    pub prev_swing_low: f64,
    pub order_block_bull: f64,
    pub order_block_bear: f64,
    pub fair_value_gap_bull: bool,
    pub fair_value_gap_bear: bool,
    // Momentum
    pub rsi_prev: f64,
    pub momentum: f64,         // rate of change %
    pub atr: f64,
    pub candle_body_ratio: f64, // body / range  (displacement measure)
    // Session
    pub asian_high: f64,
    pub asian_low: f64,
    // Volatility
    pub atr_20_avg: f64,     // average ATR over last 20 bars
    pub atr_ratio: f64,      // atr / atr_20_avg — >1 = expanding, <1 = contracting
}

/// Signal type
#[derive(Debug, Clone, PartialEq)]
pub enum Signal {
    Buy,
    Sell,
    None,
}

/// Strategy evaluation result with confidence score
#[derive(Debug, Clone)]
pub struct StrategyResult {
    pub signal: Signal,
    pub reason: String,
    pub confidence: f64,         // 0-100
    pub indicator_summary: String, // compact summary for AI
    pub suggested_sl_atr: f64,   // SL in price distance (1.5 × ATR)
    pub suggested_tp_atr: f64,   // TP in price distance (2.0 × ATR)
}

impl StrategyResult {
    fn none() -> Self {
        Self {
            signal: Signal::None,
            reason: String::new(),
            confidence: 0.0,
            indicator_summary: String::new(),
            suggested_sl_atr: 0.0,
            suggested_tp_atr: 0.0,
        }
    }

    fn buy(reason: String, confidence: f64, ind: &Indicators) -> Self {
        Self {
            signal: Signal::Buy,
            reason,
            confidence,
            indicator_summary: generate_indicator_summary(ind),
            suggested_sl_atr: ind.atr * 1.5,
            suggested_tp_atr: ind.atr * 2.5,
        }
    }

    fn sell(reason: String, confidence: f64, ind: &Indicators) -> Self {
        Self {
            signal: Signal::Sell,
            reason,
            confidence,
            indicator_summary: generate_indicator_summary(ind),
            suggested_sl_atr: ind.atr * 1.5,
            suggested_tp_atr: ind.atr * 2.5,
        }
    }
}

/// Generate compact indicator summary for AI context
fn generate_indicator_summary(ind: &Indicators) -> String {
    let trend = if ind.ema_9 > ind.ema_21 && ind.ema_21 > ind.ema_50 {
        "BULL_STACK"
    } else if ind.ema_9 < ind.ema_21 && ind.ema_21 < ind.ema_50 {
        "BEAR_STACK"
    } else if ind.ema_9 > ind.ema_21 {
        "MILD_BULL"
    } else {
        "MILD_BEAR"
    };

    let bb_pos = if ind.bb_upper > ind.bb_lower {
        ((ind.current_close - ind.bb_lower) / (ind.bb_upper - ind.bb_lower) * 100.0) as i32
    } else { 50 };

    format!(
        "RSI={:.1} RSI_prev={:.1} | EMA9={:.5} EMA21={:.5} EMA50={:.5} Trend={} | BB_pos={}% BW={:.4} | ATR={:.5} Mom={:.2}% | Body={:.0}% | SwH={:.5} SwL={:.5}",
        ind.rsi_14, ind.rsi_prev,
        ind.ema_9, ind.ema_21, ind.ema_50, trend,
        bb_pos, ind.bb_upper - ind.bb_lower,
        ind.atr, ind.momentum,
        ind.candle_body_ratio * 100.0,
        ind.swing_high, ind.swing_low,
    )
}

/// All strategy names
pub const ALL_STRATEGIES: &[&str] = &[
    "SMC", "ICT", "Session Sniper", "Fibonacci", "Trend Rider",
    "Pullback Sniper", "Bollinger Squeeze", "Momentum Surge",
    "Reversal Catcher", "Fractal Breakout", "Scalper Pro", "Grid Master"
];

/// Per-symbol cooldown tracker
struct CooldownTracker {
    last_signal_time: HashMap<String, std::time::Instant>,
}

impl CooldownTracker {
    fn new() -> Self {
        Self { last_signal_time: HashMap::new() }
    }

    fn can_trade(&self, key: &str, cooldown_secs: u64) -> bool {
        match self.last_signal_time.get(key) {
            Some(t) => t.elapsed().as_secs() >= cooldown_secs,
            None => true,
        }
    }

    fn mark(&mut self, key: &str) {
        self.last_signal_time.insert(key.to_string(), std::time::Instant::now());
    }
}

// ──────────────────────────────────────────────
//  Indicator Calculations
// ──────────────────────────────────────────────

fn calc_ema(data: &[f64], period: usize) -> Vec<f64> {
    if data.len() < period || period == 0 {
        return vec![0.0; data.len()];
    }
    let mut ema = vec![0.0; data.len()];
    let sma: f64 = data[..period].iter().sum::<f64>() / period as f64;
    ema[period - 1] = sma;
    let k = 2.0 / (period as f64 + 1.0);
    for i in period..data.len() {
        ema[i] = data[i] * k + ema[i - 1] * (1.0 - k);
    }
    ema
}

fn calc_rsi(data: &[f64], period: usize) -> f64 {
    if data.len() < period + 1 {
        return 50.0;
    }
    let mut gains = 0.0;
    let mut losses = 0.0;
    let start = data.len() - period - 1;
    for i in (start + 1)..data.len() {
        let change = data[i] - data[i - 1];
        if change > 0.0 { gains += change; }
        else { losses += change.abs(); }
    }
    let avg_gain = gains / period as f64;
    let avg_loss = losses / period as f64;
    if avg_loss == 0.0 { return 100.0; }
    let rs = avg_gain / avg_loss;
    100.0 - (100.0 / (1.0 + rs))
}

fn calc_rsi_at(data: &[f64], end: usize, period: usize) -> f64 {
    if end < period + 1 { return 50.0; }
    let mut gains = 0.0;
    let mut losses = 0.0;
    for i in (end - period)..end {
        let change = data[i] - data[i - 1];
        if change > 0.0 { gains += change; }
        else { losses += change.abs(); }
    }
    let avg_gain = gains / period as f64;
    let avg_loss = losses / period as f64;
    if avg_loss == 0.0 { return 100.0; }
    100.0 - (100.0 / (1.0 + avg_gain / avg_loss))
}

fn calc_bollinger(data: &[f64], period: usize, std_dev: f64) -> (f64, f64, f64) {
    if data.len() < period {
        let last = *data.last().unwrap_or(&0.0);
        return (last, last, last);
    }
    let slice = &data[data.len() - period..];
    let mean: f64 = slice.iter().sum::<f64>() / period as f64;
    let variance: f64 = slice.iter().map(|x| (x - mean).powi(2)).sum::<f64>() / period as f64;
    let sd = variance.sqrt();
    (mean + std_dev * sd, mean, mean - std_dev * sd)
}

fn calc_atr(candles: &[Candle], period: usize) -> f64 {
    if candles.len() < period + 1 { return 0.0; }
    let mut sum = 0.0;
    let start = candles.len() - period;
    for i in start..candles.len() {
        let tr1 = candles[i].high - candles[i].low;
        let tr2 = (candles[i].high - candles[i - 1].close).abs();
        let tr3 = (candles[i].low - candles[i - 1].close).abs();
        sum += tr1.max(tr2).max(tr3);
    }
    sum / period as f64
}

/// Find swing highs/lows (look back N candles each side)
fn find_swings(candles: &[Candle], lookback: usize) -> (f64, f64, f64, f64) {
    let n = candles.len();
    if n < lookback * 2 + 1 {
        let h = candles.iter().map(|c| c.high).fold(f64::MIN, f64::max);
        let l = candles.iter().map(|c| c.low).fold(f64::MAX, f64::min);
        return (h, l, h, l);
    }
    let mut swing_high = 0.0;
    let mut swing_low = f64::MAX;
    let mut prev_swing_high = 0.0;
    let mut prev_swing_low = f64::MAX;

    for i in lookback..(n - lookback) {
        let is_high = (0..lookback).all(|j| candles[i].high >= candles[i - j - 1].high && candles[i].high >= candles[i + j + 1].high);
        let is_low = (0..lookback).all(|j| candles[i].low <= candles[i - j - 1].low && candles[i].low <= candles[i + j + 1].low);
        if is_high {
            prev_swing_high = swing_high;
            swing_high = candles[i].high;
        }
        if is_low {
            prev_swing_low = swing_low;
            swing_low = candles[i].low;
        }
    }
    if swing_high == 0.0 { swing_high = candles.iter().map(|c| c.high).fold(f64::MIN, f64::max); }
    if swing_low == f64::MAX { swing_low = candles.iter().map(|c| c.low).fold(f64::MAX, f64::min); }
    if prev_swing_high == 0.0 { prev_swing_high = swing_high; }
    if prev_swing_low == f64::MAX { prev_swing_low = swing_low; }
    (swing_high, swing_low, prev_swing_high, prev_swing_low)
}

/// Detect Fair Value Gaps
fn detect_fvg(candles: &[Candle]) -> (bool, bool) {
    let n = candles.len();
    if n < 3 { return (false, false); }
    let c0 = &candles[n - 3]; // oldest  
    let c2 = &candles[n - 1]; // newest
    // Bullish FVG: gap between candle[0] high and candle[2] low
    let bull_fvg = c2.low > c0.high;
    // Bearish FVG: gap between candle[0] low and candle[2] high  
    let bear_fvg = c2.high < c0.low;
    (bull_fvg, bear_fvg)
}

/// Find order blocks (last bearish candle before a bullish move, and vice versa)
fn find_order_blocks(candles: &[Candle]) -> (f64, f64) {
    let n = candles.len();
    if n < 10 { return (0.0, 0.0); }
    let mut ob_bull = 0.0;
    let mut ob_bear = 0.0;
    for i in (n.saturating_sub(20)..n - 1).rev() {
        let body = candles[i].close - candles[i].open;
        let next_body = candles[i + 1].close - candles[i + 1].open;
        // Bullish OB: bearish candle followed by strong bullish candle
        if body < 0.0 && next_body > 0.0 && next_body.abs() > body.abs() * 1.5 && ob_bull == 0.0 {
            ob_bull = candles[i].low; // OB zone = low of bearish candle
        }
        // Bearish OB: bullish candle followed by strong bearish candle
        if body > 0.0 && next_body < 0.0 && next_body.abs() > body.abs() * 1.5 && ob_bear == 0.0 {
            ob_bear = candles[i].high; // OB zone = high of bullish candle
        }
        if ob_bull > 0.0 && ob_bear > 0.0 { break; }
    }
    (ob_bull, ob_bear)
}

/// Compute Asian session range (candles 0-8 in a 24-candle H1 set, approximate)
fn calc_asian_range(candles: &[Candle]) -> (f64, f64) {
    // Use last ~8 candles from the earlier part as proxy for Asian session
    let n = candles.len();
    if n < 20 { 
        let h = candles.iter().map(|c| c.high).fold(f64::MIN, f64::max);
        let l = candles.iter().map(|c| c.low).fold(f64::MAX, f64::min);
        return (h, l);
    }
    let start = n.saturating_sub(24);
    let end = start + 8;
    let slice = &candles[start..end.min(n)];
    let h = slice.iter().map(|c| c.high).fold(f64::MIN, f64::max);
    let l = slice.iter().map(|c| c.low).fold(f64::MAX, f64::min);
    (h, l)
}

pub fn compute_indicators(candles: &[Candle]) -> Indicators {
    if candles.len() < 50 {
        return Indicators::default();
    }
    let closes: Vec<f64> = candles.iter().map(|c| c.close).collect();
    let n = closes.len();

    let ema9 = calc_ema(&closes, 9);
    let ema21 = calc_ema(&closes, 21);
    let ema50 = calc_ema(&closes, 50);
    let ema200 = if n >= 200 { calc_ema(&closes, 200) } else { vec![0.0; n] };
    let rsi = calc_rsi(&closes, 14);
    let rsi_prev = calc_rsi_at(&closes, n - 1, 14);
    let (bb_upper, bb_middle, bb_lower) = calc_bollinger(&closes, 20, 2.0);
    let atr = calc_atr(candles, 14);

    // ATR average over last 20 bars — used for volatility ratio
    let atr_20_avg = if candles.len() >= 30 {
        let mut sum = 0.0;
        let count = 20usize;
        let start = candles.len().saturating_sub(count + 14);
        for i in 0..count {
            sum += calc_atr(&candles[start..start + 14 + i + 1], 14);
        }
        let avg = sum / count as f64;
        if avg > 0.0 { avg } else { atr }
    } else { atr };
    let atr_ratio = if atr_20_avg > 0.0 { atr / atr_20_avg } else { 1.0 };

    // Fibonacci: use swing high/low of last 50 candles
    let (swing_high, swing_low, prev_swing_high, prev_swing_low) = find_swings(candles, 3);
    let fib_range = swing_high - swing_low;
    let fib_382 = swing_high - fib_range * 0.382;
    let fib_500 = swing_high - fib_range * 0.500;
    let fib_618 = swing_high - fib_range * 0.618;

    // Order blocks
    let (ob_bull, ob_bear) = find_order_blocks(candles);
    // Fair value gaps
    let (fvg_bull, fvg_bear) = detect_fvg(candles);
    // Asian range
    let (asian_high, asian_low) = calc_asian_range(candles);

    // Momentum (Rate of Change)
    let roc_period = 10.min(n - 1);
    let momentum = if closes[n - 1 - roc_period] != 0.0 {
        ((closes[n - 1] - closes[n - 1 - roc_period]) / closes[n - 1 - roc_period]) * 100.0
    } else { 0.0 };

    let last = &candles[n - 1];
    let range = last.high - last.low;
    let body = (last.close - last.open).abs();
    let candle_body_ratio = if range > 0.0 { body / range } else { 0.0 };

    Indicators {
        rsi_14: rsi,
        ema_9: ema9[n - 1],
        ema_21: ema21[n - 1],
        ema_50: ema50[n - 1],
        ema_200: if n >= 200 { ema200[n - 1] } else { ema50[n - 1] },
        bb_upper, bb_middle, bb_lower,
        prev_ema_9: if n >= 2 { ema9[n - 2] } else { 0.0 },
        prev_ema_21: if n >= 2 { ema21[n - 2] } else { 0.0 },
        prev_close: if n >= 2 { closes[n - 2] } else { 0.0 },
        current_close: closes[n - 1],
        current_high: last.high,
        current_low: last.low,
        current_open: last.open,
        fib_high: swing_high, fib_low: swing_low,
        fib_382, fib_500, fib_618,
        swing_high, swing_low, prev_swing_high, prev_swing_low,
        order_block_bull: ob_bull, order_block_bear: ob_bear,
        fair_value_gap_bull: fvg_bull, fair_value_gap_bear: fvg_bear,
        rsi_prev, momentum, atr, candle_body_ratio,
        asian_high, asian_low,
        atr_20_avg, atr_ratio,
    }
}

// ──────────────────────────────────────────────
//  Strategy Signal Logic (10 strategies + Auto)
// ──────────────────────────────────────────────

pub fn evaluate_strategy(strategy: &str, ind: &Indicators) -> StrategyResult {
    // ═══ Spread Filter (v9): Skip signals in ultra-quiet markets ═══
    // If candle body < 10% of ATR, market is too quiet for reliable signals
    // (exempts Auto mode which aggregates and handles differently)
    if strategy != "Auto" && ind.atr > 0.0 {
        let body = (ind.current_close - ind.current_open).abs();
        if body < ind.atr * 0.1 {
            return StrategyResult::none();
        }
    }

    match strategy {
        "Scalper Pro"      => eval_scalper(ind),
        "Trend Rider"      => eval_trend_rider(ind),
        "Breakout Hunter"  => eval_breakout(ind),
        "Mean Revert"      => eval_mean_revert(ind),
        "Grid Master"      => eval_grid(ind),
        "SMC"              => eval_smc(ind),
        "ICT"              => eval_ict(ind),
        "Fibonacci"        => eval_fibonacci(ind),
        "Momentum Surge"   => eval_momentum(ind),
        "Session Sniper"   => eval_session(ind),
        "Engulfing Driver" => eval_engulfing(ind),
        "Bollinger Squeeze"=> eval_bollinger_squeeze(ind),
        "Pullback Sniper"  => eval_pullback_sniper(ind),
        "Reversal Catcher" => eval_reversal_catcher(ind),
        "Golden Cross"     => eval_golden_cross(ind),
        "Fractal Breakout" => eval_fractal_breakout(ind),
        "Auto"             => eval_auto(ind),
        _ => StrategyResult::none(),
    }
}

// ─── 1. Scalper Pro (ปรับ: RSI เข้มขึ้น + ATR filter + trend align) ───
// ─── 1. Scalper V2 — Smart Multi-Mode Scalping ───
// 5 modes: BB Squeeze Entry, Liquidity Sweep, EMA Ribbon Bounce, Momentum Spike, Range Break
// Features: Session filter, ATR gate, 3-confirm minimum, tight SL/TP (0.8/1.2 ATR)
fn eval_scalper(ind: &Indicators) -> StrategyResult {
    let has_atr = ind.atr > 0.0;
    if !has_atr { return StrategyResult::none(); }

    // ════════════════════════════════════════
    //  SESSION FILTER — scalp only during liquid sessions
    // ════════════════════════════════════════
    let utc_hour = chrono::Utc::now().hour();
    let in_london = utc_hour >= 7 && utc_hour < 11;
    let in_ny = utc_hour >= 13 && utc_hour < 17;
    let in_overlap = utc_hour >= 13 && utc_hour < 16; // best session
    let session_ok = in_london || in_ny;
    
    if !session_ok {
        return StrategyResult::none(); // Don't scalp outside liquid sessions
    }

    // ════════════════════════════════════════
    //  ATR GATE — skip if too quiet or too wild
    // ════════════════════════════════════════
    if ind.atr_ratio < 0.3 || ind.atr_ratio > 2.5 {
        return StrategyResult::none(); // market not suitable for scalping
    }

    // ════════════════════════════════════════
    //  CONFIRMATION SYSTEM (count confirmations)
    // ════════════════════════════════════════
    let ema_bull = ind.ema_9 > ind.ema_21;
    let ema_bear = ind.ema_9 < ind.ema_21;
    let rsi_ok_buy = ind.rsi_14 > 20.0 && ind.rsi_14 < 65.0; // not extreme
    let rsi_ok_sell = ind.rsi_14 > 35.0 && ind.rsi_14 < 80.0;
    let mom_bull = ind.momentum > 0.0;
    let mom_bear = ind.momentum < 0.0;
    let body_ok = ind.candle_body_ratio > 0.3; // not a doji
    let higher_tf_bull = ind.current_close > ind.ema_50;
    let higher_tf_bear = ind.current_close < ind.ema_50;

    let buy_confirms = [ema_bull, rsi_ok_buy, mom_bull, body_ok, higher_tf_bull]
        .iter().filter(|&&c| c).count();
    let sell_confirms = [ema_bear, rsi_ok_sell, mom_bear, body_ok, higher_tf_bear]
        .iter().filter(|&&c| c).count();

    // Session bonus
    let session_bonus: f64 = if in_overlap { 8.0 } else { 0.0 };

    // Tight SL/TP builder for scalping
    let build_scalp_result = |signal: Signal, reason: String, conf: f64| -> StrategyResult {
        StrategyResult {
            signal,
            reason,
            confidence: conf,
            indicator_summary: generate_indicator_summary(ind),
            suggested_sl_atr: ind.atr * 0.8,  // tight SL
            suggested_tp_atr: ind.atr * 1.2,  // tight TP (R:R = 1:1.5)
        }
    };

    // ════════════════════════════════════════
    //  MODE 1: BB Squeeze Entry (range → breakout)
    // ════════════════════════════════════════
    // BB is narrow (squeeze) and price breaks out of band with displacement
    {
        let bb_width = if ind.bb_middle > 0.0 {
            (ind.bb_upper - ind.bb_lower) / ind.bb_middle
        } else { 1.0 };
        let is_squeeze = bb_width < 0.015; // Bollinger Bandwidth < 1.5% = squeeze

        // BUY: Squeeze break up
        if is_squeeze && ind.current_close > ind.bb_upper && ind.prev_close <= ind.bb_upper
            && ind.candle_body_ratio > 0.5 && buy_confirms >= 3 {
            let mut conf = 65.0 + session_bonus;
            if ind.rsi_prev < ind.rsi_14 { conf += 5.0; } // RSI accelerating
            if ind.atr_ratio > 0.8 { conf += 5.0; } // expanding volatility
            return build_scalp_result(Signal::Buy,
                format!("Scalp BB-Squeeze BUY: BW={:.3}%, Break BB↑, Disp={:.0}%, Cf={}/5",
                    bb_width * 100.0, ind.candle_body_ratio * 100.0, buy_confirms),
                conf.clamp(0.0, 100.0),
            );
        }
        // SELL: Squeeze break down
        if is_squeeze && ind.current_close < ind.bb_lower && ind.prev_close >= ind.bb_lower
            && ind.candle_body_ratio > 0.5 && sell_confirms >= 3 {
            let mut conf = 65.0 + session_bonus;
            if ind.rsi_prev > ind.rsi_14 { conf += 5.0; }
            if ind.atr_ratio > 0.8 { conf += 5.0; }
            return build_scalp_result(Signal::Sell,
                format!("Scalp BB-Squeeze SELL: BW={:.3}%, Break BB↓, Disp={:.0}%, Cf={}/5",
                    bb_width * 100.0, ind.candle_body_ratio * 100.0, sell_confirms),
                conf.clamp(0.0, 100.0),
            );
        }
    }

    // ════════════════════════════════════════
    //  MODE 2: Liquidity Sweep (fake breakout → reverse)
    // ════════════════════════════════════════
    // Price sweeps swing high/low but closes back inside = liquidity grab
    {
        let wick_ratio = if (ind.current_high - ind.current_low) > 0.0 {
            1.0 - ind.candle_body_ratio // wick proportion
        } else { 0.0 };
        let long_wick = wick_ratio > 0.5; // wick > 50% of range = rejection

        // BUY: Swept swing low + long lower wick + closed above swing low
        if ind.current_low < ind.swing_low && ind.current_close > ind.swing_low
            && long_wick && ind.current_close > ind.current_open // bullish close
            && buy_confirms >= 3 {
            let mut conf = 70.0 + session_bonus;
            if ind.fair_value_gap_bull { conf += 5.0; }
            if ind.rsi_14 < 40.0 { conf += 5.0; } // swept into oversold
            return build_scalp_result(Signal::Buy,
                format!("Scalp Sweep BUY: Swept<{:.5}, Wick={:.0}%, FVG={}, Cf={}/5",
                    ind.swing_low, wick_ratio * 100.0, ind.fair_value_gap_bull, buy_confirms),
                conf.clamp(0.0, 100.0),
            );
        }
        // SELL: Swept swing high + long upper wick + closed below swing high
        if ind.current_high > ind.swing_high && ind.current_close < ind.swing_high
            && long_wick && ind.current_close < ind.current_open // bearish close
            && sell_confirms >= 3 {
            let mut conf = 70.0 + session_bonus;
            if ind.fair_value_gap_bear { conf += 5.0; }
            if ind.rsi_14 > 60.0 { conf += 5.0; }
            return build_scalp_result(Signal::Sell,
                format!("Scalp Sweep SELL: Swept>{:.5}, Wick={:.0}%, FVG={}, Cf={}/5",
                    ind.swing_high, wick_ratio * 100.0, ind.fair_value_gap_bear, sell_confirms),
                conf.clamp(0.0, 100.0),
            );
        }
    }

    // ════════════════════════════════════════
    //  MODE 3: EMA Ribbon Bounce (trending market scalp)
    // ════════════════════════════════════════
    // Price touches EMA9 zone in a trend and bounces
    {
        let ema_spread = ((ind.ema_9 - ind.ema_21) / ind.ema_21).abs();
        let trending = ema_spread > 0.001; // EMAs separated = clear trend
        let near_ema9_pct = ((ind.current_close - ind.ema_9) / ind.ema_9).abs();
        let touched_ema9 = near_ema9_pct < 0.001 || 
            (ind.current_low <= ind.ema_9 * 1.001 && ind.current_high >= ind.ema_9 * 0.999);

        // BUY: Uptrend + price bounces off EMA9
        if trending && ema_bull && touched_ema9
            && ind.current_close > ind.ema_9  // bounced above
            && ind.current_close > ind.current_open // bullish candle
            && buy_confirms >= 3 {
            let mut conf = 60.0 + session_bonus;
            if ind.ema_50 > ind.ema_200 { conf += 5.0; } // higher TF aligned
            if ind.rsi_14 > 45.0 && ind.rsi_14 < 65.0 { conf += 5.0; } // mid RSI = healthy trend
            if ind.momentum > 0.1 { conf += 5.0; }
            return build_scalp_result(Signal::Buy,
                format!("Scalp EMA-Bounce BUY: Touch EMA9={:.5}, Bounce, Spread={:.3}%, Cf={}/5",
                    ind.ema_9, ema_spread * 100.0, buy_confirms),
                conf.clamp(0.0, 100.0),
            );
        }
        // SELL: Downtrend + price bounces off EMA9
        if trending && ema_bear && touched_ema9
            && ind.current_close < ind.ema_9
            && ind.current_close < ind.current_open
            && sell_confirms >= 3 {
            let mut conf = 60.0 + session_bonus;
            if ind.ema_50 < ind.ema_200 { conf += 5.0; }
            if ind.rsi_14 > 35.0 && ind.rsi_14 < 55.0 { conf += 5.0; }
            if ind.momentum < -0.1 { conf += 5.0; }
            return build_scalp_result(Signal::Sell,
                format!("Scalp EMA-Bounce SELL: Touch EMA9={:.5}, Bounce, Spread={:.3}%, Cf={}/5",
                    ind.ema_9, ema_spread * 100.0, sell_confirms),
                conf.clamp(0.0, 100.0),
            );
        }
    }

    // ════════════════════════════════════════
    //  MODE 4: Momentum Spike (strong displacement)
    // ════════════════════════════════════════
    // Large candle body + RSI acceleration = momentum entry
    {
        let strong_body = ind.candle_body_ratio > 0.7; // body > 70% of range
        let rsi_accelerating_up = ind.rsi_14 - ind.rsi_prev > 8.0; // big RSI jump
        let rsi_accelerating_down = ind.rsi_prev - ind.rsi_14 > 8.0;

        // BUY: Strong bullish momentum
        if strong_body && rsi_accelerating_up
            && ind.current_close > ind.current_open
            && ind.current_close > ind.ema_9
            && buy_confirms >= 3 {
            let mut conf = 65.0 + session_bonus;
            if ind.atr_ratio > 1.0 { conf += 5.0; } // expanding volatility
            if higher_tf_bull { conf += 5.0; }
            return build_scalp_result(Signal::Buy,
                format!("Scalp Momentum BUY: Body={:.0}%, RSI Δ+{:.1}, ATR_ratio={:.2}, Cf={}/5",
                    ind.candle_body_ratio * 100.0, ind.rsi_14 - ind.rsi_prev, ind.atr_ratio, buy_confirms),
                conf.clamp(0.0, 100.0),
            );
        }
        // SELL: Strong bearish momentum
        if strong_body && rsi_accelerating_down
            && ind.current_close < ind.current_open
            && ind.current_close < ind.ema_9
            && sell_confirms >= 3 {
            let mut conf = 65.0 + session_bonus;
            if ind.atr_ratio > 1.0 { conf += 5.0; }
            if higher_tf_bear { conf += 5.0; }
            return build_scalp_result(Signal::Sell,
                format!("Scalp Momentum SELL: Body={:.0}%, RSI Δ-{:.1}, ATR_ratio={:.2}, Cf={}/5",
                    ind.candle_body_ratio * 100.0, ind.rsi_prev - ind.rsi_14, ind.atr_ratio, sell_confirms),
                conf.clamp(0.0, 100.0),
            );
        }
    }

    // ════════════════════════════════════════
    //  MODE 5: Range Break (Asian range → London breakout)
    // ════════════════════════════════════════
    // Price breaks Asian high/low during London session
    {
        let has_asian = ind.asian_high > 0.0 && ind.asian_low > 0.0 && ind.asian_high > ind.asian_low;

        if has_asian && in_london {
            // BUY: Break above Asian high
            if ind.current_close > ind.asian_high && ind.prev_close <= ind.asian_high
                && ind.candle_body_ratio > 0.4 && buy_confirms >= 3 {
                let mut conf = 68.0 + session_bonus;
                if ind.ema_9 > ind.ema_21 { conf += 5.0; }
                if ind.momentum > 0.0 { conf += 5.0; }
                return build_scalp_result(Signal::Buy,
                    format!("Scalp Range-Break BUY: >Asian High {:.5}, Body={:.0}%, Cf={}/5",
                        ind.asian_high, ind.candle_body_ratio * 100.0, buy_confirms),
                    conf.clamp(0.0, 100.0),
                );
            }
            // SELL: Break below Asian low
            if ind.current_close < ind.asian_low && ind.prev_close >= ind.asian_low
                && ind.candle_body_ratio > 0.4 && sell_confirms >= 3 {
                let mut conf = 68.0 + session_bonus;
                if ind.ema_9 < ind.ema_21 { conf += 5.0; }
                if ind.momentum < 0.0 { conf += 5.0; }
                return build_scalp_result(Signal::Sell,
                    format!("Scalp Range-Break SELL: <Asian Low {:.5}, Body={:.0}%, Cf={}/5",
                        ind.asian_low, ind.candle_body_ratio * 100.0, sell_confirms),
                    conf.clamp(0.0, 100.0),
                );
            }
        }
    }

    StrategyResult::none()
}

// ─── 2. Trend Rider (ปรับ: RSI zone 40-60 + ATR minimum + EMA50 confirm) ───
fn eval_trend_rider(ind: &Indicators) -> StrategyResult {
    let cross_up = ind.prev_ema_9 <= ind.prev_ema_21 && ind.ema_9 > ind.ema_21;
    let cross_down = ind.prev_ema_9 >= ind.prev_ema_21 && ind.ema_9 < ind.ema_21;
    
    if cross_up && ind.current_close > ind.ema_50 {
        let mut conf = 65.0;
        if ind.rsi_14 > 40.0 && ind.rsi_14 < 60.0 { conf += 10.0; } // RSI neutral zone
        if ind.momentum > 0.0 { conf += 5.0; } // positive momentum
        if ind.ema_50 > ind.ema_200 { conf += 5.0; } // higher TF trend aligned
        return StrategyResult::buy(
            format!("Trend BUY: EMA9 crossed EMA21, Price>{:.5}, RSI={:.1}", ind.ema_50, ind.rsi_14),
            conf, ind,
        );
    }
    if cross_down && ind.current_close < ind.ema_50 {
        let mut conf = 65.0;
        if ind.rsi_14 > 40.0 && ind.rsi_14 < 60.0 { conf += 10.0; }
        if ind.momentum < 0.0 { conf += 5.0; }
        if ind.ema_50 < ind.ema_200 { conf += 5.0; }
        return StrategyResult::sell(
            format!("Trend SELL: EMA9 crossed EMA21, Price<{:.5}, RSI={:.1}", ind.ema_50, ind.rsi_14),
            conf, ind,
        );
    }
    StrategyResult::none()
}

// ─── 3. Breakout Hunter (ปรับ: ATR spike confirmation) ───
fn eval_breakout(ind: &Indicators) -> StrategyResult {
    let atr_strong = ind.candle_body_ratio > 0.5; // strong displacement candle
    
    if ind.current_close > ind.bb_upper && ind.prev_close <= ind.bb_upper && ind.rsi_14 > 55.0 && atr_strong {
        let mut conf = 65.0;
        if ind.momentum > 0.2 { conf += 10.0; }
        if ind.ema_9 > ind.ema_21 { conf += 5.0; }
        return StrategyResult::buy(
            format!("Breakout BUY: Broke BB upper, RSI={:.1}, Body={:.0}%", ind.rsi_14, ind.candle_body_ratio*100.0),
            conf, ind,
        );
    }
    if ind.current_close < ind.bb_lower && ind.prev_close >= ind.bb_lower && ind.rsi_14 < 45.0 && atr_strong {
        let mut conf = 65.0;
        if ind.momentum < -0.2 { conf += 10.0; }
        if ind.ema_9 < ind.ema_21 { conf += 5.0; }
        return StrategyResult::sell(
            format!("Breakout SELL: Broke BB lower, RSI={:.1}, Body={:.0}%", ind.rsi_14, ind.candle_body_ratio*100.0),
            conf, ind,
        );
    }
    StrategyResult::none()
}

// ─── 4. Mean Revert (ปรับ: BB squeeze width + candle reversal) ───
fn eval_mean_revert(ind: &Indicators) -> StrategyResult {
    let bb_width = if ind.bb_middle > 0.0 { (ind.bb_upper - ind.bb_lower) / ind.bb_middle } else { 1.0 };
    
    if ind.rsi_14 < 25.0 && ind.current_close <= ind.bb_lower * 1.002 && bb_width > 0.01 {
        let mut conf = 60.0;
        if ind.current_close > ind.current_open { conf += 10.0; } // bullish candle (reversal)
        if ind.rsi_prev < ind.rsi_14 { conf += 5.0; } // RSI turning up
        if bb_width > 0.03 { conf += 5.0; } // wide band = strong revert
        return StrategyResult::buy(
            format!("MeanRevert BUY: RSI={:.1}<25, BB Lower, BW={:.3}", ind.rsi_14, bb_width),
            conf, ind,
        );
    }
    if ind.rsi_14 > 75.0 && ind.current_close >= ind.bb_upper * 0.998 && bb_width > 0.01 {
        let mut conf = 60.0;
        if ind.current_close < ind.current_open { conf += 10.0; }
        if ind.rsi_prev > ind.rsi_14 { conf += 5.0; }
        if bb_width > 0.03 { conf += 5.0; }
        return StrategyResult::sell(
            format!("MeanRevert SELL: RSI={:.1}>75, BB Upper, BW={:.3}", ind.rsi_14, bb_width),
            conf, ind,
        );
    }
    StrategyResult::none()
}

// ─── 5. Grid Master V2 — Aggressive Multi-Zone Grid ───
// 5 zones: BB Extreme, Fib Grid, EMA Bounce Grid, Swing Level, Mid-Grid Reversal
// Features: ATR-based grid spacing, session awareness, tight SL/TP, momentum filter
fn eval_grid(ind: &Indicators) -> StrategyResult {
    let range = ind.bb_upper - ind.bb_lower;
    if range <= 0.0 || ind.atr <= 0.0 { return StrategyResult::none(); }
    let bb_pos = (ind.current_close - ind.bb_lower) / range; // 0.0 = bottom, 1.0 = top

    // Session awareness — more aggressive during high-volume sessions
    let utc_hour = chrono::Utc::now().hour();
    let in_london = utc_hour >= 7 && utc_hour < 16;
    let in_ny = utc_hour >= 13 && utc_hour < 21;
    let in_overlap = utc_hour >= 13 && utc_hour < 16;
    let session_active = in_london || in_ny;
    let aggro_bonus: f64 = if in_overlap { 10.0 } else if session_active { 5.0 } else { 0.0 };

    // Skip dead market
    if ind.atr_ratio < 0.2 { return StrategyResult::none(); }

    // Tight SL/TP for grid (tighter than standard)
    let build_grid_result = |signal: Signal, reason: String, conf: f64| -> StrategyResult {
        StrategyResult {
            signal,
            reason,
            confidence: conf,
            indicator_summary: generate_indicator_summary(ind),
            suggested_sl_atr: ind.atr * 1.0,  // tight SL (1.0 ATR)
            suggested_tp_atr: ind.atr * 1.5,   // tight TP (R:R = 1:1.5)
        }
    };

    // ═══ ZONE 1: BB Extreme (ราคาอยู่ขอบ BB สุด — ดีดกลับ) ═══
    // More aggressive: enter at 10% from edge (vs 15% in v1)
    if bb_pos < 0.10 && ind.rsi_14 < 35.0 {
        let mut conf: f64 = 62.0 + aggro_bonus;
        if ind.current_close > ind.current_open { conf += 10.0; } // bullish reversal candle
        if ind.rsi_prev < ind.rsi_14 { conf += 5.0; } // RSI turning up
        if ind.fair_value_gap_bull { conf += 5.0; }
        if ind.momentum > -0.1 { conf += 3.0; } // momentum slowing
        return build_grid_result(Signal::Buy,
            format!("Grid BB-Extreme BUY: BB={:.0}%, RSI={:.1}, Turn={}", 
                bb_pos*100.0, ind.rsi_14, ind.rsi_prev < ind.rsi_14),
            conf.clamp(0.0, 100.0),
        );
    }
    if bb_pos > 0.90 && ind.rsi_14 > 65.0 {
        let mut conf: f64 = 62.0 + aggro_bonus;
        if ind.current_close < ind.current_open { conf += 10.0; }
        if ind.rsi_prev > ind.rsi_14 { conf += 5.0; }
        if ind.fair_value_gap_bear { conf += 5.0; }
        if ind.momentum < 0.1 { conf += 3.0; }
        return build_grid_result(Signal::Sell,
            format!("Grid BB-Extreme SELL: BB={:.0}%, RSI={:.1}, Turn={}",
                bb_pos*100.0, ind.rsi_14, ind.rsi_prev > ind.rsi_14),
            conf.clamp(0.0, 100.0),
        );
    }

    // ═══ ZONE 2: Fib Grid (ราคาชน Fib level — เด้ง) ═══
    let near_fib = |price: f64, level: f64| -> bool {
        if level <= 0.0 { return false; }
        ((price - level) / level).abs() < 0.002 // within 0.2%
    };

    // BUY at Fib 61.8% support in uptrend
    if ind.current_close > ind.ema_50 && near_fib(ind.current_close, ind.fib_618)
        && ind.rsi_14 > 35.0 && ind.rsi_14 < 55.0 {
        let mut conf: f64 = 60.0 + aggro_bonus;
        if ind.ema_9 > ind.ema_21 { conf += 8.0; }
        if ind.current_close > ind.current_open { conf += 5.0; }
        if ind.rsi_prev < ind.rsi_14 { conf += 5.0; }
        return build_grid_result(Signal::Buy,
            format!("Grid Fib BUY: @61.8%={:.5}, RSI={:.1}, Trend=UP",
                ind.fib_618, ind.rsi_14),
            conf.clamp(0.0, 100.0),
        );
    }
    // BUY at Fib 50.0% support
    if ind.current_close > ind.ema_50 && near_fib(ind.current_close, ind.fib_500)
        && ind.rsi_14 > 35.0 && ind.rsi_14 < 55.0 {
        let mut conf: f64 = 58.0 + aggro_bonus;
        if ind.ema_9 > ind.ema_21 { conf += 8.0; }
        if ind.current_close > ind.current_open { conf += 5.0; }
        return build_grid_result(Signal::Buy,
            format!("Grid Fib BUY: @50.0%={:.5}, RSI={:.1}", ind.fib_500, ind.rsi_14),
            conf.clamp(0.0, 100.0),
        );
    }
    // SELL at Fib 38.2% resistance in downtrend
    if ind.current_close < ind.ema_50 && near_fib(ind.current_close, ind.fib_382)
        && ind.rsi_14 > 45.0 && ind.rsi_14 < 65.0 {
        let mut conf: f64 = 60.0 + aggro_bonus;
        if ind.ema_9 < ind.ema_21 { conf += 8.0; }
        if ind.current_close < ind.current_open { conf += 5.0; }
        if ind.rsi_prev > ind.rsi_14 { conf += 5.0; }
        return build_grid_result(Signal::Sell,
            format!("Grid Fib SELL: @38.2%={:.5}, RSI={:.1}, Trend=DOWN",
                ind.fib_382, ind.rsi_14),
            conf.clamp(0.0, 100.0),
        );
    }

    // ═══ ZONE 3: EMA Bounce Grid (ราคาเด้ง EMA ในเทรนด์) ═══
    let near_ema21 = ((ind.current_close - ind.ema_21) / ind.ema_21).abs() < 0.0015;
    
    // BUY: bounce off EMA21 in uptrend
    if near_ema21 && ind.ema_9 > ind.ema_21 && ind.current_close > ind.ema_21
        && ind.current_close > ind.current_open && ind.rsi_14 > 40.0 && ind.rsi_14 < 60.0 {
        let mut conf: f64 = 58.0 + aggro_bonus;
        if ind.ema_50 > ind.ema_200 { conf += 5.0; }
        if ind.momentum > 0.0 { conf += 5.0; }
        if ind.candle_body_ratio > 0.4 { conf += 3.0; }
        return build_grid_result(Signal::Buy,
            format!("Grid EMA21 BUY: Bounce EMA21={:.5}, RSI={:.1}", ind.ema_21, ind.rsi_14),
            conf.clamp(0.0, 100.0),
        );
    }
    // SELL: bounce off EMA21 in downtrend
    if near_ema21 && ind.ema_9 < ind.ema_21 && ind.current_close < ind.ema_21
        && ind.current_close < ind.current_open && ind.rsi_14 > 40.0 && ind.rsi_14 < 60.0 {
        let mut conf: f64 = 58.0 + aggro_bonus;
        if ind.ema_50 < ind.ema_200 { conf += 5.0; }
        if ind.momentum < 0.0 { conf += 5.0; }
        if ind.candle_body_ratio > 0.4 { conf += 3.0; }
        return build_grid_result(Signal::Sell,
            format!("Grid EMA21 SELL: Bounce EMA21={:.5}, RSI={:.1}", ind.ema_21, ind.rsi_14),
            conf.clamp(0.0, 100.0),
        );
    }

    // ═══ ZONE 4: Swing Level Grid (ราคาชน swing high/low เก่า) ═══
    let near_swing_low = ind.swing_low > 0.0 && 
        ((ind.current_close - ind.swing_low) / ind.swing_low).abs() < 0.002;
    let near_swing_high = ind.swing_high > 0.0 && 
        ((ind.current_close - ind.swing_high) / ind.swing_high).abs() < 0.002;

    if near_swing_low && ind.current_close > ind.swing_low 
        && ind.current_close > ind.current_open && ind.rsi_14 < 45.0 {
        let mut conf: f64 = 60.0 + aggro_bonus;
        if ind.fair_value_gap_bull { conf += 5.0; }
        if ind.rsi_prev < ind.rsi_14 { conf += 5.0; }
        if ind.candle_body_ratio > 0.4 { conf += 3.0; }
        return build_grid_result(Signal::Buy,
            format!("Grid Swing BUY: @SwLow={:.5}, RSI={:.1}", ind.swing_low, ind.rsi_14),
            conf.clamp(0.0, 100.0),
        );
    }
    if near_swing_high && ind.current_close < ind.swing_high
        && ind.current_close < ind.current_open && ind.rsi_14 > 55.0 {
        let mut conf: f64 = 60.0 + aggro_bonus;
        if ind.fair_value_gap_bear { conf += 5.0; }
        if ind.rsi_prev > ind.rsi_14 { conf += 5.0; }
        if ind.candle_body_ratio > 0.4 { conf += 3.0; }
        return build_grid_result(Signal::Sell,
            format!("Grid Swing SELL: @SwHigh={:.5}, RSI={:.1}", ind.swing_high, ind.rsi_14),
            conf.clamp(0.0, 100.0),
        );
    }

    // ═══ ZONE 5: Mid-Grid Reversal (BB middle + RSI extreme — aggressive) ═══
    // Only during active sessions — contrarian play at BB middle
    if session_active {
        let near_bb_mid = ((ind.current_close - ind.bb_middle) / ind.bb_middle).abs() < 0.001;
        
        // BUY: price at BB middle + RSI oversold + bullish candle
        if near_bb_mid && ind.rsi_14 < 35.0 && ind.current_close > ind.current_open
            && ind.ema_9 > ind.ema_21 {
            let mut conf: f64 = 55.0 + aggro_bonus;
            if ind.rsi_prev < ind.rsi_14 { conf += 5.0; }
            if ind.momentum > 0.0 { conf += 5.0; }
            return build_grid_result(Signal::Buy,
                format!("Grid Mid BUY: @BB_mid, RSI={:.1}<35, EMA↑", ind.rsi_14),
                conf.clamp(0.0, 100.0),
            );
        }
        // SELL: price at BB middle + RSI overbought + bearish candle
        if near_bb_mid && ind.rsi_14 > 65.0 && ind.current_close < ind.current_open
            && ind.ema_9 < ind.ema_21 {
            let mut conf: f64 = 55.0 + aggro_bonus;
            if ind.rsi_prev > ind.rsi_14 { conf += 5.0; }
            if ind.momentum < 0.0 { conf += 5.0; }
            return build_grid_result(Signal::Sell,
                format!("Grid Mid SELL: @BB_mid, RSI={:.1}>65, EMA↓", ind.rsi_14),
                conf.clamp(0.0, 100.0),
            );
        }
    }

    StrategyResult::none()
}

// ─── 6. SMC (ปรับ: + Displacement candle + FVG required) ───
fn eval_smc(ind: &Indicators) -> StrategyResult {
    let bullish_bos = ind.current_high > ind.prev_swing_high && ind.prev_close <= ind.prev_swing_high;
    let bearish_bos = ind.current_low < ind.prev_swing_low && ind.prev_close >= ind.prev_swing_low;

    if bullish_bos && ind.order_block_bull > 0.0 
        && ind.current_close >= ind.order_block_bull * 0.998
        && ind.rsi_14 < 65.0 && ind.rsi_14 > 40.0 {
        let mut conf = 70.0;
        if ind.candle_body_ratio > 0.6 { conf += 10.0; } // displacement candle
        if ind.fair_value_gap_bull { conf += 5.0; } // FVG present
        if ind.ema_9 > ind.ema_21 { conf += 5.0; } // trend aligned
        if ind.momentum > 0.0 { conf += 5.0; }
        return StrategyResult::buy(
            format!("SMC BUY: BOS>{:.5}, OB={:.5}, RSI={:.1}, Disp={:.0}%", 
                ind.prev_swing_high, ind.order_block_bull, ind.rsi_14, ind.candle_body_ratio*100.0),
            conf, ind,
        );
    }
    if bearish_bos && ind.order_block_bear > 0.0
        && ind.current_close <= ind.order_block_bear * 1.002
        && ind.rsi_14 > 35.0 && ind.rsi_14 < 60.0 {
        let mut conf = 70.0;
        if ind.candle_body_ratio > 0.6 { conf += 10.0; }
        if ind.fair_value_gap_bear { conf += 5.0; }
        if ind.ema_9 < ind.ema_21 { conf += 5.0; }
        if ind.momentum < 0.0 { conf += 5.0; }
        return StrategyResult::sell(
            format!("SMC SELL: BOS<{:.5}, OB={:.5}, RSI={:.1}, Disp={:.0}%",
                ind.prev_swing_low, ind.order_block_bear, ind.rsi_14, ind.candle_body_ratio*100.0),
            conf, ind,
        );
    }
    StrategyResult::none()
}

// ─── 7. ICT (ปรับ: + Kill zone — London 7-10 UTC, New York 13-16 UTC) ───
fn eval_ict(ind: &Indicators) -> StrategyResult {
    // ICT works best during kill zones — penalize outside kill zones
    let utc_hour = chrono::Utc::now().hour();
    let in_london_kz = utc_hour >= 7 && utc_hour < 10;
    let in_ny_kz = utc_hour >= 13 && utc_hour < 16;
    let in_kill_zone = in_london_kz || in_ny_kz;
    let kz_bonus = if in_kill_zone { 10.0 } else { -10.0 };

    let swept_low = ind.current_low < ind.swing_low && ind.current_close > ind.swing_low;
    if swept_low && ind.fair_value_gap_bull && ind.candle_body_ratio > 0.6 && ind.rsi_14 < 60.0 {
        let mut conf: f64 = 70.0 + kz_bonus;
        if ind.ema_9 > ind.ema_21 { conf += 5.0; }
        if ind.current_close > ind.ema_50 { conf += 5.0; } // higher TF bias
        if ind.momentum > 0.0 { conf += 5.0; }
        let kz_label = if in_kill_zone { if in_london_kz { "London KZ" } else { "NY KZ" } } else { "Off-KZ" };
        return StrategyResult::buy(
            format!("ICT BUY [{}]: Sweep<{:.5}, FVG, Disp={:.0}%, RSI={:.1}",
                kz_label, ind.swing_low, ind.candle_body_ratio*100.0, ind.rsi_14),
            conf.clamp(0.0, 100.0), ind,
        );
    }
    let swept_high = ind.current_high > ind.swing_high && ind.current_close < ind.swing_high;
    if swept_high && ind.fair_value_gap_bear && ind.candle_body_ratio > 0.6 && ind.rsi_14 > 40.0 {
        let mut conf: f64 = 70.0 + kz_bonus;
        if ind.ema_9 < ind.ema_21 { conf += 5.0; }
        if ind.current_close < ind.ema_50 { conf += 5.0; }
        if ind.momentum < 0.0 { conf += 5.0; }
        let kz_label = if in_kill_zone { if in_london_kz { "London KZ" } else { "NY KZ" } } else { "Off-KZ" };
        return StrategyResult::sell(
            format!("ICT SELL [{}]: Sweep>{:.5}, FVG, Disp={:.0}%, RSI={:.1}",
                kz_label, ind.swing_high, ind.candle_body_ratio*100.0, ind.rsi_14),
            conf.clamp(0.0, 100.0), ind,
        );
    }
    // OTE fallback — only during kill zones
    if in_kill_zone && ind.current_close > ind.ema_50 && ind.current_close <= ind.fib_618 * 1.001 
        && ind.current_close >= ind.fib_618 * 0.990 && ind.rsi_14 > 40.0 && ind.rsi_14 < 60.0 {
        return StrategyResult::buy(
            format!("ICT BUY: OTE Fib61.8%={:.5}, RSI={:.1}", ind.fib_618, ind.rsi_14),
            62.0, ind,
        );
    }
    StrategyResult::none()
}

// ─── 8. Fibonacci (ปรับ: + RSI divergence hint) ───
fn eval_fibonacci(ind: &Indicators) -> StrategyResult {
    let in_uptrend = ind.current_close > ind.ema_50 && ind.ema_9 > ind.ema_21;
    let in_downtrend = ind.current_close < ind.ema_50 && ind.ema_9 < ind.ema_21;

    if in_uptrend && ind.current_close >= ind.fib_618 * 0.998 && ind.current_close <= ind.fib_500 * 1.002
        && ind.rsi_14 > 35.0 && ind.rsi_14 < 55.0 {
        let mut conf = 65.0;
        // RSI bullish divergence hint: price at low but RSI rising
        if ind.rsi_prev < ind.rsi_14 { conf += 10.0; }
        if ind.candle_body_ratio > 0.4 { conf += 5.0; } // decent candle
        if ind.momentum > 0.0 { conf += 5.0; }
        return StrategyResult::buy(
            format!("Fib BUY: 50-61.8% zone ({:.5}-{:.5}), RSI={:.1}", ind.fib_618, ind.fib_500, ind.rsi_14),
            conf, ind,
        );
    }
    let fib_382_inv = ind.fib_low + (ind.fib_high - ind.fib_low) * 0.382;
    let fib_500_inv = ind.fib_low + (ind.fib_high - ind.fib_low) * 0.500;
    if in_downtrend && ind.current_close <= fib_500_inv * 1.002 && ind.current_close >= fib_382_inv * 0.998
        && ind.rsi_14 > 45.0 && ind.rsi_14 < 65.0 {
        let mut conf = 65.0;
        if ind.rsi_prev > ind.rsi_14 { conf += 10.0; } // RSI divergence
        if ind.candle_body_ratio > 0.4 { conf += 5.0; }
        if ind.momentum < 0.0 { conf += 5.0; }
        return StrategyResult::sell(
            format!("Fib SELL: 38.2-50% zone ({:.5}-{:.5}), RSI={:.1}", fib_382_inv, fib_500_inv, ind.rsi_14),
            conf, ind,
        );
    }
    StrategyResult::none()
}

// ─── 9. Momentum Surge (ปรับ: + ATR breakout + stronger conditions) ───
fn eval_momentum(ind: &Indicators) -> StrategyResult {
    let ema_stack_bull = ind.ema_9 > ind.ema_21 && ind.ema_21 > ind.ema_50;
    let ema_stack_bear = ind.ema_9 < ind.ema_21 && ind.ema_21 < ind.ema_50;

    if ema_stack_bull && ind.rsi_prev < 50.0 && ind.rsi_14 > 50.0
        && ind.momentum > 0.15 && ind.candle_body_ratio > 0.5 {
        let mut conf = 70.0;
        if ind.momentum > 0.3 { conf += 5.0; } // strong momentum
        if ind.current_close > ind.bb_middle { conf += 5.0; } // above BB middle
        if ind.rsi_14 < 65.0 { conf += 5.0; } // not overbought yet
        return StrategyResult::buy(
            format!("Momentum BUY: EMA stack, RSI {:.1}→{:.1}, ROC={:.2}%", ind.rsi_prev, ind.rsi_14, ind.momentum),
            conf, ind,
        );
    }
    if ema_stack_bear && ind.rsi_prev > 50.0 && ind.rsi_14 < 50.0
        && ind.momentum < -0.15 && ind.candle_body_ratio > 0.5 {
        let mut conf = 70.0;
        if ind.momentum < -0.3 { conf += 5.0; }
        if ind.current_close < ind.bb_middle { conf += 5.0; }
        if ind.rsi_14 > 35.0 { conf += 5.0; }
        return StrategyResult::sell(
            format!("Momentum SELL: EMA stack, RSI {:.1}→{:.1}, ROC={:.2}%", ind.rsi_prev, ind.rsi_14, ind.momentum),
            conf, ind,
        );
    }
    StrategyResult::none()
}

// ─── 10. Session Sniper (ปรับ: + trend + stronger RSI range) ───
fn eval_session(ind: &Indicators) -> StrategyResult {
    let asian_range = ind.asian_high - ind.asian_low;
    if asian_range <= 0.0 { return StrategyResult::none(); }

    if ind.current_close > ind.asian_high && ind.prev_close <= ind.asian_high
        && ind.ema_9 > ind.ema_21 && ind.rsi_14 > 50.0 && ind.rsi_14 < 70.0 {
        let mut conf = 65.0;
        if ind.current_close > ind.ema_50 { conf += 5.0; } // higher TF aligned
        if ind.momentum > 0.0 { conf += 5.0; }
        if ind.candle_body_ratio > 0.5 { conf += 5.0; } // breakout candle strength
        return StrategyResult::buy(
            format!("Session BUY: >Asian High {:.5}, Range={:.1}pips, RSI={:.1}",
                ind.asian_high, asian_range * 10000.0, ind.rsi_14),
            conf, ind,
        );
    }
    if ind.current_close < ind.asian_low && ind.prev_close >= ind.asian_low
        && ind.ema_9 < ind.ema_21 && ind.rsi_14 < 50.0 && ind.rsi_14 > 30.0 {
        let mut conf = 65.0;
        if ind.current_close < ind.ema_50 { conf += 5.0; }
        if ind.momentum < 0.0 { conf += 5.0; }
        if ind.candle_body_ratio > 0.5 { conf += 5.0; }
        return StrategyResult::sell(
            format!("Session SELL: <Asian Low {:.5}, Range={:.1}pips, RSI={:.1}",
                ind.asian_low, asian_range * 10000.0, ind.rsi_14),
            conf, ind,
        );
    }
    StrategyResult::none()
}

// ─── 11. Engulfing Driver (ปรับ: + stricter body ratio + trend) ───
fn eval_engulfing(ind: &Indicators) -> StrategyResult {
    if ind.current_close > ind.ema_50 && ind.candle_body_ratio > 0.7 && ind.current_close > ind.prev_close {
        let mut conf = 60.0;
        if ind.ema_9 > ind.ema_21 { conf += 10.0; }
        if ind.rsi_14 > 40.0 && ind.rsi_14 < 65.0 { conf += 5.0; }
        return StrategyResult::buy(
            format!("Engulfing BUY: Body={:.0}%, above EMA50, RSI={:.1}", ind.candle_body_ratio*100.0, ind.rsi_14),
            conf, ind,
        );
    }
    if ind.current_close < ind.ema_50 && ind.candle_body_ratio > 0.7 && ind.current_close < ind.prev_close {
        let mut conf = 60.0;
        if ind.ema_9 < ind.ema_21 { conf += 10.0; }
        if ind.rsi_14 > 35.0 && ind.rsi_14 < 60.0 { conf += 5.0; }
        return StrategyResult::sell(
            format!("Engulfing SELL: Body={:.0}%, below EMA50, RSI={:.1}", ind.candle_body_ratio*100.0, ind.rsi_14),
            conf, ind,
        );
    }
    StrategyResult::none()
}

// ─── 12. Bollinger Squeeze (ปรับ: stricter BW + momentum confirm) ───
fn eval_bollinger_squeeze(ind: &Indicators) -> StrategyResult {
    let bandwidth = if ind.bb_middle > 0.0 { (ind.bb_upper - ind.bb_lower) / ind.bb_middle } else { 1.0 };
    if bandwidth < 0.02 {
        if ind.current_close > ind.bb_upper && ind.momentum > 0.0 {
            let mut conf = 65.0;
            if ind.candle_body_ratio > 0.5 { conf += 10.0; }
            if ind.rsi_14 > 50.0 { conf += 5.0; }
            return StrategyResult::buy(
                format!("Squeeze BUY: Broke BB Upper, BW={:.3}, Mom={:.2}%", bandwidth, ind.momentum),
                conf, ind,
            );
        }
        if ind.current_close < ind.bb_lower && ind.momentum < 0.0 {
            let mut conf = 65.0;
            if ind.candle_body_ratio > 0.5 { conf += 10.0; }
            if ind.rsi_14 < 50.0 { conf += 5.0; }
            return StrategyResult::sell(
                format!("Squeeze SELL: Broke BB Lower, BW={:.3}, Mom={:.2}%", bandwidth, ind.momentum),
                conf, ind,
            );
        }
    }
    StrategyResult::none()
}

// ─── 13. Pullback Sniper (ปรับ: + retest candle + RSI divergence) ───
fn eval_pullback_sniper(ind: &Indicators) -> StrategyResult {
    if ind.ema_50 > ind.ema_200 && ind.current_close > ind.ema_200 && ind.rsi_14 < 35.0 {
        let mut conf = 65.0;
        if ind.current_close > ind.current_open { conf += 10.0; } // reversal candle
        if ind.rsi_prev < ind.rsi_14 { conf += 5.0; } // RSI turning
        return StrategyResult::buy(
            format!("Pullback BUY: Uptrend (EMA50>200) + RSI {:.1} oversold", ind.rsi_14),
            conf, ind,
        );
    }
    if ind.ema_50 < ind.ema_200 && ind.current_close < ind.ema_200 && ind.rsi_14 > 65.0 {
        let mut conf = 65.0;
        if ind.current_close < ind.current_open { conf += 10.0; }
        if ind.rsi_prev > ind.rsi_14 { conf += 5.0; }
        return StrategyResult::sell(
            format!("Pullback SELL: Downtrend (EMA50<200) + RSI {:.1} overbought", ind.rsi_14),
            conf, ind,
        );
    }
    StrategyResult::none()
}

// ─── 14. Reversal Catcher (ปรับ: + candle body confirm + 2-bar pattern) ───
fn eval_reversal_catcher(ind: &Indicators) -> StrategyResult {
    if ind.rsi_14 < 25.0 && ind.rsi_prev < 25.0 && ind.current_close > ind.prev_close {
        let mut conf = 60.0;
        if ind.current_close > ind.current_open { conf += 10.0; } // bullish candle
        if ind.candle_body_ratio > 0.5 { conf += 5.0; }
        if ind.current_close > ind.bb_lower { conf += 5.0; } // back inside BB
        return StrategyResult::buy(
            format!("Reversal BUY: RSI={:.1} double oversold, turning up", ind.rsi_14),
            conf, ind,
        );
    }
    if ind.rsi_14 > 75.0 && ind.rsi_prev > 75.0 && ind.current_close < ind.prev_close {
        let mut conf = 60.0;
        if ind.current_close < ind.current_open { conf += 10.0; }
        if ind.candle_body_ratio > 0.5 { conf += 5.0; }
        if ind.current_close < ind.bb_upper { conf += 5.0; }
        return StrategyResult::sell(
            format!("Reversal SELL: RSI={:.1} double overbought, turning down", ind.rsi_14),
            conf, ind,
        );
    }
    StrategyResult::none()
}

// ─── 15. Golden Cross (ปรับ: + volume/momentum confirm) ───
fn eval_golden_cross(ind: &Indicators) -> StrategyResult {
    if ind.ema_50 > ind.ema_200 && ind.current_close > ind.ema_50 && ind.rsi_14 > 50.0 && ind.rsi_14 < 65.0 {
        let mut conf = 60.0;
        if ind.momentum > 0.0 { conf += 10.0; }
        if ind.ema_9 > ind.ema_21 { conf += 5.0; }
        return StrategyResult::buy(
            format!("Golden Cross BUY: EMA50>EMA200, RSI={:.1}, Mom={:.2}%", ind.rsi_14, ind.momentum),
            conf, ind,
        );
    }
    if ind.ema_50 < ind.ema_200 && ind.current_close < ind.ema_50 && ind.rsi_14 < 50.0 && ind.rsi_14 > 35.0 {
        let mut conf = 60.0;
        if ind.momentum < 0.0 { conf += 10.0; }
        if ind.ema_9 < ind.ema_21 { conf += 5.0; }
        return StrategyResult::sell(
            format!("Death Cross SELL: EMA50<EMA200, RSI={:.1}, Mom={:.2}%", ind.rsi_14, ind.momentum),
            conf, ind,
        );
    }
    StrategyResult::none()
}

// ─── 16. Fractal Breakout (ปรับ: + candle confirm + momentum) ───
fn eval_fractal_breakout(ind: &Indicators) -> StrategyResult {
    if ind.current_close > ind.swing_high && ind.prev_close <= ind.swing_high {
        let mut conf = 60.0;
        if ind.candle_body_ratio > 0.5 { conf += 10.0; } // strong breakout candle
        if ind.momentum > 0.1 { conf += 5.0; }
        if ind.ema_9 > ind.ema_21 { conf += 5.0; }
        return StrategyResult::buy(
            format!("Fractal BUY: >Swing High {:.5}, Body={:.0}%", ind.swing_high, ind.candle_body_ratio*100.0),
            conf, ind,
        );
    }
    if ind.current_close < ind.swing_low && ind.prev_close >= ind.swing_low {
        let mut conf = 60.0;
        if ind.candle_body_ratio > 0.5 { conf += 10.0; }
        if ind.momentum < -0.1 { conf += 5.0; }
        if ind.ema_9 < ind.ema_21 { conf += 5.0; }
        return StrategyResult::sell(
            format!("Fractal SELL: <Swing Low {:.5}, Body={:.0}%", ind.swing_low, ind.candle_body_ratio*100.0),
            conf, ind,
        );
    }
    StrategyResult::none()
}

// ─── AUTO MODE v2 — Tier-based Ensemble Agreement ───
// Tier 1 (weight 1.5x): SMC, ICT, Fibonacci — high-precision, structure-based
// Tier 2 (weight 1.2x): Trend Rider, Pullback Sniper, Momentum Surge
// Tier 3 (weight 1.0x): Bollinger Squeeze, Session Sniper, Reversal Catcher, Fractal Breakout
//
// Gate: ออกสัญญาณเมื่อ:
//   - Tier-1 ≥ 2 กลยุทธ์ชี้ทิศเดียวกัน, OR
//   - Tier-1 ≥ 1 + Tier-2 ≥ 1 ชี้ทิศเดียวกัน, OR
//   - Tier-2+3 ≥ 3 ชี้ทิศเดียวกัน (fallback)
fn eval_auto(ind: &Indicators) -> StrategyResult {
    let tier1: &[&str] = &["SMC", "ICT", "Fibonacci"];
    let tier2: &[&str] = &["Trend Rider", "Pullback Sniper", "Momentum Surge"];
    let tier3: &[&str] = &["Bollinger Squeeze", "Session Sniper", "Reversal Catcher", "Fractal Breakout"];

    let mut buy_t1 = 0usize; let mut sell_t1 = 0usize;
    let mut buy_t2 = 0usize; let mut sell_t2 = 0usize;
    let mut buy_t3 = 0usize; let mut sell_t3 = 0usize;
    let mut buy_score = 0.0f64; let mut sell_score = 0.0f64;
    let mut best_buy: Option<StrategyResult> = None;
    let mut best_sell: Option<StrategyResult> = None;
    let mut reasons_buy: Vec<String> = Vec::new();
    let mut reasons_sell: Vec<String> = Vec::new();

    let eval_tier = |strats: &[&str], weight: f64,
                     buy_cnt: &mut usize, sell_cnt: &mut usize,
                     b_score: &mut f64, s_score: &mut f64,
                     best_b: &mut Option<StrategyResult>,
                     best_s: &mut Option<StrategyResult>,
                     r_buy: &mut Vec<String>, r_sell: &mut Vec<String>| {
        for &strat in strats {
            let res = evaluate_strategy(strat, ind);
            match res.signal {
                Signal::Buy => {
                    *buy_cnt += 1;
                    *b_score += res.confidence * weight;
                    r_buy.push(format!("{}({:.0}%)", strat, res.confidence));
                    if best_b.as_ref().map(|b: &StrategyResult| res.confidence > b.confidence).unwrap_or(true) {
                        *best_b = Some(res);
                    }
                }
                Signal::Sell => {
                    *sell_cnt += 1;
                    *s_score += res.confidence * weight;
                    r_sell.push(format!("{}({:.0}%)", strat, res.confidence));
                    if best_s.as_ref().map(|b: &StrategyResult| res.confidence > b.confidence).unwrap_or(true) {
                        *best_s = Some(res);
                    }
                }
                Signal::None => {}
            }
        }
    };

    eval_tier(tier1, 1.5, &mut buy_t1, &mut sell_t1, &mut buy_score, &mut sell_score, &mut best_buy, &mut best_sell, &mut reasons_buy, &mut reasons_sell);
    eval_tier(tier2, 1.2, &mut buy_t2, &mut sell_t2, &mut buy_score, &mut sell_score, &mut best_buy, &mut best_sell, &mut reasons_buy, &mut reasons_sell);
    eval_tier(tier3, 1.0, &mut buy_t3, &mut sell_t3, &mut buy_score, &mut sell_score, &mut best_buy, &mut best_sell, &mut reasons_buy, &mut reasons_sell);

    // Gate conditions
    let buy_passes = (buy_t1 >= 2) || (buy_t1 >= 1 && buy_t2 >= 1) || (buy_t2 + buy_t3 >= 3);
    let sell_passes = (sell_t1 >= 2) || (sell_t1 >= 1 && sell_t2 >= 1) || (sell_t2 + sell_t3 >= 3);

    if !buy_passes && !sell_passes {
        return StrategyResult::none();
    }

    if buy_score >= sell_score && buy_passes {
        if let Some(mut b) = best_buy {
            let total = buy_t1 + buy_t2 + buy_t3;
            b.reason = format!("[Auto-Ensemble BUY | T1:{} T2:{} T3:{} | {}]", buy_t1, buy_t2, buy_t3, reasons_buy.join(", "));
            // Boost confidence based on agreement depth
            b.confidence = (b.confidence + (total as f64 - 1.0) * 3.0).min(95.0);
            let avg_score = buy_score / (buy_t1 + buy_t2 + buy_t3).max(1) as f64;
            b.confidence = b.confidence.max(avg_score).min(95.0);
            return b;
        }
    } else if sell_passes {
        if let Some(mut s) = best_sell {
            let total = sell_t1 + sell_t2 + sell_t3;
            s.reason = format!("[Auto-Ensemble SELL | T1:{} T2:{} T3:{} | {}]", sell_t1, sell_t2, sell_t3, reasons_sell.join(", "));
            s.confidence = (s.confidence + (total as f64 - 1.0) * 3.0).min(95.0);
            let avg_score = sell_score / (sell_t1 + sell_t2 + sell_t3).max(1) as f64;
            s.confidence = s.confidence.max(avg_score).min(95.0);
            return s;
        }
    }

    StrategyResult::none()
}

// ──────────────────────────────────────────────
//  TP/SL Price Calculation
// ──────────────────────────────────────────────

fn calc_tp_sl_price(
    direction: &str,
    price: f64,
    digits: i64,
    tp_enabled: bool, tp_mode: &str, tp_value: f64,
    sl_enabled: bool, sl_mode: &str, sl_value: f64,
) -> (f64, f64) {
    let point = 1.0 / 10f64.powi(digits as i32);
    let pip = if digits == 3 || digits == 5 { point * 10.0 } else { point };

    let tp_price = if tp_enabled {
        match tp_mode {
            "pips" => if direction == "BUY" { price + tp_value * pip } else { price - tp_value * pip },
            _ => 0.0,
        }
    } else { 0.0 };

    let sl_price = if sl_enabled {
        match sl_mode {
            "pips" => if direction == "BUY" { price - sl_value * pip } else { price + sl_value * pip },
            _ => 0.0,
        }
    } else { 0.0 };

    let final_tp = if tp_enabled && tp_mode == "rr" && sl_price > 0.0 {
        let sl_dist = (price - sl_price).abs();
        if direction == "BUY" { price + sl_dist * tp_value } else { price - sl_dist * tp_value }
    } else { tp_price };

    (final_tp, sl_price)
}

// ──────────────────────────────────────────────
//  Engine Main Loop
// ──────────────────────────────────────────────

const MAX_POSITIONS: usize = 5;
const COOLDOWN_SECS: u64 = 60;
const MAX_DRAWDOWN_PCT: f64 = 10.0;
const ENGINE_INTERVAL_SECS: u64 = 5;

pub async fn run_strategy_engine(
    db: Arc<Database>,
    tx: broadcast::Sender<String>,
    ea_state: Arc<RwLock<EaState>>,
) {
    info!("🧠 Strategy Engine started — 10 strategies + Auto mode, evaluating every {}s", ENGINE_INTERVAL_SECS);
    info!("📋 Available: {:?}", ALL_STRATEGIES);

    let mut cooldown = CooldownTracker::new();
    let mut last_account: Option<serde_json::Value> = None;
    let mut rx = tx.subscribe();

    let account_store: Arc<RwLock<Option<serde_json::Value>>> = Arc::new(RwLock::new(None));
    let account_store_writer = account_store.clone();
    tokio::spawn(async move {
        loop {
            match rx.recv().await {
                Ok(msg) => {
                    if msg.contains("\"account_data\"") {
                        if let Ok(val) = serde_json::from_str::<serde_json::Value>(&msg) {
                            let mut store = account_store_writer.write().await;
                            *store = Some(val);
                        }
                    }
                }
                Err(broadcast::error::RecvError::Lagged(_)) => continue,
                Err(_) => break,
            }
        }
    });

    let mut last_candle_requests: std::collections::HashMap<String, tokio::time::Instant> = std::collections::HashMap::new();

    loop {
        tokio::time::sleep(tokio::time::Duration::from_secs(ENGINE_INTERVAL_SECS)).await;

        let ea = ea_state.read().await;
        if !ea.connected {
            // Broadcast status: waiting for EA
            let status = serde_json::json!({
                "type": "engine_status",
                "status": "waiting_ea",
                "message": "⏳ Waiting for EA connection...",
                "setups": serde_json::Value::Array(vec![]),
            });
            let _ = tx.send(status.to_string());
            continue;
        }
        drop(ea);

        {
            let store = account_store.read().await;
            if let Some(ref val) = *store {
                last_account = Some(val.clone());
            }
        }

        let account = match &last_account {
            Some(a) => a,
            None => {
                let status = serde_json::json!({
                    "type": "engine_status",
                    "status": "waiting_account",
                    "message": "⏳ Waiting for account data...",
                    "setups": serde_json::Value::Array(vec![]),
                });
                let _ = tx.send(status.to_string());
                continue;
            },
        };

        let balance = account["balance"].as_f64().unwrap_or(0.0);
        let equity = account["equity"].as_f64().unwrap_or(0.0);
        if balance > 0.0 {
            let dd = ((balance - equity) / balance) * 100.0;
            if dd > MAX_DRAWDOWN_PCT {
                warn!("🛑 [Engine] Drawdown {:.2}% > max {:.1}% — skipping", dd, MAX_DRAWDOWN_PCT);
                let status = serde_json::json!({
                    "type": "engine_status",
                    "status": "drawdown_limit",
                    "message": format!("🛑 Drawdown {:.2}% > max {:.1}% — paused", dd, MAX_DRAWDOWN_PCT),
                    "setups": serde_json::Value::Array(vec![]),
                });
                let _ = tx.send(status.to_string());
                continue;
            }
        }

        let positions = account["positions"].as_array();
        let open_count = positions.map(|p| p.len()).unwrap_or(0);
        if open_count >= MAX_POSITIONS {
            let status = serde_json::json!({
                "type": "engine_status",
                "status": "max_positions",
                "message": format!("🛑 Max positions reached ({}/{})", open_count, MAX_POSITIONS),
                "setups": serde_json::Value::Array(vec![]),
            });
            let _ = tx.send(status.to_string());
            continue;
        }

        let setups = db.get_active_setups().await;
        let setups_arr = match setups.as_array() {
            Some(arr) if !arr.is_empty() => arr.clone(),
            _ => {
                let status = serde_json::json!({
                    "type": "engine_status",
                    "status": "no_setups",
                    "message": "💤 No active setups",
                    "setups": serde_json::Value::Array(vec![]),
                });
                let _ = tx.send(status.to_string());
                continue;
            },
        };

        let mut setup_statuses = Vec::new();
        let global_config = db.get_all_config().await;
        // Helper to grab config synchronously
        let get_cfg = |k: &str, def: &str| -> String {
            global_config.get(k).and_then(|v| v.as_str()).unwrap_or(def).to_string()
        };

        for setup in &setups_arr {
            let setup_id = setup["id"].as_i64().unwrap_or(0);
            let symbol = setup["symbol"].as_str().unwrap_or("");
            let strategy = setup["strategy"].as_str().unwrap_or("");
            let lot = setup["lotSize"].as_f64().unwrap_or(0.01);
            let timeframe = setup["timeframe"].as_str().unwrap_or("M5");
            let tp_enabled = setup["tpEnabled"].as_bool().unwrap_or(false);
            let tp_mode = setup["tpMode"].as_str().unwrap_or("pips");
            let tp_value = setup["tpValue"].as_f64().unwrap_or(50.0);
            let sl_enabled = setup["slEnabled"].as_bool().unwrap_or(false);
            let sl_mode = setup["slMode"].as_str().unwrap_or("pips");
            let sl_value = setup["slValue"].as_f64().unwrap_or(30.0);

            if symbol.is_empty() || strategy.is_empty() { continue; }

            let cooldown_key = format!("{}_{}", symbol, strategy);
            if !cooldown.can_trade(&cooldown_key, COOLDOWN_SECS) {
                setup_statuses.push(serde_json::json!({
                    "setup_id": setup_id,
                    "status": "cooldown",
                    "message": "⏱ Cooldown (60s between trades)",
                }));
                continue;
            }

            // === Risk Management Checks ===
            let emergency_stop = get_cfg("emergency_stop", "false") == "true";
            if emergency_stop {
                setup_statuses.push(serde_json::json!({
                    "setup_id": setup_id,
                    "status": "risk_stopped",
                    "message": "🚨 Emergency Stop - หยุดเทรดชั่วคราว",
                }));
                continue;
            }

            let risk_enabled = get_cfg("risk_stop_enabled", "true") == "true";
            if risk_enabled {
                // Check max positions
                let max_pos: usize = get_cfg("max_positions", "5").parse().unwrap_or(5);
                let current_pos_count = positions.map(|a| a.len()).unwrap_or(0);
                if current_pos_count >= max_pos {
                    setup_statuses.push(serde_json::json!({
                        "setup_id": setup_id,
                        "status": "risk_limit",
                        "message": format!("⛔ Max positions ({}/{})", current_pos_count, max_pos),
                    }));
                    continue;
                }

                // Check max total lot
                let max_lot: f64 = get_cfg("max_total_lot", "1.0").parse().unwrap_or(1.0);
                let current_lot: f64 = positions.map(|a| {
                    a.iter().filter_map(|p| p["volume"].as_f64()).sum()
                }).unwrap_or(0.0);
                if current_lot + lot > max_lot {
                    setup_statuses.push(serde_json::json!({
                        "setup_id": setup_id,
                        "status": "risk_limit",
                        "message": format!("⛔ Max lot ({:.2}/{:.2})", current_lot, max_lot),
                    }));
                    continue;
                }

                // Check daily drawdown
                let max_dd: f64 = get_cfg("max_daily_drawdown", "100").parse().unwrap_or(100.0);
                let current_pnl: f64 = positions.map(|a| {
                    a.iter().filter_map(|p| p["pnl"].as_f64()).sum()
                }).unwrap_or(0.0);
                if current_pnl < 0.0 && current_pnl.abs() >= max_dd {
                    // Send risk alert via Telegram
                    let bot_token = get_cfg("telegram_bot_token", "");
                    let chat_id = get_cfg("telegram_chat_id", "");
                    let notify_risk = get_cfg("notify_on_risk", "true") == "true";
                    if !bot_token.is_empty() && !chat_id.is_empty() && notify_risk {
                        let msg = crate::notify::format_risk_alert(current_pnl.abs(), max_dd);
                        tokio::spawn(async move { crate::notify::send_telegram_notify(&bot_token, &chat_id, &msg).await; });
                    }
                    setup_statuses.push(serde_json::json!({
                        "setup_id": setup_id,
                        "status": "risk_limit",
                        "message": format!("🚨 Drawdown limit! ({:.2}/${:.2})", current_pnl.abs(), max_dd),
                    }));
                    continue;
                }
            }

            let has_existing = positions.map(|ps| {
                ps.iter().any(|p| {
                    p["symbol"].as_str() == Some(symbol)
                        && p["comment"].as_str().map(|c| c.contains(&strategy.replace(' ', ""))).unwrap_or(false)
                })
            }).unwrap_or(false);
            if has_existing {
                setup_statuses.push(serde_json::json!({
                    "setup_id": setup_id,
                    "status": "has_position",
                    "message": "📌 Position already open",
                }));
                continue;
            }

            let tf_minutes = match timeframe {
                "M1" => 1, "M5" => 5, "M15" => 15, "M30" => 30,
                "H1" => 60, "H4" => 240, "D1" => 1440, _ => 5,
            };
            let candles = db.get_candles_for_strategy(symbol, tf_minutes, 100).await;
            if candles.len() < 50 { 
                let req_key = format!("{}_{}", symbol, tf_minutes);
                let can_req = match last_candle_requests.get(&req_key) {
                    Some(last) => last.elapsed().as_secs() > 30, // Request every 30s max
                    None => true,
                };
                
                if can_req {
                    info!("⏳ [Engine] Requesting historical candles for {} M{} (has {}/50)", symbol, tf_minutes, candles.len());
                    let cmd = serde_json::json!({
                        "action": "request_candles",
                        "symbol": symbol,
                        "timeframe": tf_minutes,
                        "count": 200
                    }).to_string();
                    let _ = tx.send(cmd);
                    last_candle_requests.insert(req_key, tokio::time::Instant::now());
                }
                setup_statuses.push(serde_json::json!({
                    "setup_id": setup_id,
                    "status": "loading_candles",
                    "message": format!("📊 Loading candle data ({}/50)...", candles.len()),
                }));
                continue; 
            }

            let indicators = compute_indicators(&candles);
            let result = evaluate_strategy(strategy, &indicators);

            if result.signal == Signal::None {
                setup_statuses.push(serde_json::json!({
                    "setup_id": setup_id,
                    "status": "scanning",
                    "message": "🔍 Scanning for signals...",
                }));
                continue;
            }

            // Confidence threshold check (default 60)
            let confidence_threshold: f64 = get_cfg("strategy_confidence_threshold", "60").parse().unwrap_or(60.0);
            if result.confidence < confidence_threshold {
                setup_statuses.push(serde_json::json!({
                    "setup_id": setup_id,
                    "status": "low_confidence",
                    "message": format!("⚠️ Signal found but confidence too low ({:.0}% < {:.0}%)", result.confidence, confidence_threshold),
                }));
                info!("⚠️ [Engine] {} {} — signal {} but confidence {:.0}% < threshold {:.0}%", 
                    symbol, strategy, result.reason, result.confidence, confidence_threshold);
                continue;
            }

            let direction = match result.signal {
                Signal::Buy => "BUY", Signal::Sell => "SELL", Signal::None => unreachable!(),
            };

            let price = indicators.current_close;
            let digits: i64 = if price > 100.0 { 2 } else if price > 10.0 { 3 } else { 5 };

            // Use ATR-based TP/SL if mode is "atr", otherwise use fixed pips
            let (tp_price, sl_price) = if sl_mode == "atr" || tp_mode == "atr" {
                let sl_dist = result.suggested_sl_atr;
                let tp_dist = result.suggested_tp_atr;
                if direction == "BUY" {
                    (price + tp_dist, price - sl_dist)
                } else {
                    (price - tp_dist, price + sl_dist)
                }
            } else {
                calc_tp_sl_price(
                    direction, price, digits, tp_enabled, tp_mode, tp_value, sl_enabled, sl_mode, sl_value,
                )
            };

            // === AI Confirmation Step ===
            let ai_enabled = get_cfg("ai_strategy_confirmation", "false") == "true";
            if ai_enabled {
                let api_key = get_cfg("gemini_api_key", "");
                let model = get_cfg("ai_model", "gemini-2.5-flash");
                
                // Broadcast that AI is thinking
                let thinking_status = serde_json::json!({
                    "type": "engine_status",
                    "status": "ai_confirming",
                    "message": format!("🧠 AI is validating {} signal for {}...", direction, symbol),
                    "setups": setup_statuses.clone()
                });
                let _ = tx.send(thinking_status.to_string());

                match crate::ai_engine::ai_confirm_signal(
                    &api_key, &model, symbol, direction, strategy, &result.reason,
                    result.confidence, &result.indicator_summary, tp_price, sl_price, price
                ).await {
                    Ok((approved, ai_reason)) => {
                        if !approved {
                            setup_statuses.push(serde_json::json!({
                                "setup_id": setup_id,
                                "status": "ai_rejected",
                                "message": format!("❌ AI Rejected: {}", ai_reason),
                            }));
                            info!("❌ [Engine] AI Rejected trade for {}: {}", symbol, ai_reason);
                            
                            db.log_strategy_signal(setup_id, "NONE", &format!("AI REJECTED [{}]: {}", direction, ai_reason)).await;
                            continue;
                        }
                    }
                    Err(e) => {
                        error!("⚠️ [Engine] AI Confirmation request failed: {}", e);
                        // Default to allow the trade if AI service is temporarily down, or we could strict reject.
                        // Assuming soft fallback is better to keep trading active.
                    }
                }
            }

            let comment = format!("EA24-{}", strategy.replace(' ', ""));
            let cmd = serde_json::json!({
                "action": "open_trade", "symbol": symbol, "direction": direction,
                "lot_size": lot, "sl": sl_price, "tp": tp_price, "comment": comment,
            });

            info!("📊 [Engine] SIGNAL: {} {} {} lot={} TP={:.5} SL={:.5} CONF={:.0}%", 
                direction, symbol, strategy, lot, tp_price, sl_price, result.confidence);
            info!("   Reason: {}", result.reason);
            info!("   Indicators: {}", result.indicator_summary);

            // Send Telegram notification for trade open
            let bot_token = db.get_config("telegram_bot_token").await.unwrap_or_default();
            let chat_id = db.get_config("telegram_chat_id").await.unwrap_or_default();
            let notify_open = db.get_config("notify_on_open").await.unwrap_or("true".to_string()) == "true";
            if !bot_token.is_empty() && !chat_id.is_empty() && notify_open {
                let msg = crate::notify::format_trade_open(symbol, direction, lot, price, strategy);
                tokio::spawn(async move { crate::notify::send_telegram_notify(&bot_token, &chat_id, &msg).await; });
            }

            setup_statuses.push(serde_json::json!({
                "setup_id": setup_id,
                "status": "signal_sent",
                "message": format!("🚀 {} signal sent! (Conf: {:.0}%)", direction, result.confidence),
            }));

            if let Err(e) = tx.send(cmd.to_string()) {
                error!("❌ [Engine] Failed to send trade command: {}", e);
            } else {
                cooldown.mark(&cooldown_key);
                db.log_strategy_signal(setup_id, direction, &result.reason).await;

                let alert = serde_json::json!({
                    "type": "alert", "level": "info",
                    "title": format!("Strategy Signal: {} {}", direction, symbol),
                    "message": &result.reason,
                });
                let _ = tx.send(alert.to_string());

                let signal_update = serde_json::json!({
                    "type": "strategy_signal", "setup_id": setup_id,
                    "signal": direction, "symbol": symbol, "strategy": strategy, 
                    "reason": &result.reason, "confidence": result.confidence,
                    "indicator_summary": &result.indicator_summary,
                });
                let _ = tx.send(signal_update.to_string());
            }

            if open_count + 1 >= MAX_POSITIONS { break; }
        }

        // Broadcast all setup statuses to UI
        let engine_status = serde_json::json!({
            "type": "engine_status",
            "status": "running",
            "message": format!("🧠 Evaluating {} setups | {} positions open", setups_arr.len(), open_count),
            "setups": setup_statuses,
        });
        let _ = tx.send(engine_status.to_string());
    }
}
