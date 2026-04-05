use log::{error, info};
use sqlx::{postgres::PgPoolOptions, PgPool};
use tokio::sync::mpsc;
use chrono::{DateTime, Utc};
use std::collections::{HashMap, BTreeMap};
use std::sync::Arc;
use tokio::sync::RwLock;

/// Thread-safe Async database wrapper
#[derive(Clone)]
pub struct Database {
    pub pool: PgPool,
    tick_tx: mpsc::Sender<TickRecord>,
    pub mem_candles: Arc<RwLock<HashMap<String, BTreeMap<i64, crate::strategy::Candle>>>>,
}

#[derive(Debug)]
struct TickRecord {
    symbol: String,
    bid: f64,
    ask: f64,
    spread: f64,
    timestamp: DateTime<Utc>,
}

impl Database {
    pub fn size(&self) -> u32 {
        self.pool.size()
    }

    /// Initialize DB, run migrations, and start background tick batcher
    pub async fn init(db_url: &str) -> Result<Self, String> {
        info!("Connecting to PostgreSQL at {}...", db_url);
        let pool = PgPoolOptions::new()
            .max_connections(20)
            .connect(db_url)
            .await
            .map_err(|e| format!("Failed to connect to database: {}", e))?;

        Self::create_tables(&pool).await?;
        Self::insert_defaults(&pool).await?;

        // Channel for batching high-frequency ticks
        let (tick_tx, mut tick_rx) = mpsc::channel::<TickRecord>(100_000);
        let batch_pool = pool.clone();
        
        let mem_candles = Arc::new(RwLock::new(HashMap::new()));
        let mem_candles_clone = mem_candles.clone();

        tokio::spawn(async move {
            let mut batch = Vec::with_capacity(500);
            let mut timer = tokio::time::interval(std::time::Duration::from_secs(1));
            
            loop {
                tokio::select! {
                    Some(tick) = tick_rx.recv() => {
                        let t_sec = tick.timestamp.timestamp();
                        let m1_time = (t_sec / 60) * 60;
                        
                        {
                            let mut map = mem_candles_clone.write().await;
                            let symbol_candles = map.entry(tick.symbol.clone()).or_insert_with(BTreeMap::new);
                            
                            let candle = symbol_candles.entry(m1_time).or_insert(crate::strategy::Candle {
                                time: m1_time,
                                open: tick.bid,
                                high: tick.bid,
                                low: tick.bid,
                                close: tick.bid,
                            });
                            
                            if tick.bid > candle.high { candle.high = tick.bid; }
                            if tick.bid < candle.low { candle.low = tick.bid; }
                            candle.close = tick.bid;
                            
                            // Prune memory buffer (keep last 1440 candles = 24h of M1)
                            if symbol_candles.len() > 1500 {
                                let key_to_remove = *symbol_candles.keys().next().unwrap();
                                symbol_candles.remove(&key_to_remove);
                            }
                        }

                        batch.push(tick);
                        if batch.len() >= 500 {
                            Self::flush_ticks(&batch_pool, &mut batch).await;
                        }
                    }
                    _ = timer.tick() => {
                        if !batch.is_empty() {
                            Self::flush_ticks(&batch_pool, &mut batch).await;
                        }
                    }
                }
            }
        });

        info!("✅ Database connected, In-Memory Cache enabled, and Tick Batcher running");
        let db = Database { pool, tick_tx, mem_candles };
        
        // Pre-load historical candles from DB into memory on startup
        db.load_candles_from_db().await;
        
        Ok(db)
    }

    async fn create_tables(pool: &PgPool) -> Result<(), String> {
        let schema = "
            CREATE TABLE IF NOT EXISTS tick_log (
                id          BIGSERIAL,
                symbol      TEXT NOT NULL,
                bid         DOUBLE PRECISION NOT NULL,
                ask         DOUBLE PRECISION NOT NULL,
                spread      DOUBLE PRECISION NOT NULL DEFAULT 0,
                timestamp   TIMESTAMPTZ NOT NULL DEFAULT NOW()
            );

            CREATE TABLE IF NOT EXISTS trade_log (
                id          BIGSERIAL PRIMARY KEY,
                action      TEXT NOT NULL,
                symbol      TEXT,
                direction   TEXT,
                lot         DOUBLE PRECISION,
                price       DOUBLE PRECISION,
                pnl         DOUBLE PRECISION,
                source      TEXT DEFAULT 'ea',
                timestamp   TIMESTAMPTZ NOT NULL DEFAULT NOW()
            );

            CREATE TABLE IF NOT EXISTS server_config (
                key         TEXT PRIMARY KEY,
                value       TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS trade_setups (
                id                      BIGSERIAL PRIMARY KEY,
                symbol                  TEXT NOT NULL,
                strategy                TEXT NOT NULL,
                timeframe               TEXT NOT NULL DEFAULT 'M5',
                lot_size                DOUBLE PRECISION NOT NULL DEFAULT 0.01,
                risk_percent            DOUBLE PRECISION NOT NULL DEFAULT 2.0,
                mt5_instance            TEXT NOT NULL DEFAULT '',
                tp_enabled              BOOLEAN NOT NULL DEFAULT false,
                tp_mode                 TEXT NOT NULL DEFAULT 'pips',
                tp_value                DOUBLE PRECISION NOT NULL DEFAULT 50.0,
                sl_enabled              BOOLEAN NOT NULL DEFAULT false,
                sl_mode                 TEXT NOT NULL DEFAULT 'pips',
                sl_value                DOUBLE PRECISION NOT NULL DEFAULT 30.0,
                trailing_stop_enabled   BOOLEAN NOT NULL DEFAULT false,
                trailing_stop_points    DOUBLE PRECISION NOT NULL DEFAULT 50.0,
                status                  TEXT NOT NULL DEFAULT 'paused',
                created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
            );

            CREATE TABLE IF NOT EXISTS trade_history (
                id          BIGSERIAL PRIMARY KEY,
                ticket      BIGINT UNIQUE NOT NULL,
                order_id    BIGINT,
                pos_id      BIGINT,
                symbol      TEXT NOT NULL,
                type        TEXT NOT NULL,
                volume      DOUBLE PRECISION NOT NULL,
                price       DOUBLE PRECISION NOT NULL,
                profit      DOUBLE PRECISION NOT NULL,
                swap        DOUBLE PRECISION NOT NULL DEFAULT 0,
                commission  DOUBLE PRECISION NOT NULL DEFAULT 0,
                magic       BIGINT NOT NULL DEFAULT 0,
                time        TEXT NOT NULL,
                comment     TEXT
            );

            CREATE TABLE IF NOT EXISTS strategy_signals (
                id          BIGSERIAL PRIMARY KEY,
                setup_id    BIGINT NOT NULL,
                signal_type TEXT NOT NULL,
                reason      TEXT,
                executed    BOOLEAN DEFAULT false,
                timestamp   TIMESTAMPTZ NOT NULL DEFAULT NOW()
            );

            CREATE INDEX IF NOT EXISTS idx_tick_symbol ON tick_log(symbol);
            CREATE INDEX IF NOT EXISTS idx_tick_time ON tick_log(timestamp DESC);
            CREATE INDEX IF NOT EXISTS idx_trade_time ON trade_log(timestamp DESC);
            CREATE INDEX IF NOT EXISTS idx_history_time ON trade_history(time);
            CREATE INDEX IF NOT EXISTS idx_signal_time ON strategy_signals(timestamp DESC);
        ";
        for q in schema.split(';') {
            let query_trimmed = q.trim();
            if !query_trimmed.is_empty() {
                sqlx::query(query_trimmed)
                    .execute(pool)
                    .await
                    .map_err(|e| format!("Tables err: {}", e))?;
            }
        }

        // Enable TimescaleDB Extension if available, ignore errors
        let _ = sqlx::query("CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE").execute(pool).await;

        // Convert tables to hypertables
        let hyper_queries = [
            "SELECT create_hypertable('tick_log', 'timestamp', if_not_exists => TRUE, migrate_data => TRUE)",
            "CREATE MATERIALIZED VIEW IF NOT EXISTS candles_m1 WITH (timescaledb.continuous) AS SELECT symbol, time_bucket('1 minute', timestamp) AS time, first(bid, timestamp) as open, max(bid) as high, min(bid) as low, last(bid, timestamp) as close FROM tick_log GROUP BY symbol, time_bucket('1 minute', timestamp)",
        ];
        
        for hq in hyper_queries {
            let _ = sqlx::query(hq).execute(pool).await;
        }

        Ok(())
    }

    async fn insert_defaults(pool: &PgPool) -> Result<(), String> {
        let defaults = vec![
            ("ws_port", "8080"),
            ("tcp_port", "8081"),
            ("http_port", "4173"),
            ("backup_interval_hours", "24"),
            ("tick_retention_days", "30"),
        ];
        
        for (key, value) in defaults {
            sqlx::query("INSERT INTO server_config (key, value) VALUES ($1, $2) ON CONFLICT (key) DO NOTHING")
                .bind(key)
                .bind(value)
                .execute(pool)
                .await
                .map_err(|e| format!("Default config err: {}", e))?;
        }
        Ok(())
    }

    async fn flush_ticks(pool: &PgPool, batch: &mut Vec<TickRecord>) {
        if batch.is_empty() { return; }
        
        let mut symbols = Vec::with_capacity(batch.len());
        let mut bids = Vec::with_capacity(batch.len());
        let mut asks = Vec::with_capacity(batch.len());
        let mut spreads = Vec::with_capacity(batch.len());
        let mut timestamps = Vec::with_capacity(batch.len());

        for t in batch.iter() {
            symbols.push(t.symbol.clone());
            bids.push(t.bid);
            asks.push(t.ask);
            spreads.push(t.spread);
            timestamps.push(t.timestamp);
        }

        let query = "
            INSERT INTO tick_log (symbol, bid, ask, spread, timestamp)
            SELECT * FROM UNNEST($1::text[], $2::double precision[], $3::double precision[], $4::double precision[], $5::timestamptz[])
        ";

        if let Err(e) = sqlx::query(query)
            .bind(symbols).bind(bids).bind(asks).bind(spreads).bind(timestamps)
            .execute(pool).await 
        {
            error!("❌ Batch insert ticks failed: {}", e);
        }

        batch.clear();
    }

    pub async fn insert_candles_as_ticks(&self, symbol: &str, candles: &serde_json::Value) {
        let arr = match candles.as_array() {
            Some(a) => a,
            None => return,
        };
        
        let mut symbols = Vec::with_capacity(arr.len() * 4);
        let mut bids = Vec::with_capacity(arr.len() * 4);
        let mut asks = Vec::with_capacity(arr.len() * 4);
        let mut spreads = Vec::with_capacity(arr.len() * 4);
        let mut timestamps = Vec::with_capacity(arr.len() * 4);

        for c in arr {
            let t = c["t"].as_i64().unwrap_or(0);
            let o = c["o"].as_f64().unwrap_or(0.0);
            let h = c["h"].as_f64().unwrap_or(0.0);
            let l = c["l"].as_f64().unwrap_or(0.0);
            let c_val = c["c"].as_f64().unwrap_or(0.0);

            if t == 0 { continue; }
            let dt = match chrono::DateTime::from_timestamp(t, 0) {
                Some(d) => d,
                None => continue,
            };

            // Insert 4 mock ticks to simulate OHLC exactly
            // 1. Open
            symbols.push(symbol.to_string());
            bids.push(o);
            asks.push(o);
            spreads.push(0.0);
            timestamps.push(dt);
            
            // 2. High
            symbols.push(symbol.to_string());
            bids.push(h);
            asks.push(h);
            spreads.push(0.0);
            timestamps.push(dt + chrono::Duration::seconds(1));
            
            // 3. Low
            symbols.push(symbol.to_string());
            bids.push(l);
            asks.push(l);
            spreads.push(0.0);
            timestamps.push(dt + chrono::Duration::seconds(2));
            
            // 4. Close
            symbols.push(symbol.to_string());
            bids.push(c_val);
            asks.push(c_val);
            spreads.push(0.0);
            timestamps.push(dt + chrono::Duration::seconds(3));
        }

        if symbols.is_empty() { return; }

        let query = "
            INSERT INTO tick_log (symbol, bid, ask, spread, timestamp)
            SELECT s, b, a, sp, ts FROM UNNEST($1::text[], $2::double precision[], $3::double precision[], $4::double precision[], $5::timestamptz[])
            AS t(s, b, a, sp, ts)
            WHERE NOT EXISTS (
                SELECT 1 FROM tick_log tl WHERE tl.symbol = t.s AND tl.timestamp = t.ts
            )
        ";

        match sqlx::query(query)
            .bind(symbols).bind(bids).bind(asks).bind(spreads).bind(timestamps)
            .execute(&self.pool).await 
        {
            Err(e) => error!("❌ Failed to insert gap-fill candles: {}", e),
            Ok(r) => info!("✅ Gap-fill: inserted {}/{} new ticks for {}", r.rows_affected(), arr.len() * 4, symbol),
        }
    }

    /// Fast non-blocking tick logger (sends to Async Batch channel)
    pub fn log_tick(&self, symbol: &str, bid: f64, ask: f64, spread: f64) {
        let sym_upper = symbol.to_uppercase();
        let crypto_keywords = ["BTC", "ETH", "XRP", "SOL", "ADA", "DOGE", "LTC", "BNB", "DOT", "AVAX", "MATIC", "LINK", "BCH", "UNI", "XLM", "XMR", "TRX", "CRYPTO"];
        let is_crypto = crypto_keywords.iter().any(|&k| sym_upper.contains(k));
        
        if !is_crypto {
            use chrono::{Datelike, Timelike, Weekday};
            let now = Utc::now();
            let weekday = now.weekday();
            let hour = now.hour();
            let month = now.month();
            let day = now.day();
            
            // Major Global Forex Holidays: Christmas & New Year
            let is_holiday = (month == 12 && day == 25) || (month == 1 && day == 1);

            // Forex market is closed from Friday 21:00 UTC to Sunday 21:00 UTC + Global Holidays
            let is_closed = is_holiday
                         || (weekday == Weekday::Fri && hour >= 21) 
                         || (weekday == Weekday::Sat) 
                         || (weekday == Weekday::Sun && hour < 21);
                         
            if is_closed {
                return; // Do not record ticks during weekend or holiday market closure
            }
        }

        let record = TickRecord {
            symbol: symbol.to_string(),
            bid, ask, spread,
            timestamp: Utc::now(),
        };
        let _ = self.tick_tx.try_send(record);
    }

    pub async fn get_historical_candles(&self, symbol: &str, limit: i64) -> serde_json::Value {
        let query = "
            SELECT 
                time,
                first(bid, timestamp) as open,
                max(bid) as high,
                min(bid) as low,
                last(bid, timestamp) as close
            FROM (
                SELECT 
                    (EXTRACT(EPOCH FROM timestamp)::bigint / 60) * 60 as time,
                    bid,
                    timestamp
                FROM tick_log
                WHERE symbol = $1
                ORDER BY timestamp DESC
                LIMIT $2 * 60 * 5 -- roughly 5 ticks per sec buffer
            ) sub
            GROUP BY time
            ORDER BY time DESC
            LIMIT $2
        ";

        if let Ok(rows) = sqlx::query_as::<_, (i64, f64, f64, f64, f64)>(query)
            .bind(symbol).bind(limit)
            .fetch_all(&self.pool).await 
        {
            let mut candles: Vec<_> = rows.into_iter().map(|row| {
                serde_json::json!({"time": row.0, "open": row.1, "high": row.2, "low": row.3, "close": row.4})
            }).collect();
            candles.reverse();
            return serde_json::Value::Array(candles);
        }
        serde_json::Value::Array(Vec::new())
    }

    #[allow(dead_code)]
    pub async fn log_trade(&self, action: &str, symbol: &str, direction: &str, lot: f64, price: f64, pnl: f64, source: &str) {
        let _ = sqlx::query("INSERT INTO trade_log (action, symbol, direction, lot, price, pnl, source) VALUES ($1, $2, $3, $4, $5, $6, $7)")
            .bind(action).bind(symbol).bind(direction).bind(lot).bind(price).bind(pnl).bind(source)
            .execute(&self.pool).await;
    }

    /// Get the latest tick timestamp for a symbol (returns Unix timestamp or 0 if none)
    pub async fn get_latest_tick_timestamp(&self, symbol: &str) -> i64 {
        let result: Option<DateTime<Utc>> = sqlx::query_scalar(
            "SELECT timestamp FROM tick_log WHERE symbol = $1 ORDER BY timestamp DESC LIMIT 1"
        ).bind(symbol).fetch_optional(&self.pool).await.unwrap_or(None);
        result.map(|t| t.timestamp()).unwrap_or(0)
    }

    /// Get all unique symbols in tick_log
    pub async fn get_tracked_symbols(&self) -> Vec<String> {
        sqlx::query_scalar("SELECT DISTINCT symbol FROM tick_log ORDER BY symbol")
            .fetch_all(&self.pool).await.unwrap_or_default()
    }

    #[allow(dead_code)]
    pub async fn get_config(&self, key: &str) -> Option<String> {
        sqlx::query_scalar("SELECT value FROM server_config WHERE key = $1")
            .bind(key).fetch_optional(&self.pool).await.unwrap_or(None)
    }

    pub async fn set_config(&self, key: &str, value: &str) {
        let _ = sqlx::query("INSERT INTO server_config (key, value) VALUES ($1, $2) ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value")
            .bind(key).bind(value).execute(&self.pool).await;
    }

    pub async fn get_all_config(&self) -> serde_json::Value {
        let mut map = serde_json::Map::new();
        if let Ok(rows) = sqlx::query_as::<_, (String, String)>("SELECT key, value FROM server_config").fetch_all(&self.pool).await {
            for (k, v) in rows { map.insert(k, serde_json::Value::String(v)); }
        }
        serde_json::Value::Object(map)
    }

    pub async fn get_stats(&self) -> serde_json::Value {
        let total_ticks: i64 = sqlx::query_scalar("SELECT COALESCE(reltuples::bigint, 0) FROM pg_class WHERE relname = 'tick_log'").fetch_one(&self.pool).await.unwrap_or(0);
        let total_trades: i64 = sqlx::query_scalar("SELECT COALESCE(reltuples::bigint, 0) FROM pg_class WHERE relname = 'trade_log'").fetch_one(&self.pool).await.unwrap_or(0);
        let latest_tick_time: String = sqlx::query_scalar::<_, DateTime<Utc>>("SELECT timestamp FROM tick_log ORDER BY timestamp DESC LIMIT 1")
            .fetch_one(&self.pool).await.map(|t| t.to_rfc3339()).unwrap_or_else(|_| "—".to_string());
        let latest_trade_time: String = sqlx::query_scalar::<_, DateTime<Utc>>("SELECT timestamp FROM trade_log ORDER BY timestamp DESC LIMIT 1")
            .fetch_one(&self.pool).await.map(|t| t.to_rfc3339()).unwrap_or_else(|_| "—".to_string());
        
        let db_size_bytes: i64 = sqlx::query_scalar("SELECT pg_database_size(current_database())").fetch_one(&self.pool).await.unwrap_or(0);

        serde_json::json!({
            "total_ticks": total_ticks,
            "total_trades": total_trades,
            "latest_tick_time": latest_tick_time,
            "latest_trade_time": latest_trade_time,
            "db_size_bytes": db_size_bytes,
            "db_path": "postgresql",
        })
    }

    pub async fn get_trade_setups(&self) -> serde_json::Value {
        #[derive(sqlx::FromRow)]
        struct SetupRow {
            id: i64, symbol: String, strategy: String, timeframe: String,
            lot_size: f64, risk_percent: f64, mt5_instance: String,
            tp_enabled: bool, tp_mode: String, tp_value: f64,
            sl_enabled: bool, sl_mode: String, sl_value: f64,
            trailing_stop_enabled: bool, trailing_stop_points: f64,
            status: String, created_at: DateTime<Utc>
        }
        let query = "SELECT id, symbol, strategy, timeframe, lot_size, risk_percent, mt5_instance, tp_enabled, tp_mode, tp_value, sl_enabled, sl_mode, sl_value, trailing_stop_enabled, trailing_stop_points, status, created_at FROM trade_setups ORDER BY id";
        if let Ok(rows) = sqlx::query_as::<_, SetupRow>(query)
            .fetch_all(&self.pool).await 
        {
            let setups: Vec<_> = rows.into_iter().map(|row| {
                serde_json::json!({
                    "id": row.id, "symbol": row.symbol, "strategy": row.strategy, "timeframe": row.timeframe,
                    "lotSize": row.lot_size, "riskPercent": row.risk_percent, "mt5Instance": row.mt5_instance,
                    "tpEnabled": row.tp_enabled, "tpMode": row.tp_mode, "tpValue": row.tp_value,
                    "slEnabled": row.sl_enabled, "slMode": row.sl_mode, "slValue": row.sl_value,
                    "trailingStopEnabled": row.trailing_stop_enabled, "trailingStopPoints": row.trailing_stop_points,
                    "status": row.status, "createdAt": row.created_at.to_rfc3339()
                })
            }).collect();
            return serde_json::Value::Array(setups);
        }
        serde_json::Value::Array(Vec::new())
    }

    pub async fn add_trade_setup(&self, symbol: &str, strategy: &str, timeframe: &str, lot: f64, risk: f64, mt5: &str, tp_en: bool, tp_mode: &str, tp_val: f64, sl_en: bool, sl_mode: &str, sl_val: f64, ts_en: bool, ts_pts: f64) -> Option<i64> {
        let q = "INSERT INTO trade_setups (symbol, strategy, timeframe, lot_size, risk_percent, mt5_instance, tp_enabled, tp_mode, tp_value, sl_enabled, sl_mode, sl_value, trailing_stop_enabled, trailing_stop_points) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14) RETURNING id";
        sqlx::query_scalar(q)
            .bind(symbol).bind(strategy).bind(timeframe).bind(lot).bind(risk).bind(mt5)
            .bind(tp_en).bind(tp_mode).bind(tp_val).bind(sl_en).bind(sl_mode).bind(sl_val).bind(ts_en).bind(ts_pts)
            .fetch_one(&self.pool).await.ok()
    }

    pub async fn update_trade_setup_status(&self, id: i64, status: &str) {
        let _ = sqlx::query("UPDATE trade_setups SET status = $1 WHERE id = $2").bind(status).bind(id).execute(&self.pool).await;
    }

    pub async fn delete_trade_setup(&self, id: i64) {
        let _ = sqlx::query("DELETE FROM trade_setups WHERE id = $1").bind(id).execute(&self.pool).await;
    }

    pub async fn update_trade_setup(&self, id: i64, symbol: &str, strategy: &str, timeframe: &str, lot: f64, risk: f64, mt5: &str, tp_en: bool, tp_mode: &str, tp_val: f64, sl_en: bool, sl_mode: &str, sl_val: f64, ts_en: bool, ts_pts: f64) {
        let q = "UPDATE trade_setups SET symbol=$1, strategy=$2, timeframe=$3, lot_size=$4, risk_percent=$5, mt5_instance=$6, tp_enabled=$7, tp_mode=$8, tp_value=$9, sl_enabled=$10, sl_mode=$11, sl_value=$12, trailing_stop_enabled=$13, trailing_stop_points=$14 WHERE id=$15";
        let _ = sqlx::query(q)
            .bind(symbol).bind(strategy).bind(timeframe).bind(lot).bind(risk).bind(mt5)
            .bind(tp_en).bind(tp_mode).bind(tp_val).bind(sl_en).bind(sl_mode).bind(sl_val).bind(ts_en).bind(ts_pts).bind(id)
            .execute(&self.pool).await;
    }

    pub async fn vacuum(&self) -> bool {
        match sqlx::query("VACUUM ANALYZE").execute(&self.pool).await {
            Ok(_) => { info!("✅ VACUUM ANALYZE completed"); true },
            Err(e) => { error!("❌ VACUUM failed: {}", e); false }
        }
    }

    #[allow(dead_code)]
    pub async fn cleanup_old_ticks(&self, retention_days: i64) {
        let sql = format!("DELETE FROM tick_log WHERE timestamp < NOW() - INTERVAL '{} days'", retention_days);
        if let Ok(res) = sqlx::query(&sql).execute(&self.pool).await {
            let deleted = res.rows_affected();
            if deleted > 0 { info!("🧹 Cleaned {} old tick records", deleted); }
        }
    }

    pub async fn save_trade_history(&self, deals: &serde_json::Value) {
        if let Some(deals_arr) = deals.as_array() {
            let mut tx = match self.pool.begin().await {
                Ok(tx) => tx,
                Err(_) => return,
            };
            for deal in deals_arr {
                let ticket = deal["ticket"].as_i64().unwrap_or(0);
                if ticket == 0 { continue; }
                let order = deal["order"].as_i64().unwrap_or(0);
                let pos_id = deal["pos_id"].as_i64().unwrap_or(0);
                let sym = deal["symbol"].as_str().unwrap_or("");
                let ty = deal["type"].as_str().unwrap_or("");
                let vol = deal["volume"].as_f64().unwrap_or(0.0);
                let px = deal["price"].as_f64().unwrap_or(0.0);
                let profit = deal["profit"].as_f64().unwrap_or(0.0);
                let swap = deal["swap"].as_f64().unwrap_or(0.0);
                let comm = deal["commission"].as_f64().unwrap_or(0.0);
                let magic = deal["magic"].as_i64().unwrap_or(0);
                let time = deal["time"].as_str().unwrap_or("");
                let comment = deal["comment"].as_str().unwrap_or("");

                let _ = sqlx::query("INSERT INTO trade_history (ticket, order_id, pos_id, symbol, type, volume, price, profit, swap, commission, magic, time, comment) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13) ON CONFLICT (ticket) DO NOTHING")
                    .bind(ticket).bind(order).bind(pos_id).bind(sym).bind(ty).bind(vol).bind(px).bind(profit).bind(swap).bind(comm).bind(magic).bind(time).bind(comment)
                    .execute(&mut *tx).await;
            }
            let _ = tx.commit().await;
        }
    }

    pub async fn get_trade_history(&self) -> serde_json::Value {
        let query = "SELECT ticket, order_id, pos_id, symbol, type, volume, price, profit, swap, commission, magic, time, comment FROM trade_history ORDER BY time DESC LIMIT 500";
        if let Ok(rows) = sqlx::query_as::<_, (i64, i64, i64, String, String, f64, f64, f64, f64, f64, i64, String, String)>(query)
            .fetch_all(&self.pool).await 
        {
            let deals: Vec<_> = rows.into_iter().map(|row| {
                serde_json::json!({
                    "ticket": row.0, "order": row.1, "pos_id": row.2, "symbol": row.3, "type": row.4,
                    "volume": row.5, "price": row.6, "profit": row.7, "swap": row.8, "commission": row.9,
                    "magic": row.10, "time": row.11, "comment": row.12
                })
            }).collect();
            return serde_json::Value::Array(deals);
        }
        serde_json::Value::Array(Vec::new())
    }

    // ──────────────────────────────────────────
    //  Strategy Engine helpers
    // ──────────────────────────────────────────

    /// Get only active trade setups
    pub async fn get_active_setups(&self) -> serde_json::Value {
        #[derive(sqlx::FromRow)]
        struct SetupRow {
            id: i64, symbol: String, strategy: String, timeframe: String,
            lot_size: f64, risk_percent: f64, mt5_instance: String,
            tp_enabled: bool, tp_mode: String, tp_value: f64,
            sl_enabled: bool, sl_mode: String, sl_value: f64,
            trailing_stop_enabled: bool, trailing_stop_points: f64,
            status: String, created_at: DateTime<Utc>
        }
        let query = "SELECT id, symbol, strategy, timeframe, lot_size, risk_percent, mt5_instance, tp_enabled, tp_mode, tp_value, sl_enabled, sl_mode, sl_value, trailing_stop_enabled, trailing_stop_points, status, created_at FROM trade_setups WHERE status = 'active' ORDER BY id";
        if let Ok(rows) = sqlx::query_as::<_, SetupRow>(query)
            .fetch_all(&self.pool).await 
        {
            let setups: Vec<_> = rows.into_iter().map(|row| {
                serde_json::json!({
                    "id": row.id, "symbol": row.symbol, "strategy": row.strategy, "timeframe": row.timeframe,
                    "lotSize": row.lot_size, "riskPercent": row.risk_percent, "mt5Instance": row.mt5_instance,
                    "tpEnabled": row.tp_enabled, "tpMode": row.tp_mode, "tpValue": row.tp_value,
                    "slEnabled": row.sl_enabled, "slMode": row.sl_mode, "slValue": row.sl_value,
                    "trailingStopEnabled": row.trailing_stop_enabled, "trailingStopPoints": row.trailing_stop_points,
                    "status": row.status, "createdAt": row.created_at.to_rfc3339()
                })
            }).collect();
            return serde_json::Value::Array(setups);
        }
        serde_json::Value::Array(Vec::new())
    }

    /// Aggregate recent ticks into OHLC candles for strategy computation
    pub async fn get_candles_for_strategy(&self, symbol: &str, tf_minutes: i64, count: i64) -> Vec<crate::strategy::Candle> {
        let tf_secs = tf_minutes * 60;
        let mut final_candles: Vec<crate::strategy::Candle> = Vec::new();

        // 1. Try serving from Memory Cache first
        {
            let map = self.mem_candles.read().await;
            if let Some(symbol_candles) = map.get(symbol) {
                let mut current_candle: Option<crate::strategy::Candle> = None;
                
                for (_m1_time, c) in symbol_candles.iter().rev() {
                    let snapped_time = (c.time / tf_secs) * tf_secs;
                    
                    if let Some(ref mut cur) = current_candle {
                        if cur.time == snapped_time {
                            cur.open = c.open;
                            if c.high > cur.high { cur.high = c.high; }
                            if c.low < cur.low { cur.low = c.low; }
                        } else {
                            final_candles.push(cur.clone());
                            if final_candles.len() as i64 >= count { break; }
                            current_candle = Some(crate::strategy::Candle {
                                time: snapped_time,
                                open: c.open,
                                high: c.high,
                                low: c.low,
                                close: c.close,
                            });
                        }
                    } else {
                        current_candle = Some(crate::strategy::Candle {
                            time: snapped_time,
                            open: c.open,
                            high: c.high,
                            low: c.low,
                            close: c.close,
                        });
                    }
                }
                if let Some(cur) = current_candle {
                    if (final_candles.len() as i64) < count {
                        final_candles.push(cur);
                    }
                }
            }
        }
        
        // 2. If memory didn't have enough data, query TimescaleDB materialized view!
        if (final_candles.len() as i64) < count {
            let missing = count - (final_candles.len() as i64);
            let latest_time = final_candles.last().map(|c| c.time).unwrap_or(Utc::now().timestamp());
            let latest_dt = DateTime::from_timestamp(latest_time, 0).unwrap_or(Utc::now());

            let query = format!(
                "SELECT 
                    EXTRACT(EPOCH FROM time_bucket(INTERVAL '{} minutes', time))::bigint as bucket_time,
                    first(open, time) as open,
                    max(high) as high,
                    min(low) as low,
                    last(close, time) as close
                FROM candles_m1
                WHERE symbol = $1 AND time < $2
                GROUP BY bucket_time
                ORDER BY bucket_time DESC
                LIMIT $3", tf_minutes
            );

            // Ignore DB query errors silently so UI doesn't crash if timescale isn't ready
            if let Ok(rows) = sqlx::query_as::<_, (i64, f64, f64, f64, f64)>(&query)
                .bind(symbol).bind(latest_dt).bind(missing)
                .fetch_all(&self.pool).await 
            {
                for row in rows {
                    final_candles.push(crate::strategy::Candle {
                        time: row.0, open: row.1, high: row.2, low: row.3, close: row.4,
                    });
                }
            }
        }

        final_candles.reverse();
        final_candles
    }

    /// Log a strategy signal
    pub async fn log_strategy_signal(&self, setup_id: i64, signal_type: &str, reason: &str) {
        let _ = sqlx::query(
            "INSERT INTO strategy_signals (setup_id, signal_type, reason, executed) VALUES ($1, $2, $3, true)"
        )
            .bind(setup_id).bind(signal_type).bind(reason)
            .execute(&self.pool).await;
    }

    /// Get recent signals for UI display
    pub async fn get_recent_signals(&self, limit: i64) -> serde_json::Value {
        let query = "SELECT s.id, s.setup_id, s.signal_type, s.reason, s.executed, s.timestamp, ts.symbol, ts.strategy 
            FROM strategy_signals s 
            LEFT JOIN trade_setups ts ON s.setup_id = ts.id 
            ORDER BY s.timestamp DESC LIMIT $1";
        if let Ok(rows) = sqlx::query_as::<_, (i64, i64, String, Option<String>, bool, DateTime<Utc>, Option<String>, Option<String>)>(query)
            .bind(limit)
            .fetch_all(&self.pool).await
        {
            let signals: Vec<_> = rows.into_iter().map(|row| {
                serde_json::json!({
                    "id": row.0, "setup_id": row.1, "signal_type": row.2,
                    "reason": row.3, "executed": row.4, "timestamp": row.5.to_rfc3339(),
                    "symbol": row.6, "strategy": row.7
                })
            }).collect();
            return serde_json::Value::Array(signals);
        }
        serde_json::Value::Array(Vec::new())
    }

    /// Pre-load historical candles from PostgreSQL into memory on startup
    /// so AI agents have data immediately without waiting for MT5
    pub async fn load_candles_from_db(&self) {
        info!("📊 Loading historical candles from DB into memory...");
        
        // Get all tracked symbols
        let symbols = self.get_tracked_symbols().await;
        if symbols.is_empty() {
            info!("📊 No symbols found in DB — memory cache stays empty until MT5 connects");
            return;
        }

        let mut total_loaded = 0u64;
        
        for symbol in &symbols {
            let query = "
                SELECT 
                    (EXTRACT(EPOCH FROM timestamp)::bigint / 60) * 60 as m1_time,
                    first(bid, timestamp) as open,
                    max(bid) as high,
                    min(bid) as low,
                    last(bid, timestamp) as close
                FROM tick_log
                WHERE symbol = $1 AND timestamp > NOW() - INTERVAL '24 hours'
                GROUP BY m1_time
                ORDER BY m1_time ASC
            ";

            match sqlx::query_as::<_, (i64, f64, f64, f64, f64)>(query)
                .bind(symbol)
                .fetch_all(&self.pool).await 
            {
                Ok(rows) => {
                    if rows.is_empty() { continue; }
                    let count = rows.len();
                    
                    let mut map = self.mem_candles.write().await;
                    let symbol_candles = map.entry(symbol.clone()).or_insert_with(BTreeMap::new);
                    
                    for row in rows {
                        symbol_candles.insert(row.0, crate::strategy::Candle {
                            time: row.0,
                            open: row.1,
                            high: row.2,
                            low: row.3,
                            close: row.4,
                        });
                    }
                    
                    total_loaded += count as u64;
                    info!("  ✅ {} — loaded {} M1 candles into memory", symbol, count);
                }
                Err(e) => {
                    error!("  ❌ {} — failed to load candles: {}", symbol, e);
                }
            }
        }
        
        info!("📊 Memory cache initialized: {} total candles for {} symbols", total_loaded, symbols.len());
    }
}
