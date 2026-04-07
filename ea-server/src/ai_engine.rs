// ──────────────────────────────────────────────
//  AI Engine — Multi-Agent Trading System
//  5 Agents: News Hunter, Chart Analyst,
//  Decision Maker, Calendar Watcher, Risk Manager
//  Uses Gemini 2.5 Pro + Tavily Search (Free)
// ──────────────────────────────────────────────

use log::{info, warn};
use serde::{Deserialize, Serialize};

const GEMINI_API_BASE: &str = "https://generativelanguage.googleapis.com/v1beta/models";
const DEFAULT_MODEL: &str = "gemini-2.5-flash";
const TAVILY_API_URL: &str = "https://api.tavily.com/search";
const FOREX_CALENDAR_URL: &str = "https://nfs.faireconomy.media/ff_calendar_thisweek.json";

// Ollama Local AI
const OLLAMA_API_BASE: &str = "http://127.0.0.1:11434";
const DEFAULT_OLLAMA_MODEL: &str = "gemma4:e4b";

// ──────────────────────────────────────────────
//  Gemini API Types
// ──────────────────────────────────────────────

#[derive(Serialize)]
struct GeminiRequest {
    contents: Vec<Content>,
    #[serde(rename = "generationConfig")]
    generation_config: GenerationConfig,
}

#[derive(Serialize)]
struct Content {
    parts: Vec<Part>,
}

#[derive(Serialize)]
struct Part {
    text: String,
}

#[derive(Serialize)]
struct GenerationConfig {
    temperature: f64,
    #[serde(rename = "maxOutputTokens")]
    max_output_tokens: i32,
    #[serde(rename = "responseMimeType", skip_serializing_if = "Option::is_none")]
    response_mime_type: Option<String>,
}

#[derive(Deserialize)]
struct GeminiResponse {
    candidates: Option<Vec<Candidate>>,
    error: Option<GeminiError>,
}

#[derive(Deserialize)]
struct Candidate {
    content: Option<CandidateContent>,
}

#[derive(Deserialize)]
struct CandidateContent {
    parts: Option<Vec<ResponsePart>>,
}

#[derive(Deserialize)]
struct ResponsePart {
    text: Option<String>,
}

#[derive(Deserialize)]
struct GeminiError {
    message: String,
    #[allow(dead_code)]
    code: Option<i32>,
}

// ──────────────────────────────────────────────
//  Tavily Search API Types
// ──────────────────────────────────────────────

#[derive(Serialize)]
struct TavilyRequest {
    api_key: String,
    query: String,
    max_results: i32,
    search_depth: String,
    include_answer: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    days: Option<i32>,
}

#[allow(dead_code)]
#[derive(Deserialize, Debug)]
struct TavilyResponse {
    pub answer: Option<String>,
    results: Option<Vec<TavilyResult>>,
}

#[allow(dead_code)]
#[derive(Deserialize, Debug, Clone)]
struct TavilyResult {
    pub title: Option<String>,
    pub url: Option<String>,
    content: Option<String>,
}

// ──────────────────────────────────────────────
//  Calendar Event Types
// ──────────────────────────────────────────────

#[derive(Deserialize, Serialize, Debug, Clone)]
pub struct ForexCalendarEvent {
    title: Option<String>,
    country: Option<String>,
    date: Option<String>,
    impact: Option<String>,
    forecast: Option<String>,
    previous: Option<String>,
}

// ──────────────────────────────────────────────
//  Agent Result Types
// ──────────────────────────────────────────────

#[allow(dead_code)]
#[derive(Debug, Clone, Serialize)]
pub struct AgentLog {
    pub agent: String,
    pub status: String,   // "running", "done", "error"
    pub message: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NewsResult {
    pub sentiment: String,        // "BULLISH", "BEARISH", "NEUTRAL"
    pub summary: String,
    pub headlines: Vec<String>,
    pub source_count: usize,
}

#[derive(Debug, Clone, Serialize)]
pub struct ChartResult {
    pub recommendation: String,   // "BUY", "SELL", "HOLD"
    pub confidence: f64,
    pub reasoning: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CalendarResult {
    pub high_impact_soon: bool,
    pub events: Vec<ForexCalendarEvent>,
    pub warning: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MacroItem {
    pub value: String,
    pub date: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MacroResult {
    pub fed: MacroItem,
    pub nfp: MacroItem,
    pub cpi: MacroItem,
}

#[derive(Debug, Clone, Serialize)]
pub struct RiskResult {
    pub approved: bool,
    pub reason: String,
    pub current_drawdown: f64,
    pub open_positions: usize,
    pub max_positions: usize,
}

#[derive(Debug, Clone, Serialize)]
pub struct MultiAgentResult {
    pub final_decision: String,   // "BUY", "SELL", "HOLD", "BLOCKED"
    pub confidence: f64,
    pub news: NewsResult,
    pub chart: ChartResult,
    pub calendar: CalendarResult,
    pub risk: RiskResult,
    pub reasoning: String,
    pub model: String,
}

/// AI analysis result (kept for backward compatibility)
#[derive(Debug, Clone, Serialize)]
pub struct AiAnalysis {
    pub recommendation: String,
    pub confidence: f64,
    pub reasoning: String,
    pub full_analysis: String,
    pub model: String,
}

// ──────────────────────────────────────────────
//  Helper: Call Gemini API
// ──────────────────────────────────────────────

async fn call_gemini(api_keys_str: &str, model: &str, prompt: &str, temp: f64, max_tokens: i32, json_mode: bool) -> Result<String, String> {
    use std::sync::atomic::{AtomicUsize, Ordering};
    static KEY_COUNTER: AtomicUsize = AtomicUsize::new(0);

    let model_name = if model.is_empty() { DEFAULT_MODEL } else { model };
    let keys: Vec<&str> = api_keys_str.split(',').map(|s| s.trim()).filter(|s| !s.is_empty()).collect();
    
    if keys.is_empty() {
        return Err("API Key is empty".to_string());
    }

    let request = GeminiRequest {
        contents: vec![Content { parts: vec![Part { text: prompt.to_string() }] }],
        generation_config: GenerationConfig {
            temperature: temp,
            max_output_tokens: max_tokens,
            response_mime_type: if json_mode { Some("application/json".to_string()) } else { None },
        },
    };

    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(45))
        .build().map_err(|e| format!("HTTP client error: {}", e))?;

    let mut last_error = "Unknown error".to_string();

    // Round-robin: start from a different key each time to distribute load evenly
    let start_idx = KEY_COUNTER.fetch_add(1, Ordering::Relaxed) % keys.len();

    let cooldown = crate::notify::get_key_manager();

    for attempt in 0..keys.len() {
        let i = (start_idx + attempt) % keys.len();
        
        // Skip keys in cooldown
        if !cooldown.is_available(i).await {
            continue;
        }
        
        let key = keys[i];
        let url = format!("{}/{}:generateContent?key={}", GEMINI_API_BASE, model_name, key);
        
        let resp = match client.post(&url).json(&request).send().await {
            Ok(r) => r,
            Err(e) => {
                last_error = format!("API request failed: {}", e);
                // If it's a network error, maybe the next key works, maybe not, but we continue.
                continue;
            }
        };

        if !resp.status().is_success() {
            let status = resp.status();
            let body = resp.text().await.unwrap_or_default();
            last_error = format!("API error ({}): {}", status, body);
            
            // Mark 429 keys for cooldown
            if status.as_u16() == 429 {
                cooldown.mark_rate_limited(i).await;
            }
            
            if attempt < keys.len() - 1 {
                warn!("⚠️ Gemini Key #{} error ({}), next...", i+1, status);
                continue;
            } else {
                return Err(last_error);
            }
        }

        let gemini_resp: GeminiResponse = match resp.json().await {
            Ok(r) => r,
            Err(e) => {
                last_error = format!("Parse error: {}", e);
                if attempt < keys.len() - 1 { continue; } else { return Err(last_error); }
            }
        };

        if let Some(err) = gemini_resp.error {
            last_error = format!("Gemini error: {}", err.message);
            if attempt < keys.len() - 1 {
                warn!("⚠️ Gemini API Key {} hit internal error, trying next...", i+1);
                continue;
            } else {
                return Err(last_error);
            }
        }

        let text = gemini_resp.candidates
            .and_then(|c| c.into_iter().next())
            .and_then(|c| c.content)
            .and_then(|c| c.parts)
            .and_then(|p| p.into_iter().next())
            .and_then(|p| p.text)
            .ok_or_else(|| "Empty response".to_string())?;

        // SUCCESS — reset cooldown for this key
        cooldown.mark_success(i).await;

        // ----- DEBUG LOGGING FOR AI AGENTS -----
        let time_now = chrono::Local::now().format("%Y-%m-%d %H:%M:%S");
        let debug_log = format!(
            "========== AI DEBUG ( {} ) ==========\n⚙️ MODEL: {}\n\n📥 [PROMPT SENT TO AI]:\n{}\n\n📤 [RAW RESPONSE FROM AI]:\n{}\n======================================================\n\n",
            time_now, model_name, prompt, text
        );

        // Async write to ai_prompt_debug.txt
        let _ = tokio::fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open("ai_prompt_debug.txt")
            .await
            .map(|mut f| async move {
                use tokio::io::AsyncWriteExt;
                let _ = f.write_all(debug_log.as_bytes()).await;
            });
            
        // Also log a quick snippet to the console
        log::info!("🤖 [AI MODEL {}] Prompt len: {}, Response len: {}", model_name, prompt.len(), text.len());
        
        return Ok(text);
    }

    // If we exhausted all keys
    Err(format!("โควต้า API Key เต็มหมดแล้ว (ลองไป {} คีย์) | Error เดี่ยวชี้: {}", keys.len(), last_error))
}

// ──────────────────────────────────────────────
//  Helper: Call Ollama Local AI (Gemma 4 E4B)
// ──────────────────────────────────────────────

#[derive(Serialize)]
struct OllamaRequest {
    model: String,
    prompt: String,
    stream: bool,
    options: OllamaOptions,
}

#[derive(Serialize)]
struct OllamaOptions {
    temperature: f64,
    num_predict: i32,
}

#[derive(Deserialize)]
struct OllamaResponse {
    response: Option<String>,
    error: Option<String>,
}

/// Chat-style request for Ollama /api/chat
#[derive(Serialize)]
struct OllamaChatRequest {
    model: String,
    messages: Vec<OllamaChatMessage>,
    stream: bool,
    options: OllamaOptions,
}

#[derive(Serialize)]
struct OllamaChatMessage {
    role: String,
    content: String,
}

#[derive(Deserialize)]
struct OllamaChatResponse {
    message: Option<OllamaChatResponseMessage>,
    error: Option<String>,
}

#[derive(Deserialize)]
struct OllamaChatResponseMessage {
    content: Option<String>,
}

async fn call_ollama(model: &str, prompt: &str, temp: f64, max_tokens: i32) -> Result<String, String> {
    let model_name = if model.is_empty() { DEFAULT_OLLAMA_MODEL } else { model };

    let request = OllamaChatRequest {
        model: model_name.to_string(),
        messages: vec![OllamaChatMessage {
            role: "user".to_string(),
            content: prompt.to_string(),
        }],
        stream: false,
        options: OllamaOptions {
            temperature: temp,
            num_predict: max_tokens,
        },
    };

    // Ollama on CPU can be slow — allow up to 5 minutes
    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(300))
        .build().map_err(|e| format!("HTTP client error: {}", e))?;

    let url = format!("{}/api/chat", OLLAMA_API_BASE);

    let resp = client.post(&url)
        .json(&request)
        .send()
        .await
        .map_err(|e| format!("Ollama request failed (is ollama running?): {}", e))?;

    if !resp.status().is_success() {
        let status = resp.status();
        let body = resp.text().await.unwrap_or_default();
        return Err(format!("Ollama error ({}): {}", status, body));
    }

    let ollama_resp: OllamaChatResponse = resp.json().await
        .map_err(|e| format!("Ollama parse error: {}", e))?;

    if let Some(err) = ollama_resp.error {
        return Err(format!("Ollama error: {}", err));
    }

    let text = ollama_resp.message
        .and_then(|m| m.content)
        .ok_or_else(|| "Ollama returned empty response".to_string())?;

    // Strip thinking blocks if present (Gemma 4 uses <think>...</think>)
    let clean_text = strip_thinking_blocks(&text);

    // ----- DEBUG LOGGING -----
    let time_now = chrono::Local::now().format("%Y-%m-%d %H:%M:%S");
    let debug_log = format!(
        "========== OLLAMA DEBUG ( {} ) ==========\n⚙️ MODEL: {} (LOCAL)\n\n📥 [PROMPT]:\n{}\n\n📤 [RESPONSE]:\n{}\n======================================================\n\n",
        time_now, model_name, prompt, clean_text
    );
    let _ = tokio::fs::OpenOptions::new()
        .create(true).append(true)
        .open("ai_prompt_debug.txt").await
        .map(|mut f| async move {
            use tokio::io::AsyncWriteExt;
            let _ = f.write_all(debug_log.as_bytes()).await;
        });

    log::info!("🏠 [OLLAMA {}] Prompt len: {}, Response len: {}", model_name, prompt.len(), clean_text.len());

    Ok(clean_text)
}

/// Remove <think>...</think> or Thinking blocks from Gemma 4 responses
fn strip_thinking_blocks(text: &str) -> String {
    // Remove XML-style thinking tags
    let mut result = text.to_string();
    while let Some(start) = result.find("<think>") {
        if let Some(end) = result.find("</think>") {
            result = format!("{}{}", &result[..start], &result[end + 8..]);
        } else {
            // Unclosed <think> tag — remove from <think> to end
            result = result[..start].to_string();
            break;
        }
    }
    result.trim().to_string()
}

// ──────────────────────────────────────────────
//  Smart AI Caller: Gemini → Ollama Fallback
// ──────────────────────────────────────────────

/// Try Gemini API first, if it fails, fallback to local Ollama.
/// If gemini_key is empty, skip Gemini and go straight to Ollama.
async fn call_ai(gemini_key: &str, model: &str, prompt: &str, temp: f64, max_tokens: i32, json_mode: bool) -> Result<String, String> {
    // If no Gemini key, go straight to Ollama
    if gemini_key.is_empty() {
        info!("🏠 [AI] No Gemini API key — using local Ollama");
        return call_ollama("", prompt, temp, max_tokens).await;
    }

    // Try Gemini first
    match call_gemini(gemini_key, model, prompt, temp, max_tokens, json_mode).await {
        Ok(text) => Ok(text),
        Err(gemini_err) => {
            // Gemini failed — try Ollama as fallback
            warn!("⚠️ [AI] Gemini failed: {} — Falling back to local Ollama...", gemini_err);
            match call_ollama("", prompt, temp, max_tokens).await {
                Ok(text) => {
                    info!("✅ [AI] Ollama fallback succeeded!");
                    Ok(text)
                }
                Err(ollama_err) => {
                    // Both failed
                    Err(format!("AI ล้มเหลวทั้งสองระบบ | Gemini: {} | Ollama: {}", gemini_err, ollama_err))
                }
            }
        }
    }
}

// ──────────────────────────────────────────────
//  Agent 1: News Hunter (Google News RSS + Tavily fallback)
// ──────────────────────────────────────────────

async fn search_news_google_rss(symbol: &str) -> Result<Vec<TavilyResult>, String> {
    let query = match symbol.to_uppercase().as_str() {
        s if s.contains("XAU") || s.contains("GOLD") => "gold+XAUUSD+price+forecast".to_string(),
        s if s.contains("EUR") => format!("{}+forex+news", symbol),
        s if s.contains("GBP") => format!("{}+forex+news", symbol),
        s if s.contains("JPY") => format!("{}+forex+news", symbol),
        s if s.contains("BTC") => "Bitcoin+BTC+crypto+price".to_string(),
        s if s.contains("ETH") => "Ethereum+ETH+crypto+price".to_string(),
        _ => format!("{}+trading+price+news", symbol),
    };

    let url = format!("https://news.google.com/rss/search?q={}+when:1d&hl=en&gl=US&ceid=US:en", query);
    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(10))
        .build().map_err(|e| format!("HTTP error: {}", e))?;

    let resp = client.get(&url)
        .header("User-Agent", "Mozilla/5.0")
        .send().await
        .map_err(|e| format!("Google News request failed: {}", e))?;

    let body = resp.text().await.map_err(|e| format!("Read error: {}", e))?;

    // Parse RSS XML — extract <item><title> and <description>
    let mut results = Vec::new();
    for item in body.split("<item>").skip(1).take(8) {
        let title = item.split("<title>").nth(1)
            .and_then(|s| s.split("</title>").next())
            .map(|s| s.replace("<![CDATA[", "").replace("]]>", "").trim().to_string());
        let desc = item.split("<description>").nth(1)
            .and_then(|s| s.split("</description>").next())
            .map(|s| s.replace("<![CDATA[", "").replace("]]>", "").trim().to_string());
        let link = item.split("<link>").nth(1)
            .and_then(|s| s.split("</link>").next())
            .map(|s| s.trim().to_string());

        if title.is_some() {
            results.push(TavilyResult {
                title,
                content: desc,
                url: link,
            });
        }
    }
    Ok(results)
}

async fn search_news_tavily(tavily_key: &str, symbol: &str) -> Result<Vec<TavilyResult>, String> {
    if tavily_key.is_empty() {
        return Err("Tavily API Key is empty".to_string());
    }

    let keys: Vec<&str> = tavily_key.split(',').map(|s| s.trim()).filter(|s| !s.is_empty()).collect();
    if keys.is_empty() {
        return Err("Tavily API Key list is empty".to_string());
    }

    let query = match symbol.to_uppercase().as_str() {
        s if s.contains("XAU") || s.contains("GOLD") => "gold XAUUSD price news today forecast".to_string(),
        s if s.contains("EUR") => format!("{} forex news today", symbol),
        s if s.contains("GBP") => format!("{} forex news today", symbol),
        s if s.contains("JPY") => format!("{} forex news today", symbol),
        s if s.contains("BTC") => "Bitcoin BTC crypto price news today".to_string(),
        s if s.contains("ETH") => "Ethereum ETH crypto price news today".to_string(),
        _ => format!("{} trading price news today", symbol),
    };

    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(15))
        .build().map_err(|e| format!("HTTP error: {}", e))?;

    let mut last_error = "Unknown error".to_string();

    for (i, key) in keys.iter().enumerate() {
        let request = TavilyRequest {
            api_key: key.to_string(),
            query: query.clone(),
            max_results: 5,
            search_depth: "basic".to_string(),
            include_answer: true,
            days: Some(1),
        };

        let resp = match client.post(TAVILY_API_URL).json(&request).send().await {
            Ok(r) => r,
            Err(e) => {
                last_error = format!("Tavily request failed: {}", e);
                continue;
            }
        };

        if !resp.status().is_success() {
            let status = resp.status();
            let body = resp.text().await.unwrap_or_default();
            last_error = format!("Tavily error ({}): {}", status, body);
            // HTTP 429 = Too Many Requests / Quota 
            if status.as_u16() == 429 || status.as_u16() == 403 || status.as_u16() == 400 || body.to_lowercase().contains("limit") || body.to_lowercase().contains("credit") {
                 if i < keys.len() - 1 {
                     warn!("⚠️ Tavily API Key {} hit limit/error, trying next...", i+1);
                     continue;
                 }
            }
            if i < keys.len() - 1 { continue; } else { return Err(last_error); }
        }

        let tavily_resp: TavilyResponse = match resp.json().await {
            Ok(r) => r,
            Err(e) => {
                last_error = format!("Tavily parse error: {}", e);
                if i < keys.len() - 1 { continue; } else { return Err(last_error); }
            }
        };

        return Ok(tavily_resp.results.unwrap_or_default());
    }

    Err(format!("Tavily fail (tried {} keys): {}", keys.len(), last_error))
}

pub async fn run_news_hunter(
    gemini_key: &str, model: &str, tavily_key: &str, symbol: &str,
    log_tx: &tokio::sync::broadcast::Sender<String>,
) -> NewsResult {
    let agent = "🔍 News Hunter";

    // Send log: starting
    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": symbol, "agent": "news_hunter", "status": "running",
        "message": format!("กำลังค้นหาข่าว {}...", symbol)
    }).to_string());

    // Try Tavily API first, then Google News RSS as fallback
    let articles = if !tavily_key.is_empty() {
        match search_news_tavily(tavily_key, symbol).await {
            Ok(results) if !results.is_empty() => {
                info!("{} Found {} articles via Tavily", agent, results.len());
                let _ = log_tx.send(serde_json::json!({
                    "type": "agent_log", "symbol": symbol, "agent": "news_hunter", "status": "running",
                    "message": format!("พบข่าว {} รายการ (Tavily) — กำลังวิเคราะห์ sentiment...", results.len())
                }).to_string());
                results
            }
            _ => {
                warn!("{} Tavily failed or returned no results, falling back to Google News", agent);
                match search_news_google_rss(symbol).await {
                    Ok(results) if !results.is_empty() => {
                        info!("{} Found {} articles via Google News", agent, results.len());
                        let _ = log_tx.send(serde_json::json!({
                            "type": "agent_log", "symbol": symbol, "agent": "news_hunter", "status": "running",
                            "message": format!("พบข่าว {} รายการ (Google News) — กำลังวิเคราะห์ sentiment...", results.len())
                        }).to_string());
                        results
                    }
                    Err(e) => {
                        warn!("{} All search methods failed: {}", agent, e);
                        let _ = log_tx.send(serde_json::json!({
                            "type": "agent_log", "symbol": symbol, "agent": "news_hunter", "status": "error",
                            "message": format!("ค้นข่าวไม่สำเร็จ: ทั้ง Tavily และ Google News ล้มเหลว")
                        }).to_string());
                        return NewsResult {
                            sentiment: "NEUTRAL".to_string(),
                            summary: format!("ไม่สามารถค้นข่าวได้: {}", e),
                            headlines: vec![], source_count: 0,
                        };
                    }
                    _ => {
                        warn!("{} No news found by any method", agent);
                        return NewsResult {
                            sentiment: "NEUTRAL".to_string(),
                            summary: "ไม่พบข่าวสารที่เกี่ยวข้องในตลาด".to_string(), headlines: vec![], source_count: 0,
                        };
                    }
                }
            }
        }
    } else {
        // If no Tavily key, try Google News only
        match search_news_google_rss(symbol).await {
            Ok(results) if !results.is_empty() => {
                info!("{} Found {} articles via Google News", agent, results.len());
                let _ = log_tx.send(serde_json::json!({
                    "type": "agent_log", "symbol": symbol, "agent": "news_hunter", "status": "running",
                    "message": format!("พบข่าว {} รายการ (Google News) — กำลังวิเคราะห์ sentiment...", results.len())
                }).to_string());
                results
            }
            Err(e) => {
                warn!("{} Google News failed and no Tavily key", agent);
                let _ = log_tx.send(serde_json::json!({
                    "type": "agent_log", "symbol": symbol, "agent": "news_hunter", "status": "error",
                    "message": format!("ค้นข่าวไม่สำเร็จ: {}", e)
                }).to_string());
                return NewsResult {
                    sentiment: "NEUTRAL".to_string(),
                    summary: "ไม่สามารถค้นข่าวได้ — ไม่มี Tavily Key สำรอง".to_string(),
                    headlines: vec![], source_count: 0,
                };
            }
            _ => {
                return NewsResult {
                    sentiment: "NEUTRAL".to_string(),
                    summary: "ไม่พบข่าวสารที่เกี่ยวข้อง".to_string(), headlines: vec![], source_count: 0,
                };
            }
        }
    };

    let headlines: Vec<String> = articles.iter()
        .filter_map(|a| a.title.clone())
        .collect();

    let news_text: String = articles.iter()
        .filter_map(|a| {
            let title = a.title.as_deref().unwrap_or("");
            let content = a.content.as_deref().unwrap_or("");
            if title.is_empty() { None } else { Some(format!("- {}: {}", title, &content[..content.len().min(350)])) }
        })
        .collect::<Vec<_>>()
        .join("\n");

    if news_text.is_empty() {
        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": symbol, "agent": "news_hunter", "status": "done",
            "message": "ไม่พบข่าวที่เกี่ยวข้อง — ใช้ NEUTRAL"
        }).to_string());
        return NewsResult {
            sentiment: "NEUTRAL".to_string(),
            summary: "ไม่พบข่าวที่เกี่ยวข้อง".to_string(),
            headlines, source_count: articles.len(),
        };
    }

    // Step 2: Ask Gemini to analyze sentiment
    let prompt = format!(
r#"You are an expert financial news analyst. Analyze the news below and summarize sentiment for {symbol}.

News:
{news_text}

IMPORTANT: You MUST translate ALL text, including the summary, headlines, and content into pure THAI language. Do NOT use English for explanations.

Respond ONLY with a valid JSON object without markdown formatting blocks (DO NOT wrap in ```json), exactly matching this structure:
{{
  "sentiment": "BULLISH",
  "summary": "สรุปภาพรวม 2-3 ประโยคเป็นภาษาไทย",
  "stories": [
    {{
      "title": "แปล Headline เป็นภาษาไทย",
      "content": "แปลเนื้อหา 2-3 ประโยคเป็นภาษาไทย"
    }}
  ]
}}"#);

    match call_ai(gemini_key, model, &prompt, 0.2, 8192, true).await {
        Ok(response) => {
            let mut sentiment = "NEUTRAL".to_string();
            let mut summary = String::new();
            let mut th_headlines = Vec::new();
            
            let start = response.find('{');
            let end = response.rfind('}');
            let clean_json = match (start, end) {
                (Some(s), Some(e)) if s < e => &response[s..=e],
                _ => response.trim().trim_start_matches("```json").trim_start_matches("```").trim_end_matches("```").trim()
            };

            match serde_json::from_str::<serde_json::Value>(clean_json) {
                Ok(json_val) => {
                    if let Some(s) = json_val.get("sentiment").and_then(|v| v.as_str()) {
                        sentiment = s.to_uppercase();
                    }
                    if let Some(s) = json_val.get("summary").and_then(|v| v.as_str()) {
                        summary = s.to_string();
                    }
                    if let Some(arr) = json_val.get("stories").and_then(|v| v.as_array()) {
                        for story in arr {
                            if let (Some(title), Some(content)) = (
                                story.get("title").and_then(|v| v.as_str()),
                                story.get("content").and_then(|v| v.as_str())
                            ) {
                                th_headlines.push(format!("{} || {}", title, content));
                            }
                        }
                    }
                    // Catch cases where Gemini returns JSON but omits the 'summary' key
                    if summary.is_empty() {
                        summary = format!("Gemini did not return 'summary' key. Raw JSON: {}", clean_json);
                    }
                }
                Err(err) => {
                    warn!("{} Failed to parse Gemini JSON, falling back. Error: {}, Raw response: {}", agent, err, response);
                    for line in response.lines() {
                        let line = line.trim();
                        if line.to_uppercase().contains("BULLISH") { sentiment = "BULLISH".to_string(); }
                        else if line.to_uppercase().contains("BEARISH") { sentiment = "BEARISH".to_string(); }
                    }
                    summary = format!("JSON Parse Error: {}. Raw: {}", err, response.replace("\n", " ").trim());
                }
            }
            let final_headlines = if th_headlines.is_empty() { headlines } else { th_headlines };
            
            info!("{} Sentiment: {} — {}", agent, sentiment, summary);
            let _ = log_tx.send(serde_json::json!({
                "type": "agent_log_verbose", "symbol": symbol, "agent": "news_hunter",
                "prompt": prompt.clone(), "response": response.clone()
            }).to_string());
            let _ = log_tx.send(serde_json::json!({
                "type": "agent_log", "symbol": symbol, "agent": "news_hunter", "status": "done",
                "message": format!("✅ Sentiment: {} — {}", sentiment, summary)
            }).to_string());
            NewsResult { sentiment, summary, headlines: final_headlines, source_count: articles.len() }
        }
        Err(e) => {
            let _ = log_tx.send(serde_json::json!({
                "type": "agent_log", "symbol": symbol, "agent": "news_hunter", "status": "error",
                "message": format!("วิเคราะห์ sentiment ไม่สำเร็จ: {}", e)
            }).to_string());
            NewsResult {
                sentiment: "NEUTRAL".to_string(),
                summary: format!("Error: {}", e),
                headlines, source_count: articles.len(),
            }
        }
    }
}

// ──────────────────────────────────────────────
//  Agent 2: Chart Analyst (Gemini)
// ──────────────────────────────────────────────

#[allow(dead_code)]
pub async fn run_chart_analyst(
    gemini_key: &str, model: &str,
    symbol: &str, timeframe: &str,
    candles: &[crate::strategy::Candle],
    log_tx: &tokio::sync::broadcast::Sender<String>,
) -> ChartResult {
    let agent = "📊 Chart Analyst";
    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": symbol, "agent": "chart_analyst", "status": "running",
        "message": format!("กำลังวิเคราะห์กราฟ {} {} ({} candles)...", symbol, timeframe, candles.len())
    }).to_string());

    if candles.is_empty() {
        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": symbol, "agent": "chart_analyst", "status": "error",
            "message": "ไม่มีข้อมูล candle — รอ MT5 เชื่อมต่อ"
        }).to_string());
        return ChartResult {
            recommendation: "HOLD".to_string(), confidence: 20.0,
            reasoning: "ไม่มีข้อมูล candle ในระบบ — รอ MT5 เชื่อมต่อ".to_string(),
        };
    }

    let limited_data = candles.len() < 10;
    let recent = &candles[candles.len().saturating_sub(20)..];
    let candle_str: String = recent.iter().map(|c| {
        format!("O:{:.5} H:{:.5} L:{:.5} C:{:.5}", c.open, c.high, c.low, c.close)
    }).collect::<Vec<_>>().join("\n");

    let price = candles.last().map(|c| c.close).unwrap_or(0.0);
    
    // Method 1: Algorithmic Feature Extraction
    let ind = crate::strategy::compute_indicators(candles);
    let trend = if ind.ema_9 > ind.ema_21 && ind.ema_21 > ind.ema_50 {
        "UPTREND (Strong)"
    } else if ind.ema_9 < ind.ema_21 && ind.ema_21 < ind.ema_50 {
        "DOWNTREND (Strong)"
    } else if ind.ema_9 > ind.ema_50 {
        "UPTREND (Weak)"
    } else if ind.ema_9 < ind.ema_50 {
        "DOWNTREND (Weak)"
    } else {
        "SIDEWAYS"
    };

    // Method 4: Volume Profile Proxy (Time-at-Price calculation)
    let mut hvn = price;
    if !candles.is_empty() {
        let max_high = candles.iter().map(|c| c.high).fold(f64::MIN, f64::max);
        let min_low = candles.iter().map(|c| c.low).fold(f64::MAX, f64::min);
        let range = max_high - min_low;
        if range > 0.0 {
            let num_bins = 10;
            let bin_size = range / num_bins as f64;
            let mut bins = vec![0; num_bins];
            for c in candles {
                let lower_bin = ((c.low - min_low) / bin_size).floor() as usize;
                let upper_bin = ((c.high - min_low) / bin_size).floor() as usize;
                for b in lower_bin..=upper_bin.min(num_bins - 1) {
                    bins[b] += 1;
                }
            }
            let mut max_bincount = 0;
            let mut best_bin = 0;
            for (i, &count) in bins.iter().enumerate() {
                if count > max_bincount {
                    max_bincount = count;
                    best_bin = i;
                }
            }
            hvn = min_low + (best_bin as f64 + 0.5) * bin_size;
        }
    }

    let data_note = if limited_data {
        format!("\n\nNote: Limited data ({} candles only). Adjust confidence accordingly and be conservative.", candles.len())
    } else { String::new() };

    let prompt = format!(
r#"You are a professional technical analyst and algorithmic decision maker. Analyze the chart data and extracted features below.

Symbol: {symbol} | Timeframe: {timeframe} | Price: {price:.5} | Trend: {trend}

--- ALGORITHMIC FEATURES EXTRACTED (Use these facts instead of guessing!) ---
RSI (14): {rsi:.1}
EMA (9/21/50): {ema9:.5} / {ema21:.5} / {ema50:.5}
Bollinger Bands: Upper={bb_upper:.5}, Mid={bb_mid:.5}, Lower={bb_lower:.5}
Smart Money (SMC): Bullish FVG=[{fvg_bull}], Bearish FVG=[{fvg_bear}] 
Order Blocks: Bullish={ob_bull:.5}, Bearish={ob_bear:.5}
Volume Profile Proxy: Point of Control (HVN) = {hvn:.5}

--- RECENT RAW OHLC ({} candles) ---
{candle_str}{data_note}

Based on both the math-perfect indicators above and the raw price action, evaluate the following 10 Strategies and assign a Buy/Sell confidence score (0% = Strong Sell, 50% = Neutral, 100% = Strong Buy) to each:
1. Trend Following (EMA)
2. Mean Reversion (Bollinger)
3. Momentum (RSI)
4. Order Blocks (SMC)
5. Fair Value Gaps (SMC)
6. Volume Profile (HVN)
7. Price Action Breakout
8. Supply / Demand
9. Candlestick Patterns
10. Multi-Timeframe Structure

Then respond EXACTLY in this format:
RECOMMENDATION: [BUY/SELL/HOLD]
CONFIDENCE: [0-100]
REASONING: [1-2 sentence summary in Thai language]
STRATEGIES:
1. Trend: [X]% (BUY/SELL/HOLD) - [เหตุผลสั้นๆ 1 ประโยคภาษาไทย]
2. BB: [X]% (BUY/SELL/HOLD) - [เหตุผลสั้นๆ 1 ประโยคภาษาไทย]
3. RSI: [X]% (BUY/SELL/HOLD) - [เหตุผลสั้นๆ 1 ประโยคภาษาไทย]
4. OB: [X]% (BUY/SELL/HOLD) - [เหตุผลสั้นๆ 1 ประโยคภาษาไทย]
5. FVG: [X]% (BUY/SELL/HOLD) - [เหตุผลสั้นๆ 1 ประโยคภาษาไทย]
6. HVN: [X]% (BUY/SELL/HOLD) - [เหตุผลสั้นๆ 1 ประโยคภาษาไทย]
7. Breakout: [X]% (BUY/SELL/HOLD) - [เหตุผลสั้นๆ 1 ประโยคภาษาไทย]
8. S/D: [X]% (BUY/SELL/HOLD) - [เหตุผลสั้นๆ 1 ประโยคภาษาไทย]
9. Candle: [X]% (BUY/SELL/HOLD) - [เหตุผลสั้นๆ 1 ประโยคภาษาไทย]
10. Structure: [X]% (BUY/SELL/HOLD) - [เหตุผลสั้นๆ 1 ประโยคภาษาไทย]"#, 
        recent.len(),
        symbol=symbol, timeframe=timeframe, price=price, trend=trend,
        rsi=ind.rsi_14, ema9=ind.ema_9, ema21=ind.ema_21, ema50=ind.ema_50,
        bb_upper=ind.bb_upper, bb_mid=ind.bb_middle, bb_lower=ind.bb_lower,
        fvg_bull=ind.fair_value_gap_bull, fvg_bear=ind.fair_value_gap_bear,
        ob_bull=ind.order_block_bull, ob_bear=ind.order_block_bear,
        hvn=hvn, candle_str=candle_str, data_note=data_note
    );

    match call_ai(gemini_key, model, &prompt, 0.3, 800, false).await {
        Ok(response) => {
            let mut rec = "HOLD".to_string();
            let mut conf = 50.0;
            let mut reason = String::new();
            let mut strats = String::new();
            let mut parsing_strats = false;
            
            for line in response.lines() {
                let line = line.trim();
                if line.starts_with("RECOMMENDATION:") {
                    let v = line.replace("RECOMMENDATION:", "").trim().to_uppercase();
                    if v.contains("BUY") { rec = "BUY".to_string(); }
                    else if v.contains("SELL") { rec = "SELL".to_string(); }
                }
                else if line.starts_with("CONFIDENCE:") {
                    let v: String = line.replace("CONFIDENCE:", "").trim().chars()
                        .filter(|c| c.is_ascii_digit() || *c == '.').collect();
                    conf = v.parse().unwrap_or(50.0);
                }
                else if line.starts_with("REASONING:") {
                    reason = line.replace("REASONING:", "").trim().to_string();
                }
                else if line.starts_with("STRATEGIES:") {
                    parsing_strats = true;
                }
                else if parsing_strats && !line.is_empty() {
                    strats.push_str("\n");
                    strats.push_str(line);
                }
            }
            if reason.is_empty() { reason = response.chars().take(150).collect(); }
            
            let full_message = if !strats.is_empty() {
                format!("✅ {} (confidence {:.0}%) — {}\n\n📊 กลยุทธ์ (0=Sell, 100=Buy):{}", rec, conf, reason, strats)
            } else {
                format!("✅ {} (confidence {:.0}%) — {}", rec, conf, reason)
            };
            
            info!("{} {} — confidence {:.0}%", agent, rec, conf);
            let _ = log_tx.send(serde_json::json!({
                "type": "agent_log_verbose", "symbol": symbol, "agent": "chart_analyst",
                "prompt": prompt.clone(), "response": response.clone()
            }).to_string());
            let _ = log_tx.send(serde_json::json!({
                "type": "agent_log", "symbol": symbol, "agent": "chart_analyst", "status": "done",
                "message": full_message
            }).to_string());
            ChartResult { recommendation: rec, confidence: conf, reasoning: reason }
        }
        Err(e) => {
            let _ = log_tx.send(serde_json::json!({
                "type": "agent_log", "symbol": symbol, "agent": "chart_analyst", "status": "error",
                "message": format!("วิเคราะห์กราฟไม่สำเร็จ: {}", e)
            }).to_string());
            ChartResult { recommendation: "HOLD".to_string(), confidence: 30.0, reasoning: format!("Error: {}", e) }
        }
    }
}

// ──────────────────────────────────────────────
//  Agent 4: Calendar Watcher (Free API)
// ──────────────────────────────────────────────

pub async fn run_calendar_watcher(
    symbol: &str,
    log_tx: &tokio::sync::broadcast::Sender<String>,
) -> CalendarResult {
    let agent = "📅 Calendar";
    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": symbol, "agent": "calendar", "status": "running",
        "message": "กำลังตรวจสอบปฏิทินเศรษฐกิจ..."
    }).to_string());

    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(10))
        .build().unwrap_or_default();

    let events = match client.get(FOREX_CALENDAR_URL).send().await {
        Ok(resp) if resp.status().is_success() => {
            match resp.json::<Vec<ForexCalendarEvent>>().await {
                Ok(all_events) => {
                    // Filter high-impact events within the next 1 hour
                    let now = chrono::Utc::now();
                    let relevant: Vec<_> = all_events.into_iter().filter(|e| {
                        let is_high = e.impact.as_deref() == Some("High");
                        let is_soon = e.date.as_ref().map(|d| {
                            chrono::DateTime::parse_from_str(d, "%Y-%m-%dT%H:%M:%S%z")
                                .map(|dt| {
                                    let diff = dt.signed_duration_since(now);
                                    diff.num_minutes() >= -30 && diff.num_minutes() <= 60
                                }).unwrap_or(false)
                        }).unwrap_or(false);
                        // Also filter by currency relevance
                        let currency_match = e.country.as_ref().map(|c| {
                            let sym_upper = symbol.to_uppercase();
                            match c.as_str() {
                                "USD" => sym_upper.contains("USD") || sym_upper.contains("XAU"),
                                "EUR" => sym_upper.contains("EUR"),
                                "GBP" => sym_upper.contains("GBP"),
                                "JPY" => sym_upper.contains("JPY"),
                                "AUD" => sym_upper.contains("AUD"),
                                "CAD" => sym_upper.contains("CAD"),
                                "CHF" => sym_upper.contains("CHF"),
                                "NZD" => sym_upper.contains("NZD"),
                                _ => false,
                            }
                        }).unwrap_or(false);
                        is_high && is_soon && currency_match
                    }).collect();
                    relevant
                }
                Err(_) => vec![],
            }
        }
        _ => vec![],
    };

    let event_names: Vec<String> = events.iter()
        .filter_map(|e| e.title.clone())
        .collect();

    let high_impact = !events.is_empty();
    let warning = if high_impact {
        format!("⚠️ พบข่าวสำคัญ {} รายการ: {}", events.len(), event_names.join(", "))
    } else {
        "✅ ไม่มีข่าวสำคัญในช่วงนี้".to_string()
    };

    info!("{} High impact: {} — {}", agent, high_impact, warning);
    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": symbol, "agent": "calendar", "status": "done",
        "message": &warning
    }).to_string());

    CalendarResult { high_impact_soon: high_impact, events, warning }
}

pub async fn fetch_macro_indicators(
    gemini_key: &str,
    model: &str,
    tavily_key: &str,
    log_tx: &tokio::sync::broadcast::Sender<String>,
) -> MacroResult {
    let fallback = MacroResult {
        fed: MacroItem { value: "-".to_string(), date: "-".to_string() },
        nfp: MacroItem { value: "-".to_string(), date: "-".to_string() },
        cpi: MacroItem { value: "-".to_string(), date: "-".to_string() },
    };

    if gemini_key.is_empty() { return fallback; }
    
    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": "Macro", "agent": "calendar", "status": "running",
        "message": "กำลังดึงข้อมูล FED, NFP, CPI ตัวล่าสุดผ่านตารางเศรษฐกิจ..."
    }).to_string());

    let articles = if !tavily_key.is_empty() {
        match search_news_tavily(tavily_key, "Latest US Federal Reserve Interest Rate, Non-Farm Payrolls (NFP), and CPI results percentages dates").await {
            Ok(res) => res,
            Err(e) => {
                warn!("Macro Tavily search failed: {}", e);
                vec![]
            }
        }
    } else {
        vec![]
    };

    let mut context_text = String::new();
    for (i, article) in articles.into_iter().take(5).enumerate() {
        let title = article.title.as_deref().unwrap_or("No Title");
        let content = article.content.as_deref().unwrap_or("No Content");
        context_text.push_str(&format!("[{}] Title: {}\nContent: {}\n\n", i+1, title, content));
    }

    let prompt = format!(
        "You are an expert economic analyst. Find the most recently announced values and their exact announcement dates (in Thai) for the following US macro indicators.\n\
        If the provided Context is empty or insufficient, USE YOUR OWN MOST RECENT KNOWLEDGE to provide the answers.\n\
        1. FED Interest Rate (อัตราดอกเบี้ยนโยบายสหรัฐ)\n\
        2. NFP (Non-Farm Payrolls)\n\
        3. CPI (Consumer Price Index Y/Y or M/M)\n\n\
        Context:\n{}\n\n\
        Output MUST be ONLY valid JSON matching this exact format, with no markdown formatting or backticks around it:\n\
        {{\n  \"fed\": {{ \"value\": \"5.50%\", \"date\": \"1 พ.ค. 2024\" }},\n  \"nfp\": {{ \"value\": \"175K\", \"date\": \"3 พ.ค. 2024\" }},\n  \"cpi\": {{ \"value\": \"3.4%\", \"date\": \"15 พ.ค. 2024\" }}\n}}",
        context_text
    );

    match call_ai(gemini_key, model, &prompt, 0.2, 500, true).await {
        Ok(res) => {
            let clean_json = res.trim().trim_start_matches("```json").trim_start_matches("```").trim_end_matches("```").trim();
            let _ = log_tx.send(serde_json::json!({
                "type": "agent_log_verbose", "symbol": "Macro", "agent": "calendar_macro",
                "prompt": prompt.clone(), "response": res.clone()
            }).to_string());
            match serde_json::from_str::<MacroResult>(clean_json) {
                Ok(macro_data) => {
                    let _ = log_tx.send(serde_json::json!({
                        "type": "agent_log", "symbol": "Macro", "agent": "calendar", "status": "done",
                        "message": format!("ดึงข้อมูลเสร็จสิ้น FED: {}, NFP: {}, CPI: {}", macro_data.fed.value, macro_data.nfp.value, macro_data.cpi.value)
                    }).to_string());
                    macro_data
                },
                Err(e) => {
                    warn!("Failed to parse Gemini macro result: {} \nResult: {}", e, clean_json);
                    fallback
                }
            }
        }
        Err(e) => {
            warn!("Failed to call Gemini for macro indicators: {}", e);
            fallback
        }
    }
}

// ──────────────────────────────────────────────
//  Agent 5: Risk Manager (Internal Data)
// ──────────────────────────────────────────────

pub fn run_risk_manager(
    symbol: &str,
    balance: f64, equity: f64,
    open_positions: usize, max_positions: usize,
    max_drawdown_pct: f64,
    emergency_stop: bool,
    log_tx: &tokio::sync::broadcast::Sender<String>,
) -> RiskResult {
    let _agent = "🛡️ Risk Manager";
    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": symbol, "agent": "risk_manager", "status": "running",
        "message": format!("ตรวจสอบความเสี่ยง... Balance: ${:.2}, Equity: ${:.2}", balance, equity)
    }).to_string());

    let drawdown = if balance > 0.0 { ((balance - equity) / balance) * 100.0 } else { 0.0 };

    // Check conditions
    if emergency_stop {
        let msg = "🚨 Emergency Stop เปิดอยู่ — ห้ามเทรด!";
        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": symbol, "agent": "risk_manager", "status": "done",
            "message": msg
        }).to_string());
        return RiskResult {
            approved: false, reason: msg.to_string(),
            current_drawdown: drawdown, open_positions, max_positions,
        };
    }

    if open_positions >= max_positions {
        let msg = format!("⛔ ออเดอร์เต็ม ({}/{})", open_positions, max_positions);
        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": symbol, "agent": "risk_manager", "status": "done",
            "message": &msg
        }).to_string());
        return RiskResult {
            approved: false, reason: msg,
            current_drawdown: drawdown, open_positions, max_positions,
        };
    }

    if drawdown > max_drawdown_pct {
        let msg = format!("🚨 Drawdown {:.2}% เกิน limit {:.1}%", drawdown, max_drawdown_pct);
        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": symbol, "agent": "risk_manager", "status": "done",
            "message": &msg
        }).to_string());
        return RiskResult {
            approved: false, reason: msg,
            current_drawdown: drawdown, open_positions, max_positions,
        };
    }

    let msg = format!("✅ ผ่าน — DD {:.2}%, ออเดอร์ {}/{}", drawdown, open_positions, max_positions);
    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": symbol, "agent": "risk_manager", "status": "done",
        "message": &msg
    }).to_string());
    RiskResult {
        approved: true, reason: msg,
        current_drawdown: drawdown, open_positions, max_positions,
    }
}

// ──────────────────────────────────────────────
//  Agent 3: Decision Maker (Orchestrator)
// ──────────────────────────────────────────────

pub async fn run_decision_maker(
    gemini_key: &str, model: &str,
    symbol: &str,
    news: &NewsResult, chart: &ChartResult,
    calendar: &CalendarResult, risk: &RiskResult,
    log_tx: &tokio::sync::broadcast::Sender<String>,
) -> (String, f64, String) {
    let _agent = "🧠 Decision Maker";
    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": symbol, "agent": "decision_maker", "status": "running",
        "message": "กำลังรวมข้อมูลจากทุก Agent เพื่อตัดสินใจ..."
    }).to_string());

    // If risk manager blocked, don't even ask AI
    if !risk.approved {
        let msg = format!("❌ BLOCKED โดย Risk Manager: {}", risk.reason);
        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": symbol, "agent": "decision_maker", "status": "done",
            "message": &msg
        }).to_string());
        return ("BLOCKED".to_string(), 0.0, msg);
    }

    // If high-impact news coming, be cautious
    if calendar.high_impact_soon {
        let msg = format!("⚠️ HOLD — มีข่าวสำคัญใกล้ออก: {}", calendar.warning);
        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": symbol, "agent": "decision_maker", "status": "done",
            "message": &msg
        }).to_string());
        return ("HOLD".to_string(), 30.0, msg);
    }

    let prompt = format!(
r#"You are a professional fund manager. Make a final trading decision based on the data below.

## Agent Reports

### News (News Hunter):
- Sentiment: {news_sentiment}
- Summary: {news_summary}

### Chart (Chart Analyst):
- Recommendation: {chart_rec}
- Confidence: {chart_conf:.0}%
- Reasoning: {chart_reason}

### Calendar:
- {calendar_warning}

### Risk Manager:
- {risk_reason}

## Instructions
Combine all data and make a final decision for {symbol}.
- If news BULLISH + chart BUY → BUY with high confidence
- If news BEARISH + chart SELL → SELL with high confidence
- If news conflicts with chart → reduce confidence or HOLD

Respond:
DECISION: [BUY/SELL/HOLD]
CONFIDENCE: [0-100]
REASONING: [concise summary in Thai language]"#,
        news_sentiment = news.sentiment,
        news_summary = news.summary,
        chart_rec = chart.recommendation,
        chart_conf = chart.confidence,
        chart_reason = chart.reasoning,
        calendar_warning = calendar.warning,
        risk_reason = risk.reason,
    );

    match call_ai(gemini_key, model, &prompt, 0.2, 400, false).await {
        Ok(response) => {
            let _ = log_tx.send(serde_json::json!({
                "type": "agent_log_verbose", "symbol": symbol, "agent": "decision_maker",
                "prompt": prompt, "response": response
            }).to_string());
            
            let mut decision = "HOLD".to_string();
            let mut confidence = 50.0;
            let mut reasoning = String::new();
            for line in response.lines() {
                let line = line.trim();
                if line.starts_with("DECISION:") {
                    let v = line.replace("DECISION:", "").trim().to_uppercase();
                    if v.contains("BUY") { decision = "BUY".to_string(); }
                    else if v.contains("SELL") { decision = "SELL".to_string(); }
                }
                if line.starts_with("CONFIDENCE:") {
                    let v: String = line.replace("CONFIDENCE:", "").trim().chars()
                        .filter(|c| c.is_ascii_digit() || *c == '.').collect();
                    confidence = v.parse().unwrap_or(50.0);
                }
                if line.starts_with("REASONING:") {
                    reasoning = line.replace("REASONING:", "").trim().to_string();
                }
            }
            if reasoning.is_empty() { reasoning = response.chars().take(200).collect(); }
            let _ = log_tx.send(serde_json::json!({
                "type": "agent_log", "symbol": symbol, "agent": "decision_maker", "status": "done",
                "message": format!("✅ ตัดสินใจ: {} (confidence {:.0}%) — {}", decision, confidence, reasoning)
            }).to_string());
            (decision, confidence, reasoning)
        }
        Err(e) => {
            let msg = format!("Error: {}", e);
            let _ = log_tx.send(serde_json::json!({
                "type": "agent_log", "symbol": symbol, "agent": "decision_maker", "status": "error",
                "message": &msg
            }).to_string());
            ("HOLD".to_string(), 0.0, msg)
        }
    }
}

// ──────────────────────────────────────────────
//  Master Orchestrator: Run All 5 Agents
// ──────────────────────────────────────────────

#[allow(dead_code)]
pub async fn run_all_agents(
    gemini_key: &str, model: &str, tavily_key: &str,
    symbol: &str, timeframe: &str,
    candles: &[crate::strategy::Candle],
    balance: f64, equity: f64,
    open_positions: usize, max_positions: usize,
    max_drawdown_pct: f64, emergency_stop: bool,
    log_tx: &tokio::sync::broadcast::Sender<String>,
) -> MultiAgentResult {
    info!("🤖 [Multi-Agent] Starting 5-agent analysis for {} {}...", symbol, timeframe);

    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": symbol, "agent": "orchestrator", "status": "running",
        "message": format!("🚀 เริ่มวิเคราะห์ {} {} ด้วย 5 Agents...", symbol, timeframe)
    }).to_string());

    // Run Agent 1 (News) and Agent 2 (Chart) in PARALLEL
    let (news_result, chart_result) = {
        let news_fut = run_news_hunter(gemini_key, model, tavily_key, symbol, log_tx);
        let chart_fut = run_chart_analyst(gemini_key, model, symbol, timeframe, candles, log_tx);
        tokio::join!(news_fut, chart_fut)
    };

    // Run Agent 4 (Calendar) — fast, doesn't need to wait
    let calendar_result = run_calendar_watcher(symbol, log_tx).await;

    // Run Agent 5 (Risk) — instant, no API call
    let risk_result = run_risk_manager(
        symbol, balance, equity, open_positions, max_positions,
        max_drawdown_pct, emergency_stop, log_tx,
    );

    // Run Agent 3 (Decision) — needs results from all other agents
    let (decision, confidence, reasoning) = run_decision_maker(
        gemini_key, model, symbol,
        &news_result, &chart_result, &calendar_result, &risk_result,
        log_tx,
    ).await;

    let model_name = if model.is_empty() { DEFAULT_MODEL } else { model };

    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": symbol, "agent": "orchestrator", "status": "done",
        "message": format!("🏁 ผลสุดท้าย: {} (confidence {:.0}%)", decision, confidence)
    }).to_string());

    info!("🤖 [Multi-Agent] Final: {} {} → {} ({:.0}%)", symbol, timeframe, decision, confidence);

    MultiAgentResult {
        final_decision: decision,
        confidence,
        news: news_result,
        chart: chart_result,
        calendar: calendar_result,
        risk: risk_result,
        reasoning,
        model: model_name.to_string(),
    }
}

// ──────────────────────────────────────────────
//  Master Orchestrator: Multi-Timeframe Version
// ──────────────────────────────────────────────

pub async fn run_all_agents_multi_tf(
    gemini_key: &str, model: &str, tavily_key: &str,
    symbol: &str,
    multi_tf_candles: &[(&str, Vec<crate::strategy::Candle>)],
    balance: f64, equity: f64,
    open_positions: usize, max_positions: usize,
    max_drawdown_pct: f64, emergency_stop: bool,
    _ai_mode: &str,
    disabled_agents: &[String],
    global_news: Option<NewsResult>,
    log_tx: &tokio::sync::broadcast::Sender<String>,
) -> MultiAgentResult {
    info!("🤖 [Multi-Agent] Starting Multi-TF analysis for {}...", symbol);

    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": symbol, "agent": "orchestrator", "status": "running",
        "message": format!("🚀 เริ่มวิเคราะห์ {} ด้วย 5 Agents + Multi-Timeframe (M5/M15/H1/H4)...", symbol)
    }).to_string());

    // Run Agent 1 (News) in parallel with multi-timeframe Chart analysis
    let news_fut = async {
        if disabled_agents.contains(&"news_hunter".to_string()) {
            let _ = log_tx.send(serde_json::json!({
                "type": "agent_log", "symbol": symbol, "agent": "news_hunter", "status": "done",
                "message": "⏸️ SKIPPED (Disabled by User)"
            }).to_string());
            NewsResult { sentiment: "NEUTRAL".to_string(), summary: "SKIPPED".to_string(), headlines: vec![], source_count: 0 }
        } else if let Some(global_news_result) = global_news {
            let _ = log_tx.send(serde_json::json!({
                "type": "agent_log", "symbol": symbol, "agent": "news_hunter", "status": "done",
                "message": "🌍 ใช้ข้อมูลข่าวสารจาก Agent ส่วนกลาง"
            }).to_string());
            global_news_result
        } else {
            run_news_hunter(gemini_key, model, tavily_key, symbol, log_tx).await
        }
    };

    // Run Chart Analyst on all timeframes
    let chart_fut = async {
        if disabled_agents.contains(&"chart_analyst".to_string()) {
            let _ = log_tx.send(serde_json::json!({
                "type": "agent_log", "symbol": symbol, "agent": "chart_analyst", "status": "done",
                "message": "⏸️ SKIPPED (Disabled by User)"
            }).to_string());
            return ChartResult {
                recommendation: "HOLD".to_string(),
                confidence: 50.0,
                reasoning: "SKIPPED".to_string(),
            };
        }

        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": symbol, "agent": "chart_analyst", "status": "running",
            "message": "📊 วิเคราะห์หลาย Timeframe พร้อมกัน: M5, M15, H1, H4..."
        }).to_string());

    // Build multi-TF chart summary for AI
    let mut tf_summaries = Vec::new();
    for (tf, candles) in multi_tf_candles {
        let count = candles.len();
        if candles.is_empty() {
            tf_summaries.push(format!("{}: ไม่มีข้อมูล", tf));
            continue;
        }
        
        let recent = &candles[candles.len().saturating_sub(20)..];
        let candle_str: String = recent.iter().map(|c| {
            format!("O:{:.5} H:{:.5} L:{:.5} C:{:.5}", c.open, c.high, c.low, c.close)
        }).collect::<Vec<_>>().join("\n");
        let price = candles.last().map(|c| c.close).unwrap_or(0.0);
        let trend = if candles.len() >= 5 {
            let s = candles[candles.len().saturating_sub(5)].close;
            let e = candles[candles.len()-1].close;
            if e > s * 1.001 { "UPTREND" } else if e < s * 0.999 { "DOWNTREND" } else { "SIDEWAYS" }
        } else { "UNKNOWN" };
        
        let mut base_summary = format!(
            "=== {} ({} candles) | Price: {:.5} | Trend: {} ===\n{}", tf, count, price, trend, candle_str
        );

        let ind = crate::strategy::compute_indicators(candles);
        
        // Calculate Volume Profile Proxy (HVN)
        let mut hvn = price;
        if !candles.is_empty() {
            let max_high = candles.iter().map(|c| c.high).fold(f64::MIN, f64::max);
            let min_low = candles.iter().map(|c| c.low).fold(f64::MAX, f64::min);
            let range = max_high - min_low;
            if range > 0.0 {
                let num_bins = 10;
                let bin_size = range / num_bins as f64;
                let mut bins = vec![0; num_bins];
                for c in candles {
                    let lower_bin = ((c.low - min_low) / bin_size).floor() as usize;
                    let upper_bin = ((c.high - min_low) / bin_size).floor() as usize;
                    for b in lower_bin..=upper_bin.min(num_bins - 1) {
                        bins[b] += 1;
                    }
                }
                let mut best_bin = 0;
                let mut max_bincount = 0;
                for (i, &count) in bins.iter().enumerate() {
                    if count > max_bincount {
                        max_bincount = count;
                        best_bin = i;
                    }
                }
                hvn = min_low + (best_bin as f64 + 0.5) * bin_size;
            }
        }
        
        let extracted = format!(
            "\n--- ALGORITHMIC FEATURES EXTRACTED ---\n\
            RSI (14): {:.1}\n\
            EMA (9/21/50): {:.5} / {:.5} / {:.5}\n\
            Bollinger Bands: Upper={:.5}, Mid={:.5}, Lower={:.5}\n\
            Smart Money (SMC): Bullish_FVG=[{}], Bearish_FVG=[{}]\n\
            Order Blocks: Bullish={:.5}, Bearish={:.5}\n\
            Volume Profile Proxy: Point of Control (HVN) = {:.5}\n",
            ind.rsi_14, ind.ema_9, ind.ema_21, ind.ema_50,
            ind.bb_upper, ind.bb_middle, ind.bb_lower,
            ind.fair_value_gap_bull, ind.fair_value_gap_bear,
            ind.order_block_bull, ind.order_block_bear,
            hvn
        );
        base_summary.push_str(&extracted);

        let mut strat_results = Vec::new();
        for &strat in crate::strategy::ALL_STRATEGIES {
            let (signal, reason) = crate::strategy::evaluate_strategy(strat, &ind);
            let sig_str = match signal {
                crate::strategy::Signal::Buy => "BUY",
                crate::strategy::Signal::Sell => "SELL",
                crate::strategy::Signal::None => "HOLD",
            };
            strat_results.push(format!("{}: {} ({})", strat, sig_str, reason));
        }
        base_summary.push_str("\n\n10-Strategy Outputs:\n");
        base_summary.push_str(&strat_results.join("\n"));

        tf_summaries.push(base_summary);
    }

    let multi_tf_prompt = format!(
r#"You are a professional multi-timeframe technical analyst. Analyze ALL the timeframes below for {symbol}.

{tf_data}

For each timeframe, identify:
1. Trend direction
2. Key support/resistance
3. Candlestick patterns
4. The 10-Strategies signals provided

Then determine:
- Which timeframe gives the BEST entry signal right now?
- What is the overall market bias from combining all timeframes?
- Based on ALL timeframes, evaluate the overall confidence percentage for each of the 10 strategies over the overall direction.

Respond in this EXACT format (Do not use Markdown blocks):
BEST_TIMEFRAME: [M5/M15/H1/H4]
RECOMMENDATION: [BUY/SELL/HOLD]
CONFIDENCE: [0-100]
REASONING: [2-3 sentence multi-timeframe summary in Thai language]
TF_M5: [BUY/SELL/HOLD]
TF_M15: [BUY/SELL/HOLD]
TF_H1: [BUY/SELL/HOLD]
TF_H4: [BUY/SELL/HOLD]
STRATEGIES:
1. Trend: [0-100]%
2. MeanReversion: [0-100]%
3. Momentum: [0-100]%
4. Breakout: [0-100]%
5. SMC: [0-100]%
6. VolumeProfile: [0-100]%
7. VWAP: [0-100]%
8. Grid: [0-100]%
9. Martingale: [0-100]%
10. Arbitrage: [0-100]%"#, tf_data = tf_summaries.join("\n\n"));

    // Run chart analysis via Gemini
        match call_ai(gemini_key, model, &multi_tf_prompt, 0.3, 600, false).await {
            Ok(text) => {
                let _ = log_tx.send(serde_json::json!({
                    "type": "agent_log_verbose", "symbol": symbol, "agent": "orchestrator",
                    "prompt": multi_tf_prompt, "response": text
                }).to_string());

                let mut rec = "HOLD".to_string();
                let mut conf = 50.0;
                let mut reason = String::new();
                let mut best_tf = "M15".to_string();
                let mut tf_m5 = "HOLD".to_string();
                let mut tf_m15 = "HOLD".to_string();
                let mut tf_h1 = "HOLD".to_string();
                let mut tf_h4 = "HOLD".to_string();
                let mut strats = Vec::new();
                let mut in_strats_block = false;
                
                for line in text.lines() {
                    let l = line.trim();
                    if l.is_empty() { continue; }
                    
                    if l.starts_with("STRATEGIES:") {
                        in_strats_block = true;
                        continue;
                    }

                    if in_strats_block {
                        if l.chars().next().unwrap_or(' ').is_ascii_digit() && l.contains(":") {
                            strats.push(l.to_string());
                        } else if l.starts_with("BEST_TIMEFRAME:") || l.starts_with("RECOMMENDATION:") {
                            in_strats_block = false; // Exited strats
                        } else {
                            continue;
                        }
                    }

                    if !in_strats_block {
                        if l.starts_with("BEST_TIMEFRAME:") { best_tf = l.replace("BEST_TIMEFRAME:", "").trim().to_string(); }
                        if l.starts_with("RECOMMENDATION:") {
                            let v = l.replace("RECOMMENDATION:", "").trim().to_uppercase();
                            if v.contains("BUY") { rec = "BUY".into() } else if v.contains("SELL") { rec = "SELL".into() }
                        }
                        if l.starts_with("CONFIDENCE:") {
                            let v: String = l.replace("CONFIDENCE:", "").trim().chars().filter(|c| c.is_ascii_digit() || *c == '.').collect();
                            conf = v.parse().unwrap_or(50.0);
                        }
                        if l.starts_with("REASONING:") { reason = l.replace("REASONING:", "").trim().to_string(); }
                        if l.starts_with("TF_M5:") { let v = l.replace("TF_M5:", "").trim().to_uppercase(); tf_m5 = if v.contains("BUY"){"BUY".into()} else if v.contains("SELL"){"SELL".into()} else {"HOLD".into()}; }
                        if l.starts_with("TF_M15:") { let v = l.replace("TF_M15:", "").trim().to_uppercase(); tf_m15 = if v.contains("BUY"){"BUY".into()} else if v.contains("SELL"){"SELL".into()} else {"HOLD".into()}; }
                        if l.starts_with("TF_H1:") { let v = l.replace("TF_H1:", "").trim().to_uppercase(); tf_h1 = if v.contains("BUY"){"BUY".into()} else if v.contains("SELL"){"SELL".into()} else {"HOLD".into()}; }
                        if l.starts_with("TF_H4:") { let v = l.replace("TF_H4:", "").trim().to_uppercase(); tf_h4 = if v.contains("BUY"){"BUY".into()} else if v.contains("SELL"){"SELL".into()} else {"HOLD".into()}; }
                    }
                }
                if reason.is_empty() { reason = text.chars().take(200).collect(); }
                
                let strats_display = if !strats.is_empty() {
                    format!("\nSTRATEGIES: {}", strats.join(", "))
                } else {
                    "".to_string()
                };

                let _ = log_tx.send(serde_json::json!({
                    "type": "agent_log", "symbol": symbol, "agent": "chart_analyst", "status": "done",
                    "message": format!("📊 Best TF: {} → {} ({:.0}%) | M5:{} M15:{} H1:{} H4:{}{}", best_tf, rec, conf, tf_m5, tf_m15, tf_h1, tf_h4, strats_display)
                }).to_string());
                
                ChartResult {
                    recommendation: rec,
                    confidence: conf,
                    reasoning: format!("[Best: {}] {} | M5:{} M15:{} H1:{} H4:{}\n{}", best_tf, reason, tf_m5, tf_m15, tf_h1, tf_h4, strats.join("\n")),
                }
            }
            Err(e) => {
                let _ = log_tx.send(serde_json::json!({
                    "type": "agent_log", "symbol": symbol, "agent": "chart_analyst", "status": "error",
                    "message": format!("วิเคราะห์กราฟไม่สำเร็จ: {}", e)
                }).to_string());
                ChartResult {
                    recommendation: "HOLD".to_string(), confidence: 30.0,
                    reasoning: format!("Error: {}", e),
                }
            }
        }
    };

    let (news_result, chart_result) = tokio::join!(news_fut, chart_fut);

    // Run Calendar + Risk
    let calendar_result = if disabled_agents.contains(&"calendar".to_string()) {
        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": symbol, "agent": "calendar", "status": "done",
            "message": "⏸️ SKIPPED (Disabled by User)"
        }).to_string());
        CalendarResult { high_impact_soon: false, warning: "SKIPPED".to_string(), events: vec![] }
    } else {
        run_calendar_watcher(symbol, log_tx).await
    };
    
    let risk_result = if disabled_agents.contains(&"risk_manager".to_string()) {
        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": symbol, "agent": "risk_manager", "status": "done",
            "message": "⏸️ SKIPPED (Disabled by User)"
        }).to_string());
        RiskResult { approved: true, reason: "SKIPPED".to_string(), current_drawdown: 0.0, open_positions: 0, max_positions: 0 }
    } else {
        run_risk_manager(
            symbol, balance, equity, open_positions, max_positions,
            max_drawdown_pct, emergency_stop, log_tx,
        )
    };

    // Run Decision Maker
    let (decision, confidence, reasoning) = if disabled_agents.contains(&"decision_maker".to_string()) {
        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": symbol, "agent": "decision_maker", "status": "done",
            "message": "⏸️ SKIPPED (Disabled by User)"
        }).to_string());
        ("HOLD".to_string(), 0.0, "Decision Maker agent disabled by user. Defaulting to HOLD.".to_string())
    } else {
        run_decision_maker(
            gemini_key, model, symbol,
            &news_result, &chart_result, &calendar_result, &risk_result,
            log_tx,
        ).await
    };

    let model_name = if model.is_empty() { DEFAULT_MODEL } else { model };

    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": symbol, "agent": "orchestrator", "status": "done",
        "message": format!("🏁 ผลสุดท้าย: {} (confidence {:.0}%)", decision, confidence)
    }).to_string());

    info!("🤖 [Multi-Agent] Final: {} Multi-TF → {} ({:.0}%)", symbol, decision, confidence);

    MultiAgentResult {
        final_decision: decision,
        confidence,
        news: news_result,
        chart: chart_result,
        calendar: calendar_result,
        risk: risk_result,
        reasoning,
        model: model_name.to_string(),
    }
}

// ──────────────────────────────────────────────
//  Original functions (backward compatibility)
// ──────────────────────────────────────────────

pub async fn analyze_market(
    api_key: &str, model: &str, symbol: &str, timeframe: &str,
    candles: &[crate::strategy::Candle], current_price: f64, strategy: &str,
) -> Result<AiAnalysis, String> {
    let recent = if candles.len() > 20 { &candles[candles.len()-20..] } else { candles };
    let candle_str: String = recent.iter().map(|c| format!("O:{:.5} H:{:.5} L:{:.5} C:{:.5}", c.open, c.high, c.low, c.close)).collect::<Vec<_>>().join("\n");
    let trend = if candles.len() >= 10 { let s=candles[candles.len()-10].close; let e=candles[candles.len()-1].close; if e>s*1.001{"UPTREND"}else if e<s*0.999{"DOWNTREND"}else{"SIDEWAYS"} } else { "UNKNOWN" };
    let pc = if candles.len()>=2 { ((candles[candles.len()-1].close - candles[candles.len()-2].close)/candles[candles.len()-2].close)*100.0 } else { 0.0 };
    let prompt = format!("You are an expert trading analyst. Respond REASONING in Thai language only.\nSymbol: {symbol} | TF: {timeframe} | Price: {current_price:.5} | Change: {pc:.4}% | Trend: {trend} | Strategy: {strategy}\n\nOHLC:\n{candle_str}\n\nAnalyze price action, support/resistance, candlestick patterns then respond:\nRECOMMENDATION: [BUY/SELL/HOLD]\nCONFIDENCE: [0-100]\nREASONING: [concise reasoning in Thai language]");
    let text = call_ai(api_key, model, &prompt, 0.3, 500, false).await?;
    let mut rec="HOLD".to_string(); let mut conf=50.0; let mut reason=String::new();
    for line in text.lines() { let l=line.trim();
        if l.starts_with("RECOMMENDATION:") { let v=l.replace("RECOMMENDATION:","").trim().to_uppercase(); if v.contains("BUY"){rec="BUY".into()}else if v.contains("SELL"){rec="SELL".into()} }
        if l.starts_with("CONFIDENCE:") { let v:String=l.replace("CONFIDENCE:","").trim().chars().filter(|c|c.is_ascii_digit()||*c=='.').collect(); conf=v.parse().unwrap_or(50.0); }
        if l.starts_with("REASONING:") { reason=l.replace("REASONING:","").trim().to_string(); }
    }
    if reason.is_empty() { reason=text.chars().take(200).collect(); }
    Ok(AiAnalysis{recommendation:rec,confidence:conf,reasoning:reason,full_analysis:text,model:if model.is_empty(){DEFAULT_MODEL}else{model}.to_string()})
}

pub async fn test_connection(api_key: &str, model: &str) -> Result<String, String> {
    if api_key.is_empty() { return Err("API Key is empty".to_string()); }
    let text = call_gemini(api_key, model, "Answer in 1 line in Thai: What AI model are you?", 0.5, 100, false).await?;
    info!("🤖 [AI] Test successful: {}", text.trim());
    Ok(text.trim().to_string())
}

pub async fn test_ollama_connection() -> Result<String, String> {
    // First check if Ollama is running
    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(5))
        .build().map_err(|e| format!("HTTP error: {}", e))?;

    let resp = client.get(format!("{}/api/tags", OLLAMA_API_BASE))
        .send().await
        .map_err(|_| "Ollama ไม่ทำงาน — กรุณาเปิด Ollama ก่อน (systemctl start ollama)".to_string())?;

    if !resp.status().is_success() {
        return Err("Ollama ตอบกลับผิดปกติ".to_string());
    }

    // List available models
    let body: serde_json::Value = resp.json().await.map_err(|e| format!("Parse error: {}", e))?;
    let models: Vec<String> = body["models"].as_array()
        .map(|arr| arr.iter().filter_map(|m| m["name"].as_str().map(|s| s.to_string())).collect())
        .unwrap_or_default();

    if models.is_empty() {
        return Err("Ollama ทำงานอยู่ แต่ยังไม่มีโมเดล — กรุณา ollama pull gemma4:e4b".to_string());
    }

    // Quick test with the first available model
    let test_model = models.first().unwrap();
    match call_ollama(test_model, "ตอบสั้นๆ 1 ประโยค: คุณคือ AI โมเดลอะไร?", 0.5, 50).await {
        Ok(text) => {
            info!("🏠 [Ollama] Test successful: {}", text.trim());
            Ok(format!("✅ Ollama พร้อมใช้งาน | Models: {} | ตอบ: {}", models.join(", "), text.trim()))
        }
        Err(e) => Err(format!("Ollama test failed: {}", e)),
    }
}

pub async fn test_tavily_connection(tavily_key: &str) -> Result<String, String> {
    if tavily_key.is_empty() { return Err("Tavily API Key is empty".to_string()); }
    
    let keys: Vec<&str> = tavily_key.split(',').map(|s| s.trim()).filter(|s| !s.is_empty()).collect();
    if keys.is_empty() { return Err("Tavily API Key list is empty".to_string()); }
    
    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(15))
        .build().map_err(|e| format!("HTTP error: {}", e))?;
        
    let mut last_error = String::new();
    let mut stats = Vec::new();
    
    for (i, key) in keys.iter().enumerate() {
        let resp = match client.get("https://api.tavily.com/usage")
            .header("Authorization", format!("Bearer {}", key))
            .send().await {
                Ok(r) => r,
                Err(e) => { last_error = format!("Tavily request failed: {}", e); continue; }
            };
            
        if !resp.status().is_success() {
            let status = resp.status();
            let body = resp.text().await.unwrap_or_default();
            last_error = format!("Tavily error ({}): {}", status, body);
            continue;
        }
        
        let json: serde_json::Value = match resp.json().await {
            Ok(v) => v,
            Err(e) => { last_error = format!("Parse error: {}", e); continue; }
        };
        
        let usage = json.get("account")
            .and_then(|a| a.get("plan_usage"))
            .or_else(|| json.get("plan_usage"))
            .and_then(|val| val.as_i64())
            .unwrap_or(0);
            
        let limit = json.get("account")
            .and_then(|a| a.get("plan_limit"))
            .or_else(|| json.get("plan_limit"))
            .and_then(|val| val.as_i64())
            .unwrap_or(0);
            
        let remain = limit - usage;
        stats.push(format!("Key {}: {}/{} (เหลือ {})", i+1, usage, limit, remain));
    }
    
    if stats.is_empty() {
        return Err(last_error);
    }
    
    Ok(format!("{}", stats.join(", ")))
}

pub async fn ask_ai(api_key: &str, model: &str, question: &str) -> Result<String, String> {
    let prompt = format!("You are an AI assistant for EA-24 trading system. Always respond in Thai language, keep it concise.\nQuestion: {}", question);
    call_ai(api_key, model, &prompt, 0.7, 800, false).await
}

pub fn available_models() -> Vec<(&'static str, &'static str)> {
    vec![
        ("gemini-2.5-flash", "Gemini 2.5 Flash (เสถียร — ฟรี)"),
        ("gemini-3-flash-preview", "Gemini 3 Flash (ใหม่ล่าสุด)"),
        ("gemini-3.1-flash-lite-preview", "Gemini 3.1 Flash Lite (เร็วมาก)"),
        ("gemma-3-4b-it", "Gemma 3 4B (โมเดลเปิด)"),
        ("ollama:gemma4:e4b", "🏠 Gemma 4 E4B (Local — Ollama)"),
    ]
}

// ──────────────────────────────────────────────
//  AI Order Manager: Manage existing positions
// ──────────────────────────────────────────────

#[derive(Debug, Clone, Serialize)]
pub struct OrderManageResult {
    pub action: String,        // "HOLD", "BREAK_EVEN", "TRAIL", "PARTIAL_CLOSE", "CLOSE"
    pub new_sl: Option<f64>,
    pub trail_distance: Option<f64>,
    pub close_percent: Option<f64>,  // 50.0 for half, 100.0 for full
    pub reasoning: String,
    pub confidence: f64,
}

pub async fn run_ai_order_manager(
    gemini_key: &str,
    model: &str,
    symbol: &str,
    position: &serde_json::Value,
    candles: &[crate::strategy::Candle],
    balance: f64,
    log_tx: &tokio::sync::broadcast::Sender<String>,
) -> OrderManageResult {
    let ticket = position["ticket"].as_i64().unwrap_or(0);
    let direction = position["type"].as_str().unwrap_or("BUY");
    let entry_price = position["open_price"].as_f64().unwrap_or(0.0);
    let current_price = position["current_price"].as_f64().unwrap_or(0.0);
    let pnl = position["pnl"].as_f64().unwrap_or(0.0);
    let lot = position["lot"].as_f64()
        .or_else(|| position["volume"].as_f64())
        .unwrap_or(0.01);
    let current_sl = position["sl"].as_f64().unwrap_or(0.0);
    let current_tp = position["tp"].as_f64().unwrap_or(0.0);

    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": symbol, "agent": "order_manager", "status": "running",
        "message": format!("🛡️ AI ดูแลออเดอร์ {} #{} ({} {:.2} lot, P&L: {:.2}$)", symbol, ticket, direction, lot, pnl)
    }).to_string());

    // Build candle summary for AI context
    let candle_summary = if candles.len() >= 5 {
        let recent = &candles[candles.len()-5..];
        let high = recent.iter().map(|c| c.high).fold(f64::NEG_INFINITY, f64::max);
        let low = recent.iter().map(|c| c.low).fold(f64::INFINITY, f64::min);
        let trend = if recent.last().unwrap().close > recent.first().unwrap().close { "UPTREND" } else { "DOWNTREND" };
        format!("Last 5 candles: High={:.5}, Low={:.5}, Trend={}", high, low, trend)
    } else {
        "No candle data available".to_string()
    };

    let pnl_pct = if balance > 0.0 { (pnl / balance) * 100.0 } else { 0.0 };
    let pips_from_entry = if direction == "BUY" { 
        current_price - entry_price 
    } else { 
        entry_price - current_price 
    };

    let prompt = format!(
r#"You are an AI trade manager. You are managing an EXISTING open position. Analyze and decide what to do.

## Current Position
- Symbol: {symbol}
- Direction: {direction}
- Entry Price: {entry_price:.5}
- Current Price: {current_price:.5}
- P&L: ${pnl:.2} ({pnl_pct:.2}% of balance)
- Lot Size: {lot:.2}
- Current SL: {current_sl:.5}
- Current TP: {current_tp:.5}
- Pips from entry: {pips:.1}

## Market Context
{candle_summary}

## Rules
1. HOLD — ถ้ายังไม่ถึงจุดที่ต้องทำอะไร คงสถานะเดิม
2. BREAK_EVEN — ถ้ากำไร ≥ 15 pips → เลื่อน SL มาที่ entry price
3. TRAIL — ถ้ากำไรดี → เลื่อน SL ตามราคา (ระบุ new_sl)
4. PARTIAL_CLOSE — ถ้ากำไร ≥ 30 pips → ปิด 50% ล็อคกำไรบางส่วน
5. CLOSE — ถ้าตลาดกลับทิศแรง หรือถึงเป้าหมายแล้ว → ปิดทั้งหมด

## Response Format (MUST follow exactly)
ACTION: [HOLD/BREAK_EVEN/TRAIL/PARTIAL_CLOSE/CLOSE]
NEW_SL: [price or 0]
CONFIDENCE: [0-100]
REASONING: [brief Thai explanation]"#,
        pips = pips_from_entry * 10000.0 // approximate pips
    );

    match call_ai(gemini_key, model, &prompt, 0.2, 300, false).await {
        Ok(response) => {
            let _ = log_tx.send(serde_json::json!({
                "type": "agent_log_verbose", "symbol": symbol, "agent": "order_manager",
                "prompt": prompt, "response": response
            }).to_string());

            let mut action = "HOLD".to_string();
            let mut new_sl = None;
            let mut confidence = 50.0;
            let mut reasoning = String::new();

            for line in response.lines() {
                let l = line.trim();
                if l.starts_with("ACTION:") {
                    let v = l.replace("ACTION:", "").trim().to_uppercase();
                    if v.contains("BREAK_EVEN") { action = "BREAK_EVEN".into(); }
                    else if v.contains("TRAIL") { action = "TRAIL".into(); }
                    else if v.contains("PARTIAL_CLOSE") { action = "PARTIAL_CLOSE".into(); }
                    else if v.contains("CLOSE") && !v.contains("PARTIAL") { action = "CLOSE".into(); }
                }
                if l.starts_with("NEW_SL:") {
                    let v: String = l.replace("NEW_SL:", "").trim().chars()
                        .filter(|c| c.is_ascii_digit() || *c == '.').collect();
                    let sl_val = v.parse::<f64>().unwrap_or(0.0);
                    if sl_val > 0.0 { new_sl = Some(sl_val); }
                }
                if l.starts_with("CONFIDENCE:") {
                    let v: String = l.replace("CONFIDENCE:", "").trim().chars()
                        .filter(|c| c.is_ascii_digit() || *c == '.').collect();
                    confidence = v.parse().unwrap_or(50.0);
                }
                if l.starts_with("REASONING:") {
                    reasoning = l.replace("REASONING:", "").trim().to_string();
                }
            }
            if reasoning.is_empty() { reasoning = response.chars().take(200).collect(); }

            // For BREAK_EVEN, auto-set SL to entry price
            if action == "BREAK_EVEN" && new_sl.is_none() {
                new_sl = Some(entry_price);
            }

            let action_emoji = match action.as_str() {
                "HOLD" => "⏸️",
                "BREAK_EVEN" => "🔒",
                "TRAIL" => "📈",
                "PARTIAL_CLOSE" => "✂️",
                "CLOSE" => "🔴",
                _ => "❓",
            };

            let _ = log_tx.send(serde_json::json!({
                "type": "agent_log", "symbol": symbol, "agent": "order_manager", "status": "done",
                "message": format!("{} ตัดสินใจ: {} (conf: {:.0}%) — {}", action_emoji, action, confidence, reasoning)
            }).to_string());

            let close_pct = match action.as_str() {
                "PARTIAL_CLOSE" => Some(50.0),
                "CLOSE" => Some(100.0),
                _ => None,
            };

            OrderManageResult {
                action,
                new_sl,
                trail_distance: None,
                close_percent: close_pct,
                reasoning,
                confidence,
            }
        }
        Err(e) => {
            let msg = format!("❌ AI Order Manager error: {}", e);
            let _ = log_tx.send(serde_json::json!({
                "type": "agent_log", "symbol": symbol, "agent": "order_manager", "status": "error",
                "message": &msg
            }).to_string());
            OrderManageResult {
                action: "HOLD".to_string(),
                new_sl: None,
                trail_distance: None,
                close_percent: None,
                reasoning: msg,
                confidence: 0.0,
            }
        }
    }
}

// ──────────────────────────────────────────────
//  Feature 1: AI Recovery & Hedging Manager
//  Handles losing positions with HEDGE/AVG/CUT
// ──────────────────────────────────────────────

#[derive(Debug, Clone, Serialize)]
pub struct RecoveryResult {
    pub action: String,        // "HOLD", "HEDGE", "AVG_DOWN", "CUT"
    pub hedge_lot: Option<f64>,
    pub avg_lot: Option<f64>,
    pub reasoning: String,
    pub confidence: f64,
}

pub async fn run_ai_recovery_manager(
    gemini_key: &str,
    model: &str,
    symbol: &str,
    position: &serde_json::Value,
    candles: &[crate::strategy::Candle],
    balance: f64,
    recovery_threshold: f64,  // e.g. 3.0 means -3%
    log_tx: &tokio::sync::broadcast::Sender<String>,
) -> RecoveryResult {
    let ticket = position["ticket"].as_i64().unwrap_or(0);
    let direction = position["type"].as_str().unwrap_or("BUY");
    let entry_price = position["open_price"].as_f64().unwrap_or(0.0);
    let current_price = position["current_price"].as_f64().unwrap_or(0.0);
    let pnl = position["pnl"].as_f64().unwrap_or(0.0);
    let lot = position["lot"].as_f64()
        .or_else(|| position["volume"].as_f64())
        .unwrap_or(0.01);
    let current_sl = position["sl"].as_f64().unwrap_or(0.0);

    let pnl_pct = if balance > 0.0 { (pnl / balance) * 100.0 } else { 0.0 };

    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": symbol, "agent": "recovery_manager", "status": "running",
        "message": format!("🚨 AI Recovery: {} #{} ขาดทุน {:.2}% (${:.2})", symbol, ticket, pnl_pct, pnl)
    }).to_string());

    let candle_summary = if candles.len() >= 5 {
        let recent = &candles[candles.len()-5..];
        let high = recent.iter().map(|c| c.high).fold(f64::NEG_INFINITY, f64::max);
        let low = recent.iter().map(|c| c.low).fold(f64::INFINITY, f64::min);
        let trend = if recent.last().unwrap().close > recent.first().unwrap().close { "REVERSAL_UP" } else { "CONTINUING_DOWN" };
        format!("Last 5 candles: High={:.5}, Low={:.5}, Trend={}", high, low, trend)
    } else {
        "No data".to_string()
    };

    let prompt = format!(
r#"You are a crisis management AI for trading. A position is losing badly and needs intervention.

## Losing Position
- Symbol: {symbol}
- Direction: {direction}
- Entry: {entry_price:.5}
- Current: {current_price:.5}
- P&L: ${pnl:.2} ({pnl_pct:.2}% of ${balance:.0})
- Lot: {lot:.2}
- SL: {current_sl:.5}
- Recovery Threshold: -{recovery_threshold:.1}%

## Market Context
{candle_summary}

## Recovery Options
1. HOLD — ถ้าเห็นว่ากลับทิศมาได้ ยังไม่ถึงจุด panic
2. HEDGE — เปิดสวนทิศทาง (50% ของ lot) เพื่อล็อคขาดทุน → ระบุ hedge_lot
3. AVG_DOWN — ถัวเฉลี่ย (เปิดตามทิศเดิมอีก 50% lot) → ระบุ avg_lot
4. CUT — ปิดตัดขาดทุนทันที ถ้าสถานการณ์แย่มาก

## Response Format
ACTION: [HOLD/HEDGE/AVG_DOWN/CUT]
LOT: [lot size for hedge/avg or 0]
CONFIDENCE: [0-100]
REASONING: [brief Thai explanation]"#);

    match call_ai(gemini_key, model, &prompt, 0.2, 300, false).await {
        Ok(response) => {
            let mut action = "HOLD".to_string();
            let mut extra_lot = None;
            let mut confidence = 50.0;
            let mut reasoning = String::new();

            for line in response.lines() {
                let l = line.trim();
                if l.starts_with("ACTION:") {
                    let v = l.replace("ACTION:", "").trim().to_uppercase();
                    if v.contains("HEDGE") { action = "HEDGE".into(); }
                    else if v.contains("AVG") { action = "AVG_DOWN".into(); }
                    else if v.contains("CUT") { action = "CUT".into(); }
                }
                if l.starts_with("LOT:") {
                    let v: String = l.replace("LOT:", "").trim().chars()
                        .filter(|c| c.is_ascii_digit() || *c == '.').collect();
                    let lv = v.parse::<f64>().unwrap_or(0.0);
                    if lv > 0.0 { extra_lot = Some(lv); }
                }
                if l.starts_with("CONFIDENCE:") {
                    let v: String = l.replace("CONFIDENCE:", "").trim().chars()
                        .filter(|c| c.is_ascii_digit() || *c == '.').collect();
                    confidence = v.parse().unwrap_or(50.0);
                }
                if l.starts_with("REASONING:") {
                    reasoning = l.replace("REASONING:", "").trim().to_string();
                }
            }
            if reasoning.is_empty() { reasoning = response.chars().take(200).collect(); }

            // Default lot for hedge/avg if AI didn't specify
            if extra_lot.is_none() && (action == "HEDGE" || action == "AVG_DOWN") {
                extra_lot = Some((lot * 0.5 * 100.0).round() / 100.0); // 50% of original, rounded to 2dp
            }

            let emoji = match action.as_str() {
                "HOLD" => "⏸️", "HEDGE" => "🔀", "AVG_DOWN" => "📉", "CUT" => "✂️", _ => "❓"
            };
            let _ = log_tx.send(serde_json::json!({
                "type": "agent_log", "symbol": symbol, "agent": "recovery_manager", "status": "done",
                "message": format!("{} Recovery: {} (conf: {:.0}%) — {}", emoji, action, confidence, reasoning)
            }).to_string());

            RecoveryResult {
                action,
                hedge_lot: if extra_lot.is_some() { extra_lot } else { None },
                avg_lot: extra_lot,
                reasoning,
                confidence,
            }
        }
        Err(e) => {
            let msg = format!("❌ Recovery Manager error: {}", e);
            let _ = log_tx.send(serde_json::json!({
                "type": "agent_log", "symbol": symbol, "agent": "recovery_manager", "status": "error",
                "message": &msg
            }).to_string());
            RecoveryResult { action: "HOLD".into(), hedge_lot: None, avg_lot: None, reasoning: msg, confidence: 0.0 }
        }
    }
}

// ──────────────────────────────────────────────
//  Feature 2: Pre-emptive News Avoidance
//  Check if high-impact news is coming soon
// ──────────────────────────────────────────────

#[derive(Debug, Clone, Serialize)]
pub struct NewsAvoidanceResult {
    pub should_avoid: bool,
    pub minutes_until: i64,
    pub event_title: String,
    pub event_country: String,
}

pub async fn check_upcoming_high_impact_news(
    log_tx: &tokio::sync::broadcast::Sender<String>,
) -> Vec<NewsAvoidanceResult> {
    let client = match reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(10))
        .build() {
        Ok(c) => c,
        Err(_) => return vec![],
    };

    let resp = match client.get(FOREX_CALENDAR_URL).send().await {
        Ok(r) => r,
        Err(e) => {
            warn!("📅 News avoidance: fetch failed: {}", e);
            return vec![];
        }
    };

    let events: Vec<ForexCalendarEvent> = match resp.json().await {
        Ok(e) => e,
        Err(_) => return vec![],
    };

    let now = chrono::Utc::now();
    let mut warnings = vec![];

    for event in &events {
        // Only high impact
        let is_high = event.impact.as_ref().map(|i| i == "High").unwrap_or(false);
        if !is_high { continue; }

        // Parse event time
        let event_time = event.date.as_ref().and_then(|d| {
            chrono::NaiveDateTime::parse_from_str(d, "%Y-%m-%dT%H:%M:%S%z")
                .or_else(|_| chrono::NaiveDateTime::parse_from_str(d, "%Y-%m-%dT%H:%M:%S"))
                .ok()
                .map(|dt| dt.and_utc())
        });

        if let Some(event_dt) = event_time {
            let diff_minutes = (event_dt - now).num_minutes();
            // Warning: 0 to 30 minutes from now
            if diff_minutes >= 0 && diff_minutes <= 30 {
                let title = event.title.clone().unwrap_or("Unknown".into());
                let country = event.country.clone().unwrap_or("?".into());
                warnings.push(NewsAvoidanceResult {
                    should_avoid: true,
                    minutes_until: diff_minutes,
                    event_title: title.clone(),
                    event_country: country.clone(),
                });
                info!("📅 [News Avoidance] ⚠️ {} ({}) in {} minutes!", title, country, diff_minutes);
            }
        }
    }

    if !warnings.is_empty() {
        let titles: Vec<String> = warnings.iter().map(|w| format!("{} ({})", w.event_title, w.event_country)).collect();
        let _ = log_tx.send(serde_json::json!({
            "type": "news_avoidance",
            "events": titles,
            "message": format!("⚠️ ข่าวสำคัญ {} รายการ ใน 30 นาที: {}", warnings.len(), titles.join(", "))
        }).to_string());
    }

    warnings
}

// ──────────────────────────────────────────────
//  Feature 3: Weekly AI Trade Journal & Reviewer
// ──────────────────────────────────────────────

#[derive(Debug, Clone, Serialize)]
pub struct WeeklyReview {
    pub total_trades: usize,
    pub win_count: usize,
    pub loss_count: usize,
    pub total_profit: f64,
    pub win_rate: f64,
    pub best_trade: f64,
    pub worst_trade: f64,
    pub ai_analysis: String,
    pub recommendations: String,
}

pub async fn run_weekly_journal(
    gemini_key: &str,
    model: &str,
    trades: &[serde_json::Value],
    log_tx: &tokio::sync::broadcast::Sender<String>,
) -> WeeklyReview {
    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": "ALL", "agent": "weekly_journal", "status": "running",
        "message": "📓 กำลังสร้างรายงานสรุปสัปดาห์..."
    }).to_string());

    let mut total_profit = 0.0;
    let mut win_count = 0usize;
    let mut loss_count = 0usize;
    let mut best_trade = f64::NEG_INFINITY;
    let mut worst_trade = f64::INFINITY;
    let mut trade_details = Vec::new();

    for t in trades {
        let profit = t["profit"].as_f64().unwrap_or(0.0);
        let swap = t["swap"].as_f64().unwrap_or(0.0);
        let comm = t["commission"].as_f64().unwrap_or(0.0);
        let net = profit + swap + comm;
        let symbol = t["symbol"].as_str().unwrap_or("?");
        let deal_type = t["type"].as_str().unwrap_or("?");
        let volume = t["volume"].as_f64().unwrap_or(0.0);

        // Skip balance/deposit type deals
        if deal_type == "DEAL_TYPE_BALANCE" || deal_type == "balance" || symbol.is_empty() { continue; }

        total_profit += net;
        if net >= 0.0 { win_count += 1; } else { loss_count += 1; }
        if net > best_trade { best_trade = net; }
        if net < worst_trade { worst_trade = net; }
        trade_details.push(format!("{} {} {:.2}lot → ${:.2}", symbol, deal_type, volume, net));
    }

    let total_trades = win_count + loss_count;
    let win_rate = if total_trades > 0 { (win_count as f64 / total_trades as f64) * 100.0 } else { 0.0 };
    if best_trade == f64::NEG_INFINITY { best_trade = 0.0; }
    if worst_trade == f64::INFINITY { worst_trade = 0.0; }

    // Build summary for AI
    let trade_list = if trade_details.len() > 20 {
        trade_details[..20].join("\n")
    } else {
        trade_details.join("\n")
    };

    let prompt = format!(
r#"You are a professional fund manager reviewing the past week's trading performance.
Always respond in Thai language.

## Weekly Performance Summary
- Total Trades: {total_trades}
- Win/Loss: {win_count}/{loss_count}
- Win Rate: {win_rate:.1}%
- Total P&L: ${total_profit:.2}
- Best Trade: ${best_trade:.2}
- Worst Trade: ${worst_trade:.2}

## Trade Details
{trade_list}

## Instructions
1. วิเคราะห์ผลงานสัปดาห์นี้ — อะไรดี อะไรพลาด
2. ระบุรูปแบบ (pattern) ที่เห็น เช่น ชนะบ่อยใน symbol ไหน แพ้บ่อยช่วงไหน
3. แนะนำการปรับปรุงสำหรับสัปดาห์หน้า (ควรเพิ่ม/ลด confidence threshold? เปลี่ยน lot size?)

Respond:
ANALYSIS: [สรุปวิเคราะห์]
RECOMMENDATIONS: [แนะนำปรับปรุง]"#);

    let (ai_analysis, recommendations) = if !gemini_key.is_empty() && total_trades > 0 {
        match call_ai(gemini_key, model, &prompt, 0.5, 800, false).await {
            Ok(response) => {
                let mut analysis = String::new();
                let mut recs = String::new();
                let mut current_section = "";
                for line in response.lines() {
                    let l = line.trim();
                    if l.starts_with("ANALYSIS:") {
                        current_section = "analysis";
                        analysis = l.replace("ANALYSIS:", "").trim().to_string();
                    } else if l.starts_with("RECOMMENDATIONS:") {
                        current_section = "recs";
                        recs = l.replace("RECOMMENDATIONS:", "").trim().to_string();
                    } else if !l.is_empty() {
                        match current_section {
                            "analysis" => { analysis.push(' '); analysis.push_str(l); }
                            "recs" => { recs.push(' '); recs.push_str(l); }
                            _ => {}
                        }
                    }
                }
                if analysis.is_empty() { analysis = response.chars().take(400).collect(); }
                (analysis, recs)
            }
            Err(e) => (format!("AI Error: {}", e), String::new()),
        }
    } else {
        ("ไม่มีเทรดในสัปดาห์นี้".to_string(), String::new())
    };

    let _ = log_tx.send(serde_json::json!({
        "type": "agent_log", "symbol": "ALL", "agent": "weekly_journal", "status": "done",
        "message": format!("📓 สรุป: {} trades, WR {:.0}%, P&L ${:.2}", total_trades, win_rate, total_profit)
    }).to_string());

    WeeklyReview {
        total_trades, win_count, loss_count,
        total_profit, win_rate, best_trade, worst_trade,
        ai_analysis, recommendations,
    }
}

// ──────────────────────────────────────────────
//  Feature 4: Multi-Asset Correlation Agent
//  Detect over-exposure across currency pairs
// ──────────────────────────────────────────────

#[derive(Debug, Clone, Serialize)]
pub struct CorrelationResult {
    pub currency_exposure: std::collections::HashMap<String, f64>,
    pub warnings: Vec<String>,
    pub max_exposure_currency: String,
    pub max_exposure_value: f64,
    pub should_reduce: bool,
}

pub fn run_correlation_check(
    pending_decisions: &[(String, String, f64)], // (symbol, direction, lot)
    existing_positions: &[serde_json::Value],
    log_tx: &tokio::sync::broadcast::Sender<String>,
) -> CorrelationResult {
    let mut exposure: std::collections::HashMap<String, f64> = std::collections::HashMap::new();

    // Helper: extract currencies from symbol
    let extract_currencies = |sym: &str| -> (String, String) {
        let s = sym.to_uppercase().replace(".", "");
        if s.len() >= 6 {
            (s[..3].to_string(), s[3..6].to_string())
        } else {
            // Handle XAU, BTC etc
            if s.contains("XAU") || s.contains("GOLD") { return ("XAU".into(), "USD".into()); }
            if s.contains("BTC") { return ("BTC".into(), "USD".into()); }
            if s.contains("ETH") { return ("ETH".into(), "USD".into()); }
            (s.clone(), "USD".into())
        }
    };

    // Process existing positions
    for pos in existing_positions {
        let sym = pos["symbol"].as_str().unwrap_or("");
        let dir = pos["type"].as_str().unwrap_or("BUY");
        let lot = pos["lot"].as_f64()
            .or_else(|| pos["volume"].as_f64())
            .unwrap_or(0.01);

        let (base, quote) = extract_currencies(sym);
        if dir == "BUY" {
            *exposure.entry(base.clone()).or_insert(0.0) += lot;
            *exposure.entry(quote.clone()).or_insert(0.0) -= lot;
        } else {
            *exposure.entry(base.clone()).or_insert(0.0) -= lot;
            *exposure.entry(quote.clone()).or_insert(0.0) += lot;
        }
    }

    // Process pending decisions
    for (sym, dir, lot) in pending_decisions {
        let (base, quote) = extract_currencies(sym);
        if dir == "BUY" {
            *exposure.entry(base.clone()).or_insert(0.0) += lot;
            *exposure.entry(quote.clone()).or_insert(0.0) -= lot;
        } else {
            *exposure.entry(base.clone()).or_insert(0.0) -= lot;
            *exposure.entry(quote.clone()).or_insert(0.0) += lot;
        }
    }

    // Check for over-exposure (> 2x in any currency)
    let mut warnings = Vec::new();
    let mut max_currency = String::new();
    let mut max_exposure = 0.0f64;

    for (currency, exp) in &exposure {
        let abs_exp = exp.abs();
        if abs_exp > max_exposure {
            max_exposure = abs_exp;
            max_currency = currency.clone();
        }
        if abs_exp > 0.02 { // More than 0.02 lot exposure in single currency
            let direction = if *exp > 0.0 { "Long" } else { "Short" };
            warnings.push(format!("⚠️ {} {} {:.2} lot — Over-exposure!", currency, direction, abs_exp));
        }
    }

    let should_reduce = !warnings.is_empty();

    if !warnings.is_empty() {
        let _ = log_tx.send(serde_json::json!({
            "type": "correlation_warning",
            "warnings": warnings,
            "exposure": exposure,
            "message": format!("🔗 Correlation Alert: {} warnings detected", warnings.len())
        }).to_string());
    } else {
        let _ = log_tx.send(serde_json::json!({
            "type": "agent_log", "symbol": "ALL", "agent": "correlation", "status": "done",
            "message": "🔗 ✅ ไม่มี Over-exposure — สมดุลดี"
        }).to_string());
    }

    CorrelationResult {
        currency_exposure: exposure,
        warnings,
        max_exposure_currency: max_currency,
        max_exposure_value: max_exposure,
        should_reduce,
    }
}
