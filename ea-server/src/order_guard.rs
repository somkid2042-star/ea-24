// ──────────────────────────────────────────────
//  Order Guard — Central Anti-Duplicate System
//
//  ป้องกันออเดอร์ซ้ำซ้อนจากทุกแหล่ง:
//    • Pipeline v9 (AI Auto-Pilot)
//    • Position Manager (HEDGE/DCA)
//    • Strategy Engine (Setup-based)
//    • UI Manual Trade
//
//  Features:
//    1. Per-symbol cooldown (configurable per source)
//    2. Pending order lock (ถ้ามี pending → block)
//    3. Max pipeline order per symbol (default 1)
//    4. Source tracking + logging
// ──────────────────────────────────────────────

use std::collections::HashMap;
use std::sync::Arc;
use std::time::Instant;
use log::info;
use tokio::sync::RwLock;

// ──────────────────────────────────────────────
//  Types
// ──────────────────────────────────────────────

/// Source of the order request
#[derive(Debug, Clone, PartialEq)]
pub enum OrderSource {
    Pipeline,         // AI Auto-Pilot (Pipeline v9)
    PositionManager,  // HEDGE / DCA
    StrategyEngine,   // Setup-based strategy
    ManualUI,         // User clicks from dashboard
}

impl std::fmt::Display for OrderSource {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            OrderSource::Pipeline => write!(f, "Pipeline"),
            OrderSource::PositionManager => write!(f, "PositionManager"),
            OrderSource::StrategyEngine => write!(f, "StrategyEngine"),
            OrderSource::ManualUI => write!(f, "ManualUI"),
        }
    }
}

/// Tracks pending order state for a symbol
#[derive(Debug, Clone)]
struct PendingOrder {
    direction: String,
    source: OrderSource,
    sent_at: Instant,
}

/// Per-symbol tracking data
#[derive(Debug, Clone)]
struct SymbolState {
    /// When the last order was confirmed for this symbol (from each source)
    last_confirmed: HashMap<String, Instant>,  // source_name -> time
    /// Currently pending (unconfirmed) order
    pending: Option<PendingOrder>,
    /// Number of pipeline-initiated positions currently open
    pipeline_position_count: usize,
}

impl SymbolState {
    fn new() -> Self {
        Self {
            last_confirmed: HashMap::new(),
            pending: None,
            pipeline_position_count: 0,
        }
    }
}

// ──────────────────────────────────────────────
//  Constants — Cooldown per source
// ──────────────────────────────────────────────

/// Cooldown after a successful Pipeline order (seconds)
const COOLDOWN_PIPELINE: u64 = 120;
/// Cooldown after a successful Position Manager order (seconds)
const COOLDOWN_POSITION_MANAGER: u64 = 300;
/// Cooldown after a successful Strategy Engine order (seconds)
const COOLDOWN_STRATEGY_ENGINE: u64 = 60;
/// Cooldown after a successful UI manual order (seconds)
const COOLDOWN_MANUAL_UI: u64 = 5;

/// Max time to wait for MT5 trade_result before considering pending expired (seconds)
const PENDING_TIMEOUT: u64 = 30;

/// Max pipeline-initiated positions per symbol
const MAX_PIPELINE_POSITIONS_PER_SYMBOL: usize = 1;

// ──────────────────────────────────────────────
//  OrderGuard
// ──────────────────────────────────────────────

#[derive(Clone)]
pub struct OrderGuard {
    state: Arc<RwLock<HashMap<String, SymbolState>>>,
}

impl OrderGuard {
    pub fn new() -> Self {
        Self {
            state: Arc::new(RwLock::new(HashMap::new())),
        }
    }

    /// Check if an order can be opened for this symbol from this source.
    /// Returns `Ok(())` if allowed, `Err(reason)` if blocked.
    pub async fn can_open_order(
        &self,
        symbol: &str,
        direction: &str,
        source: &OrderSource,
    ) -> Result<(), String> {
        let mut state = self.state.write().await;
        let sym_state = state.entry(symbol.to_string()).or_insert_with(SymbolState::new);

        // 1. Check pending order lock
        if let Some(ref pending) = sym_state.pending {
            let elapsed = pending.sent_at.elapsed().as_secs();
            if elapsed < PENDING_TIMEOUT {
                let msg = format!(
                    "🔒 [OrderGuard] BLOCKED {} {} on {} — pending {} order from {} ({}s ago)",
                    source, direction, symbol, pending.direction, pending.source, elapsed
                );
                info!("{}", msg);
                return Err(msg);
            } else {
                // Pending expired — clear it
                info!(
                    "⏰ [OrderGuard] Pending order for {} expired ({}s) — clearing lock",
                    symbol, elapsed
                );
                sym_state.pending = None;
            }
        }

        // 2. Check per-source cooldown
        let cooldown_secs = get_cooldown(source);
        let source_key = source.to_string();
        if let Some(last) = sym_state.last_confirmed.get(&source_key) {
            let elapsed = last.elapsed().as_secs();
            if elapsed < cooldown_secs {
                let remaining = cooldown_secs - elapsed;
                let msg = format!(
                    "⏱️ [OrderGuard] COOLDOWN {} {} on {} — {}s remaining (cooldown: {}s)",
                    source, direction, symbol, remaining, cooldown_secs
                );
                info!("{}", msg);
                return Err(msg);
            }
        }

        // 3. Max pipeline positions per symbol
        if *source == OrderSource::Pipeline {
            if sym_state.pipeline_position_count >= MAX_PIPELINE_POSITIONS_PER_SYMBOL {
                let msg = format!(
                    "🛑 [OrderGuard] BLOCKED Pipeline {} on {} — already {} pipeline position(s) (max: {})",
                    direction, symbol, sym_state.pipeline_position_count, MAX_PIPELINE_POSITIONS_PER_SYMBOL
                );
                info!("{}", msg);
                return Err(msg);
            }
        }

        Ok(())
    }

    /// Mark that an order command has been sent to MT5.
    /// Sets the pending lock until we get a trade_result back.
    pub async fn mark_order_sent(
        &self,
        symbol: &str,
        direction: &str,
        source: &OrderSource,
    ) {
        let mut state = self.state.write().await;
        let sym_state = state.entry(symbol.to_string()).or_insert_with(SymbolState::new);
        
        sym_state.pending = Some(PendingOrder {
            direction: direction.to_string(),
            source: source.clone(),
            sent_at: Instant::now(),
        });

        info!(
            "📤 [OrderGuard] Order SENT: {} {} on {} — lock set",
            source, direction, symbol
        );
    }

    /// Mark that MT5 confirmed the order was opened successfully.
    /// Clears the pending lock and starts the cooldown timer.
    pub async fn mark_order_confirmed(
        &self,
        symbol: &str,
        _ticket: i64,
    ) {
        let mut state = self.state.write().await;
        let sym_state = state.entry(symbol.to_string()).or_insert_with(SymbolState::new);

        // Record the source before clearing pending
        let source_key = sym_state.pending.as_ref()
            .map(|p| p.source.to_string())
            .unwrap_or_else(|| "Unknown".to_string());
        
        let was_pipeline = sym_state.pending.as_ref()
            .map(|p| p.source == OrderSource::Pipeline)
            .unwrap_or(false);

        // Start cooldown for this source
        sym_state.last_confirmed.insert(source_key.clone(), Instant::now());

        // Track pipeline position count
        if was_pipeline {
            sym_state.pipeline_position_count += 1;
        }

        // Clear pending lock
        sym_state.pending = None;

        info!(
            "✅ [OrderGuard] Order CONFIRMED on {} (source: {}) — cooldown started, pipeline_pos: {}",
            symbol, source_key, sym_state.pipeline_position_count
        );
    }

    /// Mark that MT5 rejected/failed the order.
    /// Clears the pending lock so a retry is possible.
    pub async fn mark_order_failed(
        &self,
        symbol: &str,
    ) {
        let mut state = self.state.write().await;
        let sym_state = state.entry(symbol.to_string()).or_insert_with(SymbolState::new);

        let source_key = sym_state.pending.as_ref()
            .map(|p| p.source.to_string())
            .unwrap_or_else(|| "Unknown".to_string());

        sym_state.pending = None;

        info!(
            "❌ [OrderGuard] Order FAILED on {} (source: {}) — lock cleared for retry",
            symbol, source_key
        );
    }

    /// Update pipeline position count when a position is closed.
    /// Called when we detect a position was closed (from account_data updates).
    pub async fn decrement_pipeline_positions(&self, symbol: &str) {
        let mut state = self.state.write().await;
        if let Some(sym_state) = state.get_mut(symbol) {
            if sym_state.pipeline_position_count > 0 {
                sym_state.pipeline_position_count -= 1;
                info!(
                    "📉 [OrderGuard] Pipeline position closed on {} — count: {}",
                    symbol, sym_state.pipeline_position_count
                );
            }
        }
    }

    /// Sync pipeline position counts from actual MT5 positions.
    /// Should be called periodically with current positions data.
    pub async fn sync_positions(&self, positions: &[serde_json::Value]) {
        let mut state = self.state.write().await;
        
        // Count pipeline positions per symbol from actual MT5 data
        let mut counts: HashMap<String, usize> = HashMap::new();
        for pos in positions {
            let sym = pos["symbol"].as_str().unwrap_or("");
            let comment = pos["comment"].as_str().unwrap_or("");
            // Count positions opened by Pipeline (EA24v8, EA24v9, EA24-pipeline)
            if comment.contains("EA24v") || comment.contains("EA24-pipeline") {
                *counts.entry(sym.to_string()).or_insert(0) += 1;
            }
        }

        // Update all tracked symbols
        for (sym, sym_state) in state.iter_mut() {
            let actual_count = counts.get(sym.as_str()).copied().unwrap_or(0);
            if sym_state.pipeline_position_count != actual_count {
                info!(
                    "🔄 [OrderGuard] Sync {} pipeline positions: {} → {}",
                    sym, sym_state.pipeline_position_count, actual_count
                );
                sym_state.pipeline_position_count = actual_count;
            }
        }
    }

    /// Get cooldown remaining for a symbol+source (for UI display)
    pub async fn get_cooldown_remaining(&self, symbol: &str, source: &OrderSource) -> u64 {
        let state = self.state.read().await;
        if let Some(sym_state) = state.get(symbol) {
            let source_key = source.to_string();
            let cooldown_secs = get_cooldown(source);
            if let Some(last) = sym_state.last_confirmed.get(&source_key) {
                let elapsed = last.elapsed().as_secs();
                if elapsed < cooldown_secs {
                    return cooldown_secs - elapsed;
                }
            }
        }
        0
    }

    /// Check if a symbol has a pending order
    pub async fn has_pending(&self, symbol: &str) -> bool {
        let state = self.state.read().await;
        if let Some(sym_state) = state.get(symbol) {
            if let Some(ref pending) = sym_state.pending {
                return pending.sent_at.elapsed().as_secs() < PENDING_TIMEOUT;
            }
        }
        false
    }
}

/// Get cooldown duration for a given source
fn get_cooldown(source: &OrderSource) -> u64 {
    match source {
        OrderSource::Pipeline => COOLDOWN_PIPELINE,
        OrderSource::PositionManager => COOLDOWN_POSITION_MANAGER,
        OrderSource::StrategyEngine => COOLDOWN_STRATEGY_ENGINE,
        OrderSource::ManualUI => COOLDOWN_MANUAL_UI,
    }
}
