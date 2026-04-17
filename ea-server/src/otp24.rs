use log::info;
use serde_json::Value;
use std::time::Duration;
use chrono::Utc;
use base64::{Engine as _, engine::general_purpose::STANDARD};

use crate::db::Database;

const SECRET_KEY: &str = "OTP24HRHUB_PROTECT";
const API_BASE: &str = "https://otp24hr.com/api/v1/tools/api";
// Device fingerprint bound to license key DEMO-2840-3DA8-5345
const DEVICE_ID: &str = "T1RQfE1hY0ludGVsfDh8dW5kZWZpbmVkfDE5MjB4MTA4MHxBbWVyaWNhL05ld19Zb3JrfGVuLVVT";

fn xor_decode(encoded_str: &str, key: &str) -> Result<String, String> {
    let binary_data = STANDARD.decode(encoded_str).map_err(|e| e.to_string())?;
    let key_bytes = key.as_bytes();
    let mut decoded = Vec::with_capacity(binary_data.len());

    for (i, byte) in binary_data.iter().enumerate() {
        decoded.push(byte ^ key_bytes[i % key_bytes.len()]);
    }
    String::from_utf8(decoded).map_err(|e| e.to_string())
}

pub async fn fetch_and_cache_otp24(db: &Database) -> Result<String, String> {
    // 1. Check Cache first (if less than 24 hours old)
    if let Some((payload, updated_at)) = db.get_otp24_cookie().await {
        let diff = Utc::now().signed_duration_since(updated_at);
        if diff.num_hours() < 24 {
            info!("OTP24: Returning cached payload ({} hours old)", diff.num_hours());
            return Ok(payload);
        }
    }

    info!("OTP24: Cache expired or empty. Fetching from OTP24 servers...");

    // Try to get the license key from DB config, fallback to default
    let license_key = db.get_config("otp24_license_key").await
        .unwrap_or_else(|| "DEMO-2840-3DA8-5345".to_string());

    // ดึง device_id จาก DB config (ฝัง Lock ไว้ตลอด) fallback ใช้ค่าเริ่มต้น
    let device_id = db.get_config("otp24_device_id").await
        .unwrap_or_else(|| DEVICE_ID.to_string());

    let client = reqwest::Client::builder()
        .timeout(Duration::from_secs(15))
        .danger_accept_invalid_certs(true)
        .build()
        .map_err(|e| e.to_string())?;

    // Step 1: First call login_by_device to get CSRF token
    let login_device_url = format!("{}?action=login_by_device", API_BASE);
    let mut headers = reqwest::header::HeaderMap::new();
    headers.insert("User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36".parse().unwrap());
    headers.insert("x-device-id", device_id.parse().unwrap());

    let device_form = [("device_id", device_id.clone())];
    let device_res = client.post(&login_device_url)
        .headers(headers.clone())
        .form(&device_form)
        .send()
        .await
        .map_err(|e| format!("login_by_device request failed: {}", e))?;

    // Extract CSRF token from response headers
    let csrf_token = device_res.headers()
        .get("x-csrf-token")
        .and_then(|v| v.to_str().ok())
        .unwrap_or("")
        .to_string();

    // We don't care if login_by_device fails — we just need CSRF
    let _ = device_res.text().await;

    info!("OTP24: Got CSRF token: {}...", &csrf_token.chars().take(16).collect::<String>());

    // Step 2: Use action=login with the license key
    let login_url = format!("{}?action=login", API_BASE);

    headers.insert("x-csrf-token", csrf_token.parse().unwrap());
    headers.insert("x-license-key", license_key.parse().unwrap());

    let login_form = [("key", license_key.as_str())];

    let res = client.post(&login_url)
        .headers(headers.clone())
        .form(&login_form)
        .send()
        .await
        .map_err(|e| format!("login request failed: {}", e))?;

    // Get new CSRF from response if available
    let new_csrf = res.headers()
        .get("x-csrf-token")
        .and_then(|v| v.to_str().ok())
        .unwrap_or(&csrf_token)
        .to_string();

    let body_str = res.text().await.map_err(|e| e.to_string())?;
    let json: Value = serde_json::from_str(&body_str).map_err(|e| format!("JSON parse error: {} body: {}", e, &body_str[..100.min(body_str.len())]))?;

    if json["success"].as_bool() != Some(true) {
        let msg = json["message"].as_str().unwrap_or("Unknown error");
        return Err(format!("OTP24 login failed: {}", msg));
    }

    let payload_b64 = json["payload"].as_str().unwrap_or("");
    if payload_b64.is_empty() {
        return Err(format!("Login succeeded but no payload. Response: {}", body_str));
    }

    let decoded = xor_decode(payload_b64, SECRET_KEY)?;
    let parsed: Value = serde_json::from_str(&decoded).map_err(|e| format!("Decoded JSON parse error: {}", e))?;

    // Build response with apps list
    let apps = parsed.get("apps").cloned().unwrap_or(Value::Array(vec![]));
    let used_today = parsed["used_today"].as_i64().unwrap_or(0);
    let daily_limit = parsed["daily_limit"].as_i64().unwrap_or(5);
    let expiry_date = parsed["expiry_date"].as_str().unwrap_or("");
    let plan = parsed["plan"].as_str().unwrap_or("free");

    let result = serde_json::json!({
        "status": "success",
        "source": "otp24_live",
        "updated_at": Utc::now().to_rfc3339(),
        "license_key": license_key,
        "plan": plan,
        "used_today": used_today,
        "daily_limit": daily_limit,
        "expiry_date": expiry_date,
        "apps": apps,
        "csrf_token": new_csrf,
        "device_id": DEVICE_ID,
    });

    let result_str = result.to_string();

    // Save to Database Cache
    db.save_otp24_cookie(&result_str).await;
    info!("OTP24: Successfully fetched and cached {} apps.", 
        apps.as_array().map(|a| a.len()).unwrap_or(0));

    Ok(result_str)
}

/// Fetch nodes/servers for a specific app (CACHED 24h)
pub async fn get_nodes(db: &Database, app_id: i64) -> Result<String, String> {
    // Check cache first
    let cache_key = format!("nodes_{}", app_id);
    if let Some((payload, updated_at)) = db.get_otp24_cache(&cache_key).await {
        let diff = Utc::now().signed_duration_since(updated_at);
        if diff.num_hours() < 24 {
            info!("OTP24: Returning cached nodes for app_id={} ({} hours old)", app_id, diff.num_hours());
            return Ok(payload);
        }
    }

    info!("OTP24: Fetching fresh nodes for app_id={}", app_id);

    // We need a valid session (csrf + license_key) from the last login
    let cached = db.get_otp24_cookie().await;
    let (csrf_token, license_key) = if let Some((payload, _)) = cached {
        let parsed: Value = serde_json::from_str(&payload).unwrap_or_default();
        (
            parsed["csrf_token"].as_str().unwrap_or("").to_string(),
            parsed["license_key"].as_str().unwrap_or("DEMO-2840-3DA8-5345").to_string(),
        )
    } else {
        // Need to login first
        let _ = fetch_and_cache_otp24(db).await?;
        let cached2 = db.get_otp24_cookie().await;
        if let Some((payload, _)) = cached2 {
            let parsed: Value = serde_json::from_str(&payload).unwrap_or_default();
            (
                parsed["csrf_token"].as_str().unwrap_or("").to_string(),
                parsed["license_key"].as_str().unwrap_or("DEMO-2840-3DA8-5345").to_string(),
            )
        } else {
            return Err("No cached session. Login first.".to_string());
        }
    };

    // ดึง device_id จาก DB config (ค่าที่ Lock ไว้ตลอด)
    let device_id = db.get_config("otp24_device_id").await
        .unwrap_or_else(|| DEVICE_ID.to_string());

    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(15))
        .danger_accept_invalid_certs(true)
        .build()
        .map_err(|e| e.to_string())?;

    let url = format!("{}?action=get_nodes&app_id={}&key={}", API_BASE, app_id, license_key);
    let mut headers = reqwest::header::HeaderMap::new();
    headers.insert("User-Agent", "Mozilla/5.0".parse().unwrap());
    headers.insert("x-csrf-token", csrf_token.parse().unwrap());
    headers.insert("x-device-id", device_id.parse().unwrap());
    headers.insert("x-license-key", license_key.parse().unwrap());

    let res = client.get(&url)
        .headers(headers)
        .send()
        .await
        .map_err(|e| e.to_string())?;

    // Update CSRF
    let new_csrf = res.headers()
        .get("x-csrf-token")
        .and_then(|v| v.to_str().ok())
        .unwrap_or("")
        .to_string();

    let body = res.text().await.map_err(|e| e.to_string())?;
    let json: Value = serde_json::from_str(&body).map_err(|e| e.to_string())?;

    let payload_b64 = json["payload"].as_str().unwrap_or("");
    if payload_b64.is_empty() {
        return Err(format!("get_nodes failed: {}", body));
    }

    let decoded = xor_decode(payload_b64, SECRET_KEY)?;

    // Save to cache
    db.save_otp24_cache(&cache_key, &decoded).await;
    info!("OTP24: Cached nodes for app_id={}", app_id);

    // Update csrf_token in cached data
    if !new_csrf.is_empty() {
        if let Some((old_payload, _)) = db.get_otp24_cookie().await {
            if let Ok(mut parsed) = serde_json::from_str::<Value>(&old_payload) {
                parsed["csrf_token"] = Value::String(new_csrf);
                db.save_otp24_cookie(&parsed.to_string()).await;
            }
        }
    }

    Ok(decoded)
}

/// Fetch cookie for a specific node (CACHED 24h)
pub async fn get_cookie(db: &Database, node_id: &str) -> Result<String, String> {
    // Check cache first
    let cache_key = format!("cookie_{}", node_id);
    if let Some((payload, updated_at)) = db.get_otp24_cache(&cache_key).await {
        let diff = Utc::now().signed_duration_since(updated_at);
        if diff.num_hours() < 24 {
            info!("OTP24: Returning cached cookie for node_id={} ({} hours old)", node_id, diff.num_hours());
            return Ok(payload);
        }
    }

    info!("OTP24: Fetching fresh cookie for node_id={}", node_id);

    let cached = db.get_otp24_cookie().await;
    let (csrf_token, license_key) = if let Some((payload, _)) = cached {
        let parsed: Value = serde_json::from_str(&payload).unwrap_or_default();
        (
            parsed["csrf_token"].as_str().unwrap_or("").to_string(),
            parsed["license_key"].as_str().unwrap_or("DEMO-2840-3DA8-5345").to_string(),
        )
    } else {
        // Need to login first
        let _ = fetch_and_cache_otp24(db).await?;
        let cached2 = db.get_otp24_cookie().await;
        if let Some((payload, _)) = cached2 {
            let parsed: Value = serde_json::from_str(&payload).unwrap_or_default();
            (
                parsed["csrf_token"].as_str().unwrap_or("").to_string(),
                parsed["license_key"].as_str().unwrap_or("DEMO-2840-3DA8-5345").to_string(),
            )
        } else {
            return Err("No session. Fetch apps first.".to_string());
        }
    };

    // ดึง device_id จาก DB config (ค่าที่ Lock ไว้ตลอด)
    let device_id = db.get_config("otp24_device_id").await
        .unwrap_or_else(|| DEVICE_ID.to_string());

    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(15))
        .danger_accept_invalid_certs(true)
        .build()
        .map_err(|e| e.to_string())?;

    let url = format!("{}?action=get_cookie&node_id={}&key={}", API_BASE, node_id, license_key);
    let mut headers = reqwest::header::HeaderMap::new();
    headers.insert("User-Agent", "Mozilla/5.0".parse().unwrap());
    headers.insert("x-csrf-token", csrf_token.parse().unwrap());
    headers.insert("x-device-id", device_id.parse().unwrap());
    headers.insert("x-license-key", license_key.parse().unwrap());

    let res = client.get(&url)
        .headers(headers)
        .send()
        .await
        .map_err(|e| e.to_string())?;

    let new_csrf = res.headers()
        .get("x-csrf-token")
        .and_then(|v| v.to_str().ok())
        .unwrap_or("")
        .to_string();

    let body = res.text().await.map_err(|e| e.to_string())?;
    let json: Value = serde_json::from_str(&body).map_err(|e| e.to_string())?;

    if json["success"].as_bool() != Some(true) {
        let msg = json["message"].as_str().unwrap_or("Unknown error");
        return Err(format!("get_cookie failed: {}", msg));
    }

    let payload_b64 = json["payload"].as_str().unwrap_or("");
    if payload_b64.is_empty() {
        return Err("No cookie payload".to_string());
    }

    let decoded = xor_decode(payload_b64, SECRET_KEY)?;

    // Save to cache
    db.save_otp24_cache(&cache_key, &decoded).await;
    info!("OTP24: Cached cookie for node_id={}", node_id);

    // Update csrf_token
    if !new_csrf.is_empty() {
        if let Some((old_payload, _)) = db.get_otp24_cookie().await {
            if let Ok(mut parsed) = serde_json::from_str::<Value>(&old_payload) {
                parsed["csrf_token"] = Value::String(new_csrf);
                db.save_otp24_cookie(&parsed.to_string()).await;
            }
        }
    }

    Ok(decoded)
}
