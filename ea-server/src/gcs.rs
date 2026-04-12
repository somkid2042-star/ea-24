// ──────────────────────────────────────────────
//  gcs.rs — Google Cloud Storage via Service Account
//  Uses raw HTTP with JWT (no heavy google-cloud crate)
// ──────────────────────────────────────────────

use base64::{Engine as _, engine::general_purpose};
use log::{error, info};
use serde::{Deserialize, Serialize};
use std::time::{SystemTime, UNIX_EPOCH};

// ──────────────────────────────────────────────
//  Public Result Type
// ──────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GcsUploadResult {
    pub file_name: String,
    pub gcs_link: String,
    pub size_bytes: u64,
}

// ──────────────────────────────────────────────
//  Service Account JSON Structure
// ──────────────────────────────────────────────

#[derive(Debug, Deserialize, Clone)]
pub struct ServiceAccountKey {
    pub private_key: String,
    pub client_email: String,
    pub project_id: Option<String>,
}

// ──────────────────────────────────────────────
//  JWT Creation (RS256)
// ──────────────────────────────────────────────

fn build_jwt(sa: &ServiceAccountKey, scope: &str) -> Result<String, String> {
    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_secs();

    let header = serde_json::json!({
        "alg": "RS256",
        "typ": "JWT"
    });

    let claims = serde_json::json!({
        "iss": sa.client_email,
        "scope": scope,
        "aud": "https://oauth2.googleapis.com/token",
        "exp": now + 3600,
        "iat": now,
    });

    let header_b64 = general_purpose::URL_SAFE_NO_PAD.encode(header.to_string());
    let claims_b64 = general_purpose::URL_SAFE_NO_PAD.encode(claims.to_string());
    let signing_input = format!("{}.{}", header_b64, claims_b64);

    let signature = sign_rsa(&sa.private_key, signing_input.as_bytes())?;
    let sig_b64 = general_purpose::URL_SAFE_NO_PAD.encode(&signature);

    Ok(format!("{}.{}", signing_input, sig_b64))
}

fn sign_rsa(pem_key: &str, data: &[u8]) -> Result<Vec<u8>, String> {
    let pem = pem_key.trim();
    let der_b64: String = pem
        .lines()
        .filter(|l| !l.starts_with("-----"))
        .collect::<Vec<_>>()
        .join("");
    
    let der = general_purpose::STANDARD
        .decode(&der_b64)
        .map_err(|e| format!("Failed to decode private key PEM: {}", e))?;

    use rsa::{pkcs8::DecodePrivateKey, RsaPrivateKey};
    use rsa::pkcs1v15::SigningKey;
    use rsa::signature::{SignatureEncoding, Signer};
    use sha2::Sha256;

    let private_key = RsaPrivateKey::from_pkcs8_der(&der)
        .map_err(|e| format!("Failed to parse RSA private key: {}", e))?;

    let signing_key = SigningKey::<Sha256>::new(private_key);
    let sig = signing_key.sign(data);
    Ok(sig.to_vec())
}

// ──────────────────────────────────────────────
//  Get OAuth2 Access Token
// ──────────────────────────────────────────────

async fn get_access_token(sa: &ServiceAccountKey) -> Result<String, String> {
    let scope = "https://www.googleapis.com/auth/devstorage.read_write";
    let jwt = build_jwt(sa, scope)?;

    let client = reqwest::Client::new();
    let resp = client
        .post("https://oauth2.googleapis.com/token")
        .form(&[
            ("grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer"),
            ("assertion", &jwt),
        ])
        .send()
        .await
        .map_err(|e| format!("Token request failed: {}", e))?;

    let body: serde_json::Value = resp
        .json()
        .await
        .map_err(|e| format!("Token response parse failed: {}", e))?;

    if let Some(token) = body["access_token"].as_str() {
        Ok(token.to_string())
    } else {
        Err(format!("No access_token in response: {}", body))
    }
}

// ──────────────────────────────────────────────
//  Download Video from URL → Temp File (Identical to before)
// ──────────────────────────────────────────────

pub async fn download_video(
    url: &str,
    progress_tx: Option<tokio::sync::broadcast::Sender<String>>,
    job_id: &str,
) -> Result<(tempfile::NamedTempFile, String), String> {
    use tokio::io::AsyncWriteExt;

    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(600))
        .redirect(reqwest::redirect::Policy::limited(10))
        .user_agent("Mozilla/5.0 EA24-Server/9.1")
        .build()
        .map_err(|e| format!("HTTP client build failed: {}", e))?;

    let mut target_url = url.to_string();

    // -- Telegram Link Interceptor --
    if target_url.contains("t.me/") {
        let embed_url = if target_url.contains("?embed=1") { target_url.clone() } else { format!("{}?embed=1", target_url) };
        info!("Extracting Telegram video from: {}", embed_url);
        
        let html_resp = client.get(&embed_url).send().await.map_err(|e| format!("Telegram HTML fetch failed: {}", e))?;
        if html_resp.status().is_success() {
            let html_text = html_resp.text().await.unwrap_or_default();
            if let Some(video_tag) = html_text.split("<video").nth(1) {
                if let Some(src_part) = video_tag.split("src=\"").nth(1) {
                    if let Some(raw_url) = src_part.split("\"").next() {
                        target_url = raw_url.replace("&amp;", "&");
                        info!("Found raw Telegram video stream: {}", target_url);
                    }
                }
            } else {
                return Err("Could not find video in Telegram link. Ensure the post is public and contains a video.".to_string());
            }
        }
    }

    let resp = client
        .get(&target_url)
        .send()
        .await
        .map_err(|e| format!("Download request failed: {}", e))?;

    if !resp.status().is_success() {
        return Err(format!("Download failed with status: {}", resp.status()));
    }

    let file_name = {
        let cd = resp
            .headers()
            .get("content-disposition")
            .and_then(|v| v.to_str().ok())
            .and_then(|s| {
                s.split(';')
                    .find(|p| p.trim().starts_with("filename="))
                    .map(|p| p.trim().trim_start_matches("filename=").trim_matches('"').to_string())
            });

        if let Some(name) = cd {
            name
        } else {
            let url_path = url.split('?').next().unwrap_or(url);
            let base = url_path.split('/').last().unwrap_or("video");
            if base.contains('.') {
                base.to_string()
            } else {
                format!("{}.mp4", base)
            }
        }
    };

    let total_size = resp.content_length().unwrap_or(0);

    let mut tmp = tempfile::NamedTempFile::new()
        .map_err(|e| format!("Failed to create temp file: {}", e))?;
    let tmp_path = tmp.path().to_path_buf();
    let mut file = tokio::fs::File::create(&tmp_path)
        .await
        .map_err(|e| format!("Failed to open temp writing: {}", e))?;

    let mut downloaded: u64 = 0;
    let mut stream = resp.bytes_stream();
    use futures_util::StreamExt;

    while let Some(chunk) = stream.next().await {
        let chunk = chunk.map_err(|e| format!("Download stream error: {}", e))?;
        file.write_all(&chunk).await.map_err(|e| format!("Write error: {}", e))?;
        downloaded += chunk.len() as u64;

        if let Some(tx) = &progress_tx {
            let pct = if total_size > 0 {
                (downloaded as f64 / total_size as f64 * 50.0) as u32
            } else {
                0
            };
            let msg = serde_json::json!({
                "type": "upload_video_progress",
                "job_id": job_id,
                "stage": "downloading",
                "progress": pct,
                "downloaded_bytes": downloaded,
                "total_bytes": total_size
            })
            .to_string();
            let _ = tx.send(msg);
        }
    }

    file.flush().await.map_err(|e| format!("Flush error: {}", e))?;
    drop(file);

    let tmp_file = tempfile::Builder::new()
        .suffix(&format!("_{}", file_name))
        .tempfile()
        .map_err(|e| format!("Tempfile error: {}", e))?;

    std::fs::copy(&tmp_path, tmp_file.path())
        .map_err(|e| format!("Copy file error: {}", e))?;

    info!("Downloaded '{}': {} bytes", file_name, downloaded);
    Ok((tmp_file, file_name))
}

// ──────────────────────────────────────────────
//  Upload to Google Cloud Storage
// ──────────────────────────────────────────────

pub async fn upload_to_gcs(
    file_bytes: Vec<u8>,
    file_name: &str,
    bucket_name: &str,
    sa: &ServiceAccountKey,
    progress_tx: Option<tokio::sync::broadcast::Sender<String>>,
    job_id: &str,
) -> Result<GcsUploadResult, String> {
    let token = get_access_token(sa).await?;

    let mime_type = mime_guess::from_path(file_name)
        .first_or_octet_stream()
        .to_string();

    let size_bytes = file_bytes.len() as u64;

    if let Some(tx) = &progress_tx {
        let msg = serde_json::json!({
            "type": "upload_video_progress",
            "job_id": job_id,
            "stage": "uploading",
            "progress": 55,
        })
        .to_string();
        let _ = tx.send(msg);
    }

    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(600))
        .build()
        .map_err(|e| format!("HTTP client error: {}", e))?;

    // Attempt upload. URL encode the file name just in case.
    let encoded_name = urlencoding::encode(file_name);
    let upload_url = format!(
        "https://storage.googleapis.com/upload/storage/v1/b/{}/o?uploadType=media&name={}",
        bucket_name, encoded_name
    );

    let resp = client
        .post(&upload_url)
        .bearer_auth(&token)
        .header("Content-Type", mime_type)
        .body(file_bytes)
        .send()
        .await
        .map_err(|e| format!("Upload request failed: {}", e))?;

    if !resp.status().is_success() {
        let status = resp.status();
        let body = resp.text().await.unwrap_or_default();
        return Err(format!("GCS Upload failed ({}): {}", status, body));
    }

    // Best effort try to make file public via ACL (won't work if Uniform Bucket Level Access is ON, but doesn't hurt)
    let acl_url = format!(
        "https://storage.googleapis.com/storage/v1/b/{}/o/{}/acl",
        bucket_name, encoded_name
    );
    let _ = client
        .post(&acl_url)
        .bearer_auth(&token)
        .json(&serde_json::json!({
            "entity": "allUsers",
            "role": "READER"
        }))
        .send()
        .await;

    let gcs_link = format!(
        "https://storage.googleapis.com/{}/{}",
        bucket_name, encoded_name
    );

    info!(
        "Uploaded '{}' to GCS Bucket '{}' ({} bytes)",
        file_name, bucket_name, size_bytes
    );

    Ok(GcsUploadResult {
        file_name: file_name.to_string(),
        gcs_link,
        size_bytes,
    })
}

// ──────────────────────────────────────────────
//  Full Pipeline: URL → Download → GCS Upload
// ──────────────────────────────────────────────

pub async fn upload_url_to_gcs(
    video_url: &str,
    bucket_name: &str,
    sa: &ServiceAccountKey,
    progress_tx: Option<tokio::sync::broadcast::Sender<String>>,
    job_id: &str,
) -> Result<GcsUploadResult, String> {
    info!("Starting upload pipeline: {} → GCS Bucket {}", video_url, bucket_name);

    let (tmp_file, file_name) =
        download_video(video_url, progress_tx.clone(), job_id).await?;

    let file_bytes =
        std::fs::read(tmp_file.path()).map_err(|e| format!("Failed to read temp file: {}", e))?;

    drop(tmp_file);

    let result = upload_to_gcs(
        file_bytes,
        &file_name,
        bucket_name,
        sa,
        progress_tx,
        job_id,
    )
    .await?;

    Ok(result)
}
