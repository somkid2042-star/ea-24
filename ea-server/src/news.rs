use serde::Deserialize;
use std::sync::Arc;
use tokio::sync::RwLock;
use chrono::{DateTime, Utc};
use log::{info, warn, error};

#[derive(Debug, Clone, Deserialize)]
pub struct NewsEvent {
    pub title: String,
    pub country: String,
    pub date: String, // ISO8601 e.g. "2026-04-10T08:30:00-04:00"
    pub impact: String,
    pub forecast: String,
    pub previous: String,
}

pub struct NewsEngine {
    events: Arc<RwLock<Vec<NewsEvent>>>,
}

impl NewsEngine {
    pub fn new() -> Arc<Self> {
        let engine = Arc::new(Self {
            events: Arc::new(RwLock::new(Vec::new())),
        });
        
        let engine_clone = engine.clone();
        tokio::spawn(async move {
            engine_clone.start_sync().await;
        });

        engine
    }

    /// Background task to fetch news every 4 hours
    async fn start_sync(&self) {
        loop {
            match Self::fetch_news().await {
                Ok(mut new_events) => {
                    new_events.retain(|e| e.impact == "High" || e.impact == "Medium"); 
                    let mut store = self.events.write().await;
                    *store = new_events;
                    info!("📰 [News Engine] Calendar updated. Loaded {} important events", store.len());
                }
                Err(e) => {
                    warn!("⚠️ [News Engine] Failed to fetch calendar: {}", e);
                }
            }
            tokio::time::sleep(tokio::time::Duration::from_secs(4 * 3600)).await; // 4 hours
        }
    }

    async fn fetch_news() -> Result<Vec<NewsEvent>, Box<dyn std::error::Error + Send + Sync>> {
        let url = "https://nfs.faireconomy.media/ff_calendar_thisweek.json";
        let client = reqwest::Client::builder()
            .timeout(std::time::Duration::from_secs(10))
            .build()?;
            
        let res = client.get(url)
            .header("User-Agent", "Mozilla/5.0 EA-24 Trader")
            .send()
            .await?;
            
        if !res.status().is_success() {
            return Err(format!("HTTP {}", res.status()).into());
        }
        
        let body = res.text().await?;
        let events: Vec<NewsEvent> = serde_json::from_str(&body)?;
        Ok(events)
    }

    /// Check if 'symbol' has High Impact news within ± `window_mins`
    pub async fn has_upcoming_news(&self, symbol: &str, window_mins: i64) -> Option<(String, i64)> {
        let store = self.events.read().await;
        let now = Utc::now();
        
        let sym_upper = symbol.to_uppercase();
        let is_gold = sym_upper.contains("XAU") || sym_upper.contains("GOLD");
        let is_crypto = sym_upper.contains("BTC") || sym_upper.contains("ETH");
        
        for event in store.iter() {
            if event.impact != "High" { continue; }
            
            let ccy = event.country.to_uppercase();
            
            let mut is_affected = false;
            if is_gold || is_crypto {
                if ccy == "USD" { is_affected = true; }
            } else {
                if sym_upper.contains(&ccy) { is_affected = true; }
            }
            
            if !is_affected { continue; }
            
            if let Ok(event_time) = DateTime::parse_from_rfc3339(&event.date) {
                let event_utc = event_time.with_timezone(&Utc);
                let diff_mins = (event_utc - now).num_minutes();
                
                // Allow pre and post checking
                if diff_mins.abs() <= window_mins {
                    return Some((event.title.clone(), diff_mins));
                }
            }
        }
        
        None
    }
}
