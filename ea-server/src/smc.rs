use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Candle {
    pub time: i64,
    pub open: f64,
    pub high: f64,
    pub low: f64,
    pub close: f64,
}

#[derive(Debug, Clone, PartialEq)]
pub enum Signal {
    Buy,
    Sell,
}

#[derive(Debug, Clone, PartialEq)]
pub enum Trend {
    Bullish,
    Bearish,
    Flat,
}

#[derive(Debug, Clone)]
pub struct SwingPoint {
    pub time: i64,
    pub price: f64,
    pub is_high: bool,
    pub index: usize,
}

#[derive(Debug, Clone)]
pub struct OrderBlock {
    pub time: i64,
    pub top: f64,
    pub bottom: f64,
    pub is_bullish: bool,
    pub mitigated: bool,
}

/// Analyze an array of historical candles (oldest to newest) to detect SMC signals.
pub fn analyze_smc(candles: &[Candle]) -> Option<Signal> {
    if candles.len() < 10 {
        return None;
    }

    let left_bars = 2;
    let right_bars = 2;

    let mut swing_highs: Vec<SwingPoint> = Vec::new();
    let mut swing_lows: Vec<SwingPoint> = Vec::new();
    let mut trend = Trend::Flat;
    let mut active_ob: Option<OrderBlock> = None;

    // Detect Swing Points
    for i in left_bars..(candles.len().saturating_sub(right_bars)) {
        let current = &candles[i];
        
        let mut is_swing_high = true;
        let mut is_swing_low = true;

        for j in (i - left_bars)..=(i + right_bars) {
            if i == j { continue; }
            if candles[j].high > current.high { is_swing_high = false; }
            if candles[j].low < current.low { is_swing_low = false; }
        }

        if is_swing_high {
            swing_highs.push(SwingPoint { time: current.time, price: current.high, is_high: true, index: i });
        }
        if is_swing_low {
            swing_lows.push(SwingPoint { time: current.time, price: current.low, is_high: false, index: i });
        }
    }

    // Trace Market Structure to find the latest valid Order Block
    // Replay the chart forward to identify BOS/CHOCH
    for i in 0..candles.len() {
        let c = &candles[i];

        // Did we break the last valid swing high?
        if let Some(last_sh) = swing_highs.iter().rev().find(|sh| sh.index < i) {
            if c.close > last_sh.price {
                // Bullish Break (BOS or CHOCH)
                if trend != Trend::Bullish {
                    trend = Trend::Bullish;
                }
                
                // Identify Bullish OB: the last down candle before this upward impulse
                if active_ob.is_none() || !active_ob.as_ref().unwrap().is_bullish {
                    // search backwards from `i` to find the lowest point or last red candle
                    let mut ob_idx = i.saturating_sub(1);
                    while ob_idx > 0 {
                        if candles[ob_idx].close < candles[ob_idx].open { // down candle
                            active_ob = Some(OrderBlock {
                                time: candles[ob_idx].time,
                                top: candles[ob_idx].high,
                                bottom: candles[ob_idx].low,
                                is_bullish: true,
                                mitigated: false,
                            });
                            break;
                        }
                        ob_idx -= 1;
                    }
                }
            }
        }

        // Did we break the last valid swing low?
        if let Some(last_sl) = swing_lows.iter().rev().find(|sl| sl.index < i) {
            if c.close < last_sl.price {
                // Bearish Break (BOS or CHOCH)
                if trend != Trend::Bearish {
                    trend = Trend::Bearish;
                }

                // Identify Bearish OB: the last up candle before this downward impulse
                if active_ob.is_none() || active_ob.as_ref().unwrap().is_bullish {
                    let mut ob_idx = i.saturating_sub(1);
                    while ob_idx > 0 {
                        if candles[ob_idx].close > candles[ob_idx].open { // up candle
                            active_ob = Some(OrderBlock {
                                time: candles[ob_idx].time,
                                top: candles[ob_idx].high,
                                bottom: candles[ob_idx].low,
                                is_bullish: false,
                                mitigated: false,
                            });
                            break;
                        }
                        ob_idx -= 1;
                    }
                }
            }
        }

        // Check if the current candle mitigates the active OB
        if let Some(ob) = active_ob.as_mut() {
            if !ob.mitigated {
                if ob.is_bullish {
                    // If price dips into the Bullish OB
                    if c.low <= ob.top && c.low >= ob.bottom {
                        ob.mitigated = true;
                        // Return signal if this is the very last/live candle
                        if i == candles.len() - 1 {
                            return Some(Signal::Buy);
                        }
                    } else if c.close < ob.bottom {
                        // OB invalidated
                        ob.mitigated = true;
                    }
                } else {
                    // If price rallies into the Bearish OB
                    if c.high >= ob.bottom && c.high <= ob.top {
                        ob.mitigated = true;
                        // Return signal if this is the very last/live candle
                        if i == candles.len() - 1 {
                            return Some(Signal::Sell);
                        }
                    } else if c.close > ob.top {
                        // OB invalidated
                        ob.mitigated = true;
                    }
                }
            }
        }
    }

    None
}
