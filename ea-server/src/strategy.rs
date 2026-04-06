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
}

/// Signal type
#[derive(Debug, Clone, PartialEq)]
pub enum Signal {
    Buy,
    Sell,
    None,
}

/// All strategy names
pub const ALL_STRATEGIES: &[&str] = &[
    "SMC", "ICT", "Session Sniper", "Fibonacci", "Trend Rider",
    "Pullback Sniper", "Bollinger Squeeze", "Momentum Surge",
    "Reversal Catcher", "Fractal Breakout"
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
    }
}

// ──────────────────────────────────────────────
//  Strategy Signal Logic (10 strategies + Auto)
// ──────────────────────────────────────────────

pub fn evaluate_strategy(strategy: &str, ind: &Indicators) -> (Signal, String) {
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
        _ => (Signal::None, "Unknown strategy".to_string()),
    }
}

// ─── 1. Scalper Pro ───
fn eval_scalper(ind: &Indicators) -> (Signal, String) {
    if ind.rsi_14 < 35.0 && ind.ema_9 > ind.ema_21 && ind.current_close > ind.ema_9 {
        return (Signal::Buy, format!(
            "Scalper BUY: RSI={:.1}<35, EMA9>EMA21, Price above EMA9", ind.rsi_14
        ));
    }
    if ind.rsi_14 > 65.0 && ind.ema_9 < ind.ema_21 && ind.current_close < ind.ema_9 {
        return (Signal::Sell, format!(
            "Scalper SELL: RSI={:.1}>65, EMA9<EMA21, Price below EMA9", ind.rsi_14
        ));
    }
    (Signal::None, String::new())
}

// ─── 2. Trend Rider ───
fn eval_trend_rider(ind: &Indicators) -> (Signal, String) {
    let cross_up = ind.prev_ema_9 <= ind.prev_ema_21 && ind.ema_9 > ind.ema_21;
    let cross_down = ind.prev_ema_9 >= ind.prev_ema_21 && ind.ema_9 < ind.ema_21;
    if cross_up && ind.current_close > ind.ema_50 {
        return (Signal::Buy, format!("Trend BUY: EMA9 crossed above EMA21, Price>{:.5}", ind.ema_50));
    }
    if cross_down && ind.current_close < ind.ema_50 {
        return (Signal::Sell, format!("Trend SELL: EMA9 crossed below EMA21, Price<{:.5}", ind.ema_50));
    }
    (Signal::None, String::new())
}

// ─── 3. Breakout Hunter ───
fn eval_breakout(ind: &Indicators) -> (Signal, String) {
    if ind.current_close > ind.bb_upper && ind.prev_close <= ind.bb_upper && ind.rsi_14 > 55.0 {
        return (Signal::Buy, format!("Breakout BUY: Price broke BB upper, RSI={:.1}", ind.rsi_14));
    }
    if ind.current_close < ind.bb_lower && ind.prev_close >= ind.bb_lower && ind.rsi_14 < 45.0 {
        return (Signal::Sell, format!("Breakout SELL: Price broke BB lower, RSI={:.1}", ind.rsi_14));
    }
    (Signal::None, String::new())
}

// ─── 4. Mean Revert ───
fn eval_mean_revert(ind: &Indicators) -> (Signal, String) {
    if ind.rsi_14 < 25.0 && ind.current_close <= ind.bb_lower * 1.002 {
        return (Signal::Buy, format!("MeanRevert BUY: RSI={:.1}<25, Price at BB lower", ind.rsi_14));
    }
    if ind.rsi_14 > 75.0 && ind.current_close >= ind.bb_upper * 0.998 {
        return (Signal::Sell, format!("MeanRevert SELL: RSI={:.1}>75, Price at BB upper", ind.rsi_14));
    }
    (Signal::None, String::new())
}

// ─── 5. Grid Master ───
fn eval_grid(ind: &Indicators) -> (Signal, String) {
    let range = ind.bb_upper - ind.bb_lower;
    if range <= 0.0 { return (Signal::None, String::new()); }
    let pos = (ind.current_close - ind.bb_lower) / range;
    if pos < 0.20 && ind.rsi_14 < 40.0 {
        return (Signal::Buy, format!("Grid BUY: BB pos={:.0}%, RSI={:.1}", pos*100.0, ind.rsi_14));
    }
    if pos > 0.80 && ind.rsi_14 > 60.0 {
        return (Signal::Sell, format!("Grid SELL: BB pos={:.0}%, RSI={:.1}", pos*100.0, ind.rsi_14));
    }
    (Signal::None, String::new())
}

// ─── 6. SMC (Smart Money Concepts) ───
// Break of Structure + Order Block + RSI confirmation
fn eval_smc(ind: &Indicators) -> (Signal, String) {
    // Bullish BOS: current high breaks above previous swing high
    let bullish_bos = ind.current_high > ind.prev_swing_high && ind.prev_close <= ind.prev_swing_high;
    // Bearish BOS: current low breaks below previous swing low
    let bearish_bos = ind.current_low < ind.prev_swing_low && ind.prev_close >= ind.prev_swing_low;

    // BUY: Bullish BOS + price near bullish order block + RSI not overbought
    if bullish_bos && ind.order_block_bull > 0.0 
        && ind.current_close >= ind.order_block_bull * 0.998
        && ind.rsi_14 < 65.0 && ind.rsi_14 > 40.0 {
        return (Signal::Buy, format!(
            "SMC BUY: Break of Structure above {:.5}, OB zone={:.5}, RSI={:.1}",
            ind.prev_swing_high, ind.order_block_bull, ind.rsi_14
        ));
    }
    // SELL: Bearish BOS + price near bearish order block + RSI not oversold
    if bearish_bos && ind.order_block_bear > 0.0
        && ind.current_close <= ind.order_block_bear * 1.002
        && ind.rsi_14 > 35.0 && ind.rsi_14 < 60.0 {
        return (Signal::Sell, format!(
            "SMC SELL: Break of Structure below {:.5}, OB zone={:.5}, RSI={:.1}",
            ind.prev_swing_low, ind.order_block_bear, ind.rsi_14
        ));
    }
    (Signal::None, String::new())
}

// ─── 7. ICT (Inner Circle Trader) ───
// Liquidity sweep + Fair Value Gap + displacement candle
fn eval_ict(ind: &Indicators) -> (Signal, String) {
    // Bullish: sweep below swing low (liquidity grab) + bullish FVG + strong displacement candle
    let swept_low = ind.current_low < ind.swing_low && ind.current_close > ind.swing_low;
    if swept_low && ind.fair_value_gap_bull && ind.candle_body_ratio > 0.6 && ind.rsi_14 < 60.0 {
        return (Signal::Buy, format!(
            "ICT BUY: Liquidity sweep below {:.5}, Bullish FVG, Displacement={:.0}%, RSI={:.1}",
            ind.swing_low, ind.candle_body_ratio * 100.0, ind.rsi_14
        ));
    }
    // Bearish: sweep above swing high + bearish FVG + strong displacement
    let swept_high = ind.current_high > ind.swing_high && ind.current_close < ind.swing_high;
    if swept_high && ind.fair_value_gap_bear && ind.candle_body_ratio > 0.6 && ind.rsi_14 > 40.0 {
        return (Signal::Sell, format!(
            "ICT SELL: Liquidity sweep above {:.5}, Bearish FVG, Displacement={:.0}%, RSI={:.1}",
            ind.swing_high, ind.candle_body_ratio * 100.0, ind.rsi_14
        ));
    }
    // Fallback: Optimal Trade Entry (OTE) at 62-79% fib retracement in trending market
    if ind.current_close > ind.ema_50 && ind.current_close <= ind.fib_618 * 1.001 
        && ind.current_close >= ind.fib_618 * 0.990 && ind.rsi_14 > 40.0 && ind.rsi_14 < 60.0 {
        return (Signal::Buy, format!(
            "ICT BUY: OTE at Fib 61.8%={:.5}, Uptrend (Price>EMA50), RSI={:.1}",
            ind.fib_618, ind.rsi_14
        ));
    }
    (Signal::None, String::new())
}

// ─── 8. Fibonacci ───
// Fib retracement + trend direction + RSI filter
fn eval_fibonacci(ind: &Indicators) -> (Signal, String) {
    let in_uptrend = ind.current_close > ind.ema_50 && ind.ema_9 > ind.ema_21;
    let in_downtrend = ind.current_close < ind.ema_50 && ind.ema_9 < ind.ema_21;

    // BUY: Uptrend + price bounces off Fib 50-61.8% retracement zone
    if in_uptrend && ind.current_close >= ind.fib_618 * 0.998 && ind.current_close <= ind.fib_500 * 1.002
        && ind.rsi_14 > 35.0 && ind.rsi_14 < 55.0 {
        return (Signal::Buy, format!(
            "Fib BUY: Price at 50-61.8% zone ({:.5}-{:.5}), Uptrend, RSI={:.1}",
            ind.fib_618, ind.fib_500, ind.rsi_14
        ));
    }
    // SELL: Downtrend + price rejected from Fib 38.2-50% zone (retracement up)
    let fib_382_inv = ind.fib_low + (ind.fib_high - ind.fib_low) * 0.382;
    let fib_500_inv = ind.fib_low + (ind.fib_high - ind.fib_low) * 0.500;
    if in_downtrend && ind.current_close <= fib_500_inv * 1.002 && ind.current_close >= fib_382_inv * 0.998
        && ind.rsi_14 > 45.0 && ind.rsi_14 < 65.0 {
        return (Signal::Sell, format!(
            "Fib SELL: Price at 38.2-50% retracement ({:.5}-{:.5}), Downtrend, RSI={:.1}",
            fib_382_inv, fib_500_inv, ind.rsi_14
        ));
    }
    (Signal::None, String::new())
}

// ─── 9. Momentum Surge ───
// Multi-indicator momentum alignment: RSI divergence + Rate of Change + EMA stack
fn eval_momentum(ind: &Indicators) -> (Signal, String) {
    let ema_stack_bull = ind.ema_9 > ind.ema_21 && ind.ema_21 > ind.ema_50;
    let ema_stack_bear = ind.ema_9 < ind.ema_21 && ind.ema_21 < ind.ema_50;

    // BUY: Bullish EMA stack + RSI rising from <50 to >50 + positive momentum + strong candle
    if ema_stack_bull && ind.rsi_prev < 50.0 && ind.rsi_14 > 50.0
        && ind.momentum > 0.1 && ind.candle_body_ratio > 0.5 {
        return (Signal::Buy, format!(
            "Momentum BUY: EMA stack bullish, RSI crossed 50 ({:.1}→{:.1}), ROC={:.2}%",
            ind.rsi_prev, ind.rsi_14, ind.momentum
        ));
    }
    // SELL: Bearish EMA stack + RSI falling from >50 to <50 + negative momentum
    if ema_stack_bear && ind.rsi_prev > 50.0 && ind.rsi_14 < 50.0
        && ind.momentum < -0.1 && ind.candle_body_ratio > 0.5 {
        return (Signal::Sell, format!(
            "Momentum SELL: EMA stack bearish, RSI crossed 50 ({:.1}→{:.1}), ROC={:.2}%",
            ind.rsi_prev, ind.rsi_14, ind.momentum
        ));
    }
    (Signal::None, String::new())
}

// ─── 10. Session Sniper ───
// Asian session breakout during London/NY with volume confirmation
fn eval_session(ind: &Indicators) -> (Signal, String) {
    let asian_range = ind.asian_high - ind.asian_low;
    if asian_range <= 0.0 { return (Signal::None, String::new()); }

    // BUY: Price breaks above Asian High + trend alignment + RSI > 50
    if ind.current_close > ind.asian_high && ind.prev_close <= ind.asian_high
        && ind.ema_9 > ind.ema_21 && ind.rsi_14 > 50.0 && ind.rsi_14 < 75.0 {
        return (Signal::Buy, format!(
            "Session BUY: Broke Asian High {:.5}, Range={:.1}pips, RSI={:.1}",
            ind.asian_high, asian_range * 10000.0, ind.rsi_14
        ));
    }
    // SELL: Price breaks below Asian Low + trend alignment + RSI < 50
    if ind.current_close < ind.asian_low && ind.prev_close >= ind.asian_low
        && ind.ema_9 < ind.ema_21 && ind.rsi_14 < 50.0 && ind.rsi_14 > 25.0 {
        return (Signal::Sell, format!(
            "Session SELL: Broke Asian Low {:.5}, Range={:.1}pips, RSI={:.1}",
            ind.asian_low, asian_range * 10000.0, ind.rsi_14
        ));
    }
    (Signal::None, String::new())
}

// ─── 11. Engulfing Driver ───
fn eval_engulfing(ind: &Indicators) -> (Signal, String) {
    if ind.current_close > ind.ema_50 && ind.candle_body_ratio > 0.7 && ind.current_close > ind.prev_close {
        return (Signal::Buy, format!("Engulfing BUY: Strong body ({:.0}%) above EMA50", ind.candle_body_ratio * 100.0));
    }
    if ind.current_close < ind.ema_50 && ind.candle_body_ratio > 0.7 && ind.current_close < ind.prev_close {
        return (Signal::Sell, format!("Engulfing SELL: Strong body ({:.0}%) below EMA50", ind.candle_body_ratio * 100.0));
    }
    (Signal::None, String::new())
}

// ─── 12. Bollinger Squeeze ───
fn eval_bollinger_squeeze(ind: &Indicators) -> (Signal, String) {
    let bandwidth = if ind.bb_middle > 0.0 { (ind.bb_upper - ind.bb_lower) / ind.bb_middle } else { 1.0 };
    if bandwidth < 0.02 {
        if ind.current_close > ind.bb_upper { return (Signal::Buy, format!("Squeeze BUY: Broke BB Upper, BW={:.3}", bandwidth)); }
        if ind.current_close < ind.bb_lower { return (Signal::Sell, format!("Squeeze SELL: Broke BB Lower, BW={:.3}", bandwidth)); }
    }
    (Signal::None, String::new())
}

// ─── 13. Pullback Sniper ───
fn eval_pullback_sniper(ind: &Indicators) -> (Signal, String) {
    if ind.ema_50 > ind.ema_200 && ind.current_close > ind.ema_200 && ind.rsi_14 < 35.0 {
        return (Signal::Buy, format!("Pullback BUY: Uptrend (EMA50>200) + RSI Oversold ({:.1})", ind.rsi_14));
    }
    if ind.ema_50 < ind.ema_200 && ind.current_close < ind.ema_200 && ind.rsi_14 > 65.0 {
        return (Signal::Sell, format!("Pullback SELL: Downtrend (EMA50<200) + RSI Overbought ({:.1})", ind.rsi_14));
    }
    (Signal::None, String::new())
}

// ─── 14. Reversal Catcher ───
fn eval_reversal_catcher(ind: &Indicators) -> (Signal, String) {
    if ind.rsi_14 < 25.0 && ind.rsi_prev < 25.0 && ind.current_close > ind.prev_close {
        return (Signal::Buy, format!("Reversal BUY: RSI={:.1} turning up from < 25", ind.rsi_14));
    }
    if ind.rsi_14 > 75.0 && ind.rsi_prev > 75.0 && ind.current_close < ind.prev_close {
        return (Signal::Sell, format!("Reversal SELL: RSI={:.1} turning down from > 75", ind.rsi_14));
    }
    (Signal::None, String::new())
}

// ─── 15. Golden Cross ───
fn eval_golden_cross(ind: &Indicators) -> (Signal, String) {
    if ind.ema_50 > ind.ema_200 && ind.current_close > ind.ema_50 && ind.rsi_14 > 50.0 && ind.rsi_14 < 60.0 {
        return (Signal::Buy, "Golden Cross BUY: EMA50 > EMA200".to_string());
    }
    if ind.ema_50 < ind.ema_200 && ind.current_close < ind.ema_50 && ind.rsi_14 < 50.0 && ind.rsi_14 > 40.0 {
        return (Signal::Sell, "Death Cross SELL: EMA50 < EMA200".to_string());
    }
    (Signal::None, String::new())
}

// ─── 16. Fractal Breakout ───
fn eval_fractal_breakout(ind: &Indicators) -> (Signal, String) {
    if ind.current_close > ind.swing_high && ind.prev_close <= ind.swing_high {
        return (Signal::Buy, format!("Fractal BUY: Broke swing high {:.5}", ind.swing_high));
    }
    if ind.current_close < ind.swing_low && ind.prev_close >= ind.swing_low {
        return (Signal::Sell, format!("Fractal SELL: Broke swing low {:.5}", ind.swing_low));
    }
    (Signal::None, String::new())
}

// ─── AUTO MODE ───
// Evaluates ALL strategies, picks the one with the strongest signal
// Priority: SMC > ICT > Fibonacci > Momentum > others
fn eval_auto(ind: &Indicators) -> (Signal, String) {
    // Priority order — more sophisticated strategies first (Grid Master is ignored in Auto)
    let priority: &[&str] = &[
        "SMC", "ICT", "Session Sniper", "Fibonacci", "Trend Rider",
        "Pullback Sniper", "Bollinger Squeeze", "Momentum Surge",
        "Reversal Catcher", "Fractal Breakout"
    ];
    for &strat in priority {
        let (signal, reason) = evaluate_strategy(strat, ind);
        if signal != Signal::None {
            return (signal, format!("[Auto→{}] {}", strat, reason));
        }
    }
    (Signal::None, String::new())
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
            let (signal, reason) = evaluate_strategy(strategy, &indicators);

            if signal == Signal::None {
                setup_statuses.push(serde_json::json!({
                    "setup_id": setup_id,
                    "status": "scanning",
                    "message": "🔍 Scanning for signals...",
                }));
                continue;
            }

            let direction = match signal {
                Signal::Buy => "BUY", Signal::Sell => "SELL", Signal::None => unreachable!(),
            };

            let price = indicators.current_close;
            let digits: i64 = if price > 100.0 { 2 } else if price > 10.0 { 3 } else { 5 };
            let (tp_price, sl_price) = calc_tp_sl_price(
                direction, price, digits, tp_enabled, tp_mode, tp_value, sl_enabled, sl_mode, sl_value,
            );

            let comment = format!("EA24-{}", strategy.replace(' ', ""));
            let cmd = serde_json::json!({
                "action": "open_trade", "symbol": symbol, "direction": direction,
                "lot_size": lot, "sl": sl_price, "tp": tp_price, "comment": comment,
            });

            info!("📊 [Engine] SIGNAL: {} {} {} lot={} TP={:.5} SL={:.5}", direction, symbol, strategy, lot, tp_price, sl_price);
            info!("   Reason: {}", reason);

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
                "message": format!("🚀 {} signal sent!", direction),
            }));

            if let Err(e) = tx.send(cmd.to_string()) {
                error!("❌ [Engine] Failed to send trade command: {}", e);
            } else {
                cooldown.mark(&cooldown_key);
                db.log_strategy_signal(setup_id, direction, &reason).await;

                let alert = serde_json::json!({
                    "type": "alert", "level": "info",
                    "title": format!("Strategy Signal: {} {}", direction, symbol),
                    "message": &reason,
                });
                let _ = tx.send(alert.to_string());

                let signal_update = serde_json::json!({
                    "type": "strategy_signal", "setup_id": setup_id,
                    "signal": direction, "symbol": symbol, "strategy": strategy, "reason": &reason,
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
