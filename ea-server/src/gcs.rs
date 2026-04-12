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

    // -- Telegram Link Interceptor (Using Telethon Python Proxy for Private/Public) --
    if target_url.contains("t.me/") {
        info!("Delegating Telegram download to python Telethon proxy for: {}", target_url);

        if let Some(tx) = &progress_tx {
            let msg = serde_json::json!({
                "type": "upload_video_progress",
                "job_id": job_id,
                "stage": "downloading_telegram",
                "progress": 10,
            }).to_string();
            let _ = tx.send(msg);
        }

        use std::process::Stdio;
        use tokio::io::{AsyncBufReadExt, BufReader};

        let mut child = tokio::process::Command::new("python3")
            .arg("telegram_downloader.py")
            .arg(&target_url)
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn()
            .map_err(|e| format!("Failed to spawn python proxy: {}", e))?;

        let stdout = child.stdout.take().expect("Child did not have a handle to stdout");
        let stderr = child.stderr.take().expect("Child did not have a handle to stderr");

        let progress_tx_clone = progress_tx.clone();
        let job_id_clone = job_id.to_string();
        
        let mut file_path_opt: Option<String> = None;
        let mut info_msg_opt: Option<String> = None;
        let mut output_log = String::new();

        let mut reader = BufReader::new(stdout).lines();
        while let Ok(Some(line)) = reader.next_line().await {
            output_log.push_str(&line);
            output_log.push('\n');

            if line.starts_with("PROGRESS:") {
                if let Some(tx) = &progress_tx_clone {
                    let parts: Vec<&str> = line.trim_start_matches("PROGRESS:").split('/').collect();
                    if parts.len() == 2 {
                        let cur: f64 = parts[0].parse().unwrap_or(0.0);
                        let tot: f64 = parts[1].parse().unwrap_or(1.0);
                        let mut pct = (cur / tot * 50.0) as u32; // Telegram download is first 50% of total job
                        if pct < 10 { pct = 10; }
                        
                        let msg = serde_json::json!({
                            "type": "upload_video_progress",
                            "job_id": job_id_clone,
                            "stage": "downloading_telegram",
                            "progress": pct,
                        }).to_string();
                        let _ = tx.send(msg);
                    }
                }
            } else if line.starts_with("SUCCESS:") {
                let parts: Vec<&str> = line.splitn(2, ':').collect();
                if parts.len() == 2 {
                    file_path_opt = Some(parts[1].trim().to_string());
                }
            } else if line.starts_with("INFO:") {
                let parts: Vec<&str> = line.split(':').collect();
                if parts.len() >= 3 {
                    let size_bytes: f64 = parts[1].parse().unwrap_or(0.0);
                    let size_mb = size_bytes / 1024.0 / 1024.0;
                    info_msg_opt = Some(format!("✅ TEST CONNECTION SUCCESS!\n\n[Server Tag: v9.3.7]\nFile Name: {}\nFile Size: {:.2} MB\n\nThe bot can successfully read the private channel without downloading it!", parts[2], size_mb));
                }
            } else {
                info!("Python TG Proxy: {}", line);
            }
        }

        let status = child.wait().await.map_err(|e| format!("Failed to wait on child: {}", e))?;

        if let Some(info_msg) = info_msg_opt {
             return Err(info_msg);
        }

        if !status.success() || file_path_opt.is_none() {
            let mut err_log = String::new();
            let mut err_reader = BufReader::new(stderr).lines();
            while let Ok(Some(l)) = err_reader.next_line().await { err_log.push_str(&l); err_log.push('\n'); }
            
            error!("Telethon Script Failed. Status: {}\nOutput: {}\nError: {}", status, output_log, err_log);
            return Err(format!("Python Telethon proxy failed: {}", err_log));
        }

        let file_path_str = file_path_opt.unwrap();

        let file_path = std::path::Path::new(&file_path_str);
        
        // Wrap the downloaded python temp file into a standard NamedTempFile so the rest of the flow is identical
        let mut tmp = tempfile::NamedTempFile::new().map_err(|e| format!("Failed to create temp for TG: {}", e))?;
        
        let py_bytes = tokio::fs::read(file_path).await.map_err(|e| format!("Failed to read python downloaded file: {}", e))?;
        std::io::Write::write_all(&mut tmp, &py_bytes).map_err(|e| format!("Write all error: {}", e))?;
        
        // Cleanup the python-generated temp file
        let _ = tokio::fs::remove_file(file_path).await;

        let file_name = format!("telegram_video_{}.mp4", chrono::Utc::now().timestamp());
        
        let tmp_file = tempfile::Builder::new()
            .suffix(&format!("_{}", file_name))
            .tempfile()
            .map_err(|e| format!("Tempfile error: {}", e))?;

        std::fs::copy(tmp.path(), tmp_file.path())
            .map_err(|e| format!("Copy file error: {}", e))?;

        info!("Telethon Download OK: '{}': {} bytes", file_name, py_bytes.len());
        return Ok((tmp_file, file_name));
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
