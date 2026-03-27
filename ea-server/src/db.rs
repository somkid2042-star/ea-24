use log::{info, error, warn};
use rusqlite::{Connection, params};
use std::path::PathBuf;
use std::sync::Mutex;

/// Thread-safe database wrapper
pub struct Database {
    conn: Mutex<Connection>,
    path: PathBuf,
}

#[allow(dead_code)]
impl Database {
    /// Initialize database — creates file + tables if they don't exist
    pub fn init(db_path: &str) -> Result<Self, String> {
        let path = PathBuf::from(db_path);

        // Create parent directory if needed
        if let Some(parent) = path.parent() {
            if !parent.exists() {
                std::fs::create_dir_all(parent)
                    .map_err(|e| format!("Failed to create DB directory: {}", e))?;
            }
        }

        let conn = Connection::open(&path)
            .map_err(|e| format!("Failed to open database: {}", e))?;

        // Encrypt the database using AES-256
        conn.execute("PRAGMA key = 'ea24-secure-db-key-x8s9!';", [])
            .map_err(|e| format!("Failed to encrypt database: {}", e))?;

        // Enable WAL mode for better concurrent performance
        conn.execute_batch("PRAGMA journal_mode=WAL; PRAGMA synchronous=NORMAL;")
            .map_err(|e| format!("Failed to set PRAGMA: {}", e))?;

        // Hide the DB file on Windows
        #[cfg(target_os = "windows")]
        {
            if db_path != ":memory:" {
                let mut cmd = std::process::Command::new("attrib");
                cmd.args(&["+h", db_path]);
                use std::os::windows::process::CommandExt;
                cmd.creation_flags(0x08000000);
                let _ = cmd.output();
            }
        }

        // Create tables
        conn.execute_batch(
            "
            CREATE TABLE IF NOT EXISTS tick_log (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                symbol      TEXT NOT NULL,
                bid         REAL NOT NULL,
                ask         REAL NOT NULL,
                spread      REAL NOT NULL DEFAULT 0,
                timestamp   TEXT NOT NULL DEFAULT (datetime('now'))
            );

            CREATE TABLE IF NOT EXISTS trade_log (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                action      TEXT NOT NULL,
                symbol      TEXT,
                direction   TEXT,
                lot         REAL,
                price       REAL,
                pnl         REAL,
                source      TEXT DEFAULT 'ea',
                timestamp   TEXT NOT NULL DEFAULT (datetime('now'))
            );

            CREATE TABLE IF NOT EXISTS server_config (
                key         TEXT PRIMARY KEY,
                value       TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS trade_setups (
                id                      INTEGER PRIMARY KEY AUTOINCREMENT,
                symbol                  TEXT NOT NULL,
                strategy                TEXT NOT NULL,
                timeframe               TEXT NOT NULL DEFAULT 'M5',
                lot_size                REAL NOT NULL DEFAULT 0.01,
                risk_percent            REAL NOT NULL DEFAULT 2.0,
                mt5_instance            TEXT NOT NULL DEFAULT '',
                tp_enabled              INTEGER NOT NULL DEFAULT 0,
                tp_mode                 TEXT NOT NULL DEFAULT 'pips',
                tp_value                REAL NOT NULL DEFAULT 50.0,
                sl_enabled              INTEGER NOT NULL DEFAULT 0,
                sl_mode                 TEXT NOT NULL DEFAULT 'pips',
                sl_value                REAL NOT NULL DEFAULT 30.0,
                trailing_stop_enabled   INTEGER NOT NULL DEFAULT 0,
                trailing_stop_points    REAL NOT NULL DEFAULT 50.0,
                status                  TEXT NOT NULL DEFAULT 'paused',
                created_at              TEXT NOT NULL DEFAULT (datetime('now'))
            );

            CREATE INDEX IF NOT EXISTS idx_tick_symbol ON tick_log(symbol);
            CREATE INDEX IF NOT EXISTS idx_tick_time   ON tick_log(timestamp);
            CREATE INDEX IF NOT EXISTS idx_trade_time  ON trade_log(timestamp);
            "
        ).map_err(|e| format!("Failed to create tables: {}", e))?;

        // Insert default config if not exists
        let defaults = vec![
            ("db_path", db_path),
            ("ws_port", "8080"),
            ("tcp_port", "8081"),
            ("http_port", "4173"),
            ("backup_interval_hours", "24"),
            ("tick_retention_days", "30"),
        ];
        for (key, value) in defaults {
            conn.execute(
                "INSERT OR IGNORE INTO server_config (key, value) VALUES (?1, ?2)",
                params![key, value],
            ).ok();
        }

        info!("✅ Database initialized: {:?}", path);
        Ok(Database {
            conn: Mutex::new(conn),
            path,
        })
    }

    /// Log a tick from MT5
    pub fn log_tick(&self, symbol: &str, bid: f64, ask: f64, spread: f64) {
        if let Ok(conn) = self.conn.lock() {
            if let Err(e) = conn.execute(
                "INSERT INTO tick_log (symbol, bid, ask, spread) VALUES (?1, ?2, ?3, ?4)",
                params![symbol, bid, ask, spread],
            ) {
                error!("❌ DB log_tick error: {}", e);
            }
        }
    }

    /// Log a trade action (panic, stop_trading, start_trading, etc.)
    pub fn log_trade(&self, action: &str, symbol: &str, direction: &str, lot: f64, price: f64, pnl: f64, source: &str) {
        if let Ok(conn) = self.conn.lock() {
            if let Err(e) = conn.execute(
                "INSERT INTO trade_log (action, symbol, direction, lot, price, pnl, source) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
                params![action, symbol, direction, lot, price, pnl, source],
            ) {
                error!("❌ DB log_trade error: {}", e);
            }
        }
    }

    /// Get a config value
    pub fn get_config(&self, key: &str) -> Option<String> {
        if let Ok(conn) = self.conn.lock() {
            conn.query_row(
                "SELECT value FROM server_config WHERE key = ?1",
                params![key],
                |row| row.get(0),
            ).ok()
        } else {
            None
        }
    }

    /// Set a config value
    pub fn set_config(&self, key: &str, value: &str) {
        if let Ok(conn) = self.conn.lock() {
            if let Err(e) = conn.execute(
                "INSERT OR REPLACE INTO server_config (key, value) VALUES (?1, ?2)",
                params![key, value],
            ) {
                error!("❌ DB set_config error: {}", e);
            }
        }
    }

    /// Get all config as JSON object
    pub fn get_all_config(&self) -> serde_json::Value {
        let mut map = serde_json::Map::new();
        if let Ok(conn) = self.conn.lock() {
            if let Ok(mut stmt) = conn.prepare("SELECT key, value FROM server_config") {
                if let Ok(rows) = stmt.query_map([], |row| {
                    Ok((row.get::<_, String>(0)?, row.get::<_, String>(1)?))
                }) {
                    for row in rows.flatten() {
                        map.insert(row.0, serde_json::Value::String(row.1));
                    }
                }
            }
        }
        serde_json::Value::Object(map)
    }

    /// Get database statistics
    pub fn get_stats(&self) -> serde_json::Value {
        let mut total_ticks: i64 = 0;
        let mut total_trades: i64 = 0;
        let mut latest_tick_time = String::from("—");
        let mut latest_trade_time = String::from("—");

        if let Ok(conn) = self.conn.lock() {
            total_ticks = conn.query_row("SELECT COUNT(*) FROM tick_log", [], |r| r.get(0)).unwrap_or(0);
            total_trades = conn.query_row("SELECT COUNT(*) FROM trade_log", [], |r| r.get(0)).unwrap_or(0);
            latest_tick_time = conn.query_row(
                "SELECT timestamp FROM tick_log ORDER BY id DESC LIMIT 1", [],
                |r| r.get(0),
            ).unwrap_or_else(|_| "—".to_string());
            latest_trade_time = conn.query_row(
                "SELECT timestamp FROM trade_log ORDER BY id DESC LIMIT 1", [],
                |r| r.get(0),
            ).unwrap_or_else(|_| "—".to_string());
        }

        // Get file size
        let db_size_bytes = std::fs::metadata(&self.path)
            .map(|m| m.len())
            .unwrap_or(0);

        serde_json::json!({
            "total_ticks": total_ticks,
            "total_trades": total_trades,
            "latest_tick_time": latest_tick_time,
            "latest_trade_time": latest_trade_time,
            "db_size_bytes": db_size_bytes,
            "db_path": self.path.to_string_lossy(),
        })
    }

    /// Get all trade setups as JSON array
    pub fn get_trade_setups(&self) -> serde_json::Value {
        let mut setups = Vec::new();
        if let Ok(conn) = self.conn.lock() {
            if let Ok(mut stmt) = conn.prepare(
                "SELECT id, symbol, strategy, timeframe, lot_size, risk_percent, mt5_instance, tp_enabled, tp_mode, tp_value, sl_enabled, sl_mode, sl_value, trailing_stop_enabled, trailing_stop_points, status, created_at FROM trade_setups ORDER BY id"
            ) {
                if let Ok(rows) = stmt.query_map([], |row| {
                    Ok(serde_json::json!({
                        "id": row.get::<_, i64>(0)?,
                        "symbol": row.get::<_, String>(1)?,
                        "strategy": row.get::<_, String>(2)?,
                        "timeframe": row.get::<_, String>(3)?,
                        "lotSize": row.get::<_, f64>(4)?,
                        "riskPercent": row.get::<_, f64>(5)?,
                        "mt5Instance": row.get::<_, String>(6)?,
                        "tpEnabled": row.get::<_, i64>(7)? != 0,
                        "tpMode": row.get::<_, String>(8)?,
                        "tpValue": row.get::<_, f64>(9)?,
                        "slEnabled": row.get::<_, i64>(10)? != 0,
                        "slMode": row.get::<_, String>(11)?,
                        "slValue": row.get::<_, f64>(12)?,
                        "trailingStopEnabled": row.get::<_, i64>(13)? != 0,
                        "trailingStopPoints": row.get::<_, f64>(14)?,
                        "status": row.get::<_, String>(15)?,
                        "createdAt": row.get::<_, String>(16)?,
                    }))
                }) {
                    for row in rows.flatten() {
                        setups.push(row);
                    }
                }
            }
        }
        serde_json::Value::Array(setups)
    }

    /// Add a new trade setup
    pub fn add_trade_setup(&self, symbol: &str, strategy: &str, timeframe: &str, lot_size: f64, risk_percent: f64, mt5_instance: &str, tp_enabled: bool, tp_mode: &str, tp_value: f64, sl_enabled: bool, sl_mode: &str, sl_value: f64, trailing_stop_enabled: bool, trailing_stop_points: f64) -> Option<i64> {
        if let Ok(conn) = self.conn.lock() {
            match conn.execute(
                "INSERT INTO trade_setups (symbol, strategy, timeframe, lot_size, risk_percent, mt5_instance, tp_enabled, tp_mode, tp_value, sl_enabled, sl_mode, sl_value, trailing_stop_enabled, trailing_stop_points) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13, ?14)",
                params![symbol, strategy, timeframe, lot_size, risk_percent, mt5_instance, tp_enabled as i64, tp_mode, tp_value, sl_enabled as i64, sl_mode, sl_value, trailing_stop_enabled as i64, trailing_stop_points],
            ) {
                Ok(_) => {
                    let id = conn.last_insert_rowid();
                    info!("✅ Trade setup added: {} {} (id={})", symbol, strategy, id);
                    Some(id)
                }
                Err(e) => {
                    error!("❌ add_trade_setup error: {}", e);
                    None
                }
            }
        } else {
            None
        }
    }

    /// Update trade setup status
    pub fn update_trade_setup_status(&self, id: i64, status: &str) {
        if let Ok(conn) = self.conn.lock() {
            if let Err(e) = conn.execute(
                "UPDATE trade_setups SET status = ?1 WHERE id = ?2",
                params![status, id],
            ) {
                error!("❌ update_trade_setup_status error: {}", e);
            }
        }
    }

    /// Delete a trade setup
    pub fn delete_trade_setup(&self, id: i64) {
        if let Ok(conn) = self.conn.lock() {
            if let Err(e) = conn.execute("DELETE FROM trade_setups WHERE id = ?1", params![id]) {
                error!("❌ delete_trade_setup error: {}", e);
            }
        }
    }

    /// Update a trade setup (all fields)
    pub fn update_trade_setup(&self, id: i64, symbol: &str, strategy: &str, timeframe: &str, lot_size: f64, risk_percent: f64, mt5_instance: &str, tp_enabled: bool, tp_mode: &str, tp_value: f64, sl_enabled: bool, sl_mode: &str, sl_value: f64, trailing_stop_enabled: bool, trailing_stop_points: f64) {
        if let Ok(conn) = self.conn.lock() {
            if let Err(e) = conn.execute(
                "UPDATE trade_setups SET symbol=?1, strategy=?2, timeframe=?3, lot_size=?4, risk_percent=?5, mt5_instance=?6, tp_enabled=?7, tp_mode=?8, tp_value=?9, sl_enabled=?10, sl_mode=?11, sl_value=?12, trailing_stop_enabled=?13, trailing_stop_points=?14 WHERE id=?15",
                params![symbol, strategy, timeframe, lot_size, risk_percent, mt5_instance, tp_enabled as i64, tp_mode, tp_value, sl_enabled as i64, sl_mode, sl_value, trailing_stop_enabled as i64, trailing_stop_points, id],
            ) {
                error!("❌ update_trade_setup error: {}", e);
            } else {
                info!("✅ Trade setup updated: id={}", id);
            }
        }
    }

    /// Run VACUUM to optimize database
    pub fn vacuum(&self) -> bool {
        if let Ok(conn) = self.conn.lock() {
            match conn.execute_batch("VACUUM;") {
                Ok(_) => {
                    info!("✅ Database VACUUM completed");
                    true
                }
                Err(e) => {
                    error!("❌ VACUUM failed: {}", e);
                    false
                }
            }
        } else {
            false
        }
    }

    /// Clean old ticks based on retention days
    pub fn cleanup_old_ticks(&self, retention_days: i64) {
        if let Ok(conn) = self.conn.lock() {
            match conn.execute(
                "DELETE FROM tick_log WHERE timestamp < datetime('now', ?1)",
                params![format!("-{} days", retention_days)],
            ) {
                Ok(deleted) => {
                    if deleted > 0 {
                        info!("🧹 Cleaned {} old tick records (>{} days)", deleted, retention_days);
                    }
                }
                Err(e) => warn!("⚠️ Tick cleanup error: {}", e),
            }
        }
    }
}
