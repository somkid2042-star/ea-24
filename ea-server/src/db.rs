use log::{error, info};
use sqlx::{postgres::PgPoolOptions, PgPool};
use tokio::sync::mpsc;
use chrono::{DateTime, Utc};

/// Thread-safe Async database wrapper
#[derive(Clone)]
pub struct Database {
    pool: PgPool,
    tick_tx: mpsc::Sender<TickRecord>,
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
        
        tokio::spawn(async move {
            let mut batch = Vec::with_capacity(500);
            let mut timer = tokio::time::interval(std::time::Duration::from_secs(1));
            
            loop {
                tokio::select! {
                    Some(tick) = tick_rx.recv() => {
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

        info!("✅ Database connected and Tick Batcher running");
        Ok(Database { pool, tick_tx })
    }

    async fn create_tables(pool: &PgPool) -> Result<(), String> {
        let schema = "
            CREATE TABLE IF NOT EXISTS tick_log (
                id          BIGSERIAL PRIMARY KEY,
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

            CREATE INDEX IF NOT EXISTS idx_tick_symbol ON tick_log(symbol);
            CREATE INDEX IF NOT EXISTS idx_tick_time ON tick_log(timestamp DESC);
            CREATE INDEX IF NOT EXISTS idx_trade_time ON trade_log(timestamp DESC);
            CREATE INDEX IF NOT EXISTS idx_history_time ON trade_history(time);
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

    /// Fast non-blocking tick logger (sends to Async Batch channel)
    pub fn log_tick(&self, symbol: &str, bid: f64, ask: f64, spread: f64) {
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
                EXTRACT(EPOCH FROM timestamp)::bigint / 60 * 60 as time,
                (SELECT bid FROM tick_log t2 WHERE t2.symbol = t1.symbol AND EXTRACT(EPOCH FROM t2.timestamp)::bigint / 60 * 60 = EXTRACT(EPOCH FROM t1.timestamp)::bigint / 60 * 60 ORDER BY id ASC LIMIT 1) as open,
                MAX(bid) as high,
                MIN(bid) as low,
                (SELECT bid FROM tick_log t2 WHERE t2.symbol = t1.symbol AND EXTRACT(EPOCH FROM t2.timestamp)::bigint / 60 * 60 = EXTRACT(EPOCH FROM t1.timestamp)::bigint / 60 * 60 ORDER BY id DESC LIMIT 1) as close
            FROM tick_log t1
            WHERE symbol = $1
            GROUP BY time, symbol
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
        let total_ticks: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM tick_log").fetch_one(&self.pool).await.unwrap_or(0);
        let total_trades: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM trade_log").fetch_one(&self.pool).await.unwrap_or(0);
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
}
