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
pub struct FVG {
    pub time: i64,
    pub top: f64,
    pub bottom: f64,
    pub is_bullish: bool,
    pub mitigated: bool,
}

/// Analyze an array of historical candles (oldest to newest) to detect ICT signals.
pub fn analyze_ict(candles: &[Candle]) -> Option<Signal> {
    if candles.len() < 10 {
        return None;
    }

    let left_bars = 5; // Lookback for liquidity sweeps
    let right_bars = 2; // Confirmation bars

    let mut swing_highs: Vec<SwingPoint> = Vec::new();
    let mut swing_lows: Vec<SwingPoint> = Vec::new();
    
    let mut trend = Trend::Flat;
    let mut active_fvg: Option<FVG> = None;
    
    // We track if a liquidity sweep recently occurred.
    // Time index of the most recent sweep.
    let mut last_bsl_sweep_idx: Option<usize> = None;
    let mut last_ssl_sweep_idx: Option<usize> = None;

    // Detect Swing Points (Liquidity Pools)
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

    // Iterate through chart to find sweeps, MSS, and FVGs
    for i in 2..candles.len() {
        let c = &candles[i];

        // 1. Detect Liquidity Sweeps
        // Check if price broke above a Swing High (Buy-Side Liquidity Sweep)
        if let Some(sh) = swing_highs.iter().rev().find(|sh| sh.index < i) {
            if c.high > sh.price && candles[i.saturating_sub(1)].high <= sh.price {
                // We just swept a high
                last_bsl_sweep_idx = Some(i);
            }
        }
        
        // Check if price broke below a Swing Low (Sell-Side Liquidity Sweep)
        if let Some(sl) = swing_lows.iter().rev().find(|sl| sl.index < i) {
            if c.low < sl.price && candles[i.saturating_sub(1)].low >= sl.price {
                // We just swept a low
                last_ssl_sweep_idx = Some(i);
            }
        }

        // 2. Track Market Structure Shift (MSS)
        // If we recently swept BSL, look for a Bearish MSS
        if let Some(bsl_idx) = last_bsl_sweep_idx {
            // Need to break structure lower to confirm MSS
            if let Some(last_sl) = swing_lows.iter().rev().find(|sl| sl.index > bsl_idx && sl.index < i) {
                if c.close < last_sl.price {
                    // Bearish MSS Confirmed
                    if trend != Trend::Bearish {
                        trend = Trend::Bearish;
                        
                        // Look for a Bearish FVG that formed during this displacement
                        // We check the last few candles for a gap
                        let mut fvg_found = false;
                        for mut_idx in (bsl_idx..=i).rev() {
                            if mut_idx < 2 { continue; }
                            let c1 = &candles[mut_idx - 2];
                            // let c2 = &candles[mut_idx - 1]; // The displacement candle
                            let c3 = &candles[mut_idx];

                            // Bearish FVG: C1 Low > C3 High
                            if c1.low > c3.high {
                                active_fvg = Some(FVG {
                                    time: candles[mut_idx - 1].time,
                                    top: c1.low,
                                    bottom: c3.high,
                                    is_bullish: false,
                                    mitigated: false,
                                });
                                fvg_found = true;
                                break;
                            }
                        }
                        
                        if fvg_found {
                            last_bsl_sweep_idx = None; // Reset until another sweep
                        }
                    }
                }
            } else {
                // If there's no immediate inner-swing-low yet, breaking the previous major swing low counts as MSS
                if let Some(maj_sl) = swing_lows.iter().rev().find(|sl| sl.index < bsl_idx) {
                    if c.close < maj_sl.price {
                       if trend != Trend::Bearish {
                            trend = Trend::Bearish;
                            let mut fvg_found = false;
                            for mut_idx in (bsl_idx..=i).rev() {
                                if mut_idx < 2 { continue; }
                                let c1 = &candles[mut_idx - 2];
                                let c3 = &candles[mut_idx];
                                if c1.low > c3.high {
                                    active_fvg = Some(FVG {
                                        time: candles[mut_idx - 1].time,
                                        top: c1.low,
                                        bottom: c3.high,
                                        is_bullish: false,
                                        mitigated: false,
                                    });
                                    fvg_found = true;
                                    break;
                                }
                            }
                            if fvg_found { last_bsl_sweep_idx = None; }
                       }
                    }
                }
            }
        }

        // If we recently swept SSL, look for a Bullish MSS
        if let Some(ssl_idx) = last_ssl_sweep_idx {
            if let Some(last_sh) = swing_highs.iter().rev().find(|sh| sh.index > ssl_idx && sh.index < i) {
                if c.close > last_sh.price {
                    // Bullish MSS Confirmed
                    if trend != Trend::Bullish {
                        trend = Trend::Bullish;
                        
                        let mut fvg_found = false;
                        for mut_idx in (ssl_idx..=i).rev() {
                            if mut_idx < 2 { continue; }
                            let c1 = &candles[mut_idx - 2];
                            let c3 = &candles[mut_idx];

                            // Bullish FVG: C1 High < C3 Low
                            if c1.high < c3.low {
                                active_fvg = Some(FVG {
                                    time: candles[mut_idx - 1].time,
                                    top: c3.low,
                                    bottom: c1.high,
                                    is_bullish: true,
                                    mitigated: false,
                                });
                                fvg_found = true;
                                break;
                            }
                        }
                        if fvg_found { last_ssl_sweep_idx = None; }
                    }
                }
            } else {
                 if let Some(maj_sh) = swing_highs.iter().rev().find(|sh| sh.index < ssl_idx) {
                    if c.close > maj_sh.price {
                       if trend != Trend::Bullish {
                            trend = Trend::Bullish;
                            let mut fvg_found = false;
                            for mut_idx in (ssl_idx..=i).rev() {
                                if mut_idx < 2 { continue; }
                                let c1 = &candles[mut_idx - 2];
                                let c3 = &candles[mut_idx];
                                if c1.high < c3.low {
                                    active_fvg = Some(FVG {
                                        time: candles[mut_idx - 1].time,
                                        top: c3.low,
                                        bottom: c1.high,
                                        is_bullish: true,
                                        mitigated: false,
                                    });
                                    fvg_found = true;
                                    break;
                                }
                            }
                            if fvg_found { last_ssl_sweep_idx = None; }
                       }
                    }
                }
            }
        }

        // 3. Evaluate FVG Mitigation / Signal Generation
        if let Some(fvg) = active_fvg.as_mut() {
            if !fvg.mitigated {
                if fvg.is_bullish {
                    // Tap into Bullish FVG
                    if c.low <= fvg.top && c.low >= fvg.bottom {
                        fvg.mitigated = true;
                        if i == candles.len() - 1 {
                            return Some(Signal::Buy);
                        }
                    } else if c.close < fvg.bottom {
                        // Invalidate FVG
                        fvg.mitigated = true;
                    }
                } else {
                    // Tap into Bearish FVG
                    if c.high >= fvg.bottom && c.high <= fvg.top {
                        fvg.mitigated = true;
                        if i == candles.len() - 1 {
                            return Some(Signal::Sell);
                        }
                    } else if c.close > fvg.top {
                        // Invalidate
                        fvg.mitigated = true;
                    }
                }
            }
        }
    }

    None
}
