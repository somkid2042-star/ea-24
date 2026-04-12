// ──────────────────────────────────────────────
//  drive.rs — Google Drive Upload via Service Account
//  Uses raw HTTP with JWT (no heavy google-drive3 crate)
// ──────────────────────────────────────────────

use base64::{Engine as _, engine::general_purpose};
use log::{error, info};
use serde::{Deserialize, Serialize};
use std::time::{SystemTime, UNIX_EPOCH};

// ──────────────────────────────────────────────
//  Public Result Type
// ──────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DriveUploadResult {
    pub file_id: String,
    pub file_name: String,
    pub drive_link: String,
    pub size_bytes: u64,
}

// ──────────────────────────────────────────────
//  Service Account JSON Structure
// ──────────────────────────────────────────────

#[derive(Debug, Deserialize, Clone)]
pub struct ServiceAccountKey {
    pub private_key: String,
    pub client_email: String,
    #[allow(dead_code)]
    pub project_id: Option<String>,
}

// ──────────────────────────────────────────────
//  JWT Creation (RS256 — manual implementation)
// ──────────────────────────────────────────────

/// Build a JWT for Google OAuth2 service account
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

    // Sign with RSA private key using rsa crate
    let signature = sign_rsa(&sa.private_key, signing_input.as_bytes())?;
    let sig_b64 = general_purpose::URL_SAFE_NO_PAD.encode(&signature);

    Ok(format!("{}.{}", signing_input, sig_b64))
}

/// RSA-SHA256 signing using openssl (available via reqwest's rustls)
fn sign_rsa(pem_key: &str, data: &[u8]) -> Result<Vec<u8>, String> {
    // Use ring crate for RSA signing
    // Parse PEM → DER
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
    let scope = "https://www.googleapis.com/auth/drive.file";
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
//  Create Drive Folder
// ──────────────────────────────────────────────

pub async fn create_drive_folder(
    sa: &ServiceAccountKey,
    folder_name: &str,
    parent_folder_id: Option<&str>,
) -> Result<String, String> {
    let token = get_access_token(sa).await?;

    let mut metadata = serde_json::json!({
        "name": folder_name,
        "mimeType": "application/vnd.google-apps.folder"
    });

    if let Some(parent) = parent_folder_id {
        metadata["parents"] = serde_json::json!([parent]);
    }

    let client = reqwest::Client::new();
    let resp = client
        .post("https://www.googleapis.com/drive/v3/files")
        .bearer_auth(&token)
        .json(&metadata)
        .send()
        .await
        .map_err(|e| format!("Create folder request failed: {}", e))?;

    let body: serde_json::Value = resp
        .json()
        .await
        .map_err(|e| format!("Create folder response parse failed: {}", e))?;

    if let Some(id) = body["id"].as_str() {
        info!("Created Drive folder '{}' with ID: {}", folder_name, id);
        Ok(id.to_string())
    } else {
        Err(format!("No folder ID in response: {}", body))
    }
}

// ──────────────────────────────────────────────
//  Set File/Folder Public Readable
// ──────────────────────────────────────────────

pub async fn make_public(sa: &ServiceAccountKey, file_id: &str) -> Result<(), String> {
    let token = get_access_token(sa).await?;

    let client = reqwest::Client::new();
    let permission = serde_json::json!({
        "type": "anyone",
        "role": "reader"
    });

    let resp = client
        .post(format!(
            "https://www.googleapis.com/drive/v3/files/{}/permissions",
            file_id
        ))
        .bearer_auth(&token)
        .json(&permission)
        .send()
        .await
        .map_err(|e| format!("Set permission failed: {}", e))?;

    if resp.status().is_success() {
        Ok(())
    } else {
        let body = resp.text().await.unwrap_or_default();
        Err(format!("Set permission failed: {}", body))
    }
}

// ──────────────────────────────────────────────
//  Download Video from URL → Temp File
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

    let resp = client
        .get(url)
        .send()
        .await
        .map_err(|e| format!("Download request failed: {}", e))?;

    if !resp.status().is_success() {
        return Err(format!("Download failed with status: {}", resp.status()));
    }

    // Detect filename from Content-Disposition or URL
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
            // Extract from URL
            let url_path = url.split('?').next().unwrap_or(url);
            let base = url_path.split('/').last().unwrap_or("video");
            if base.contains('.') {
                base.to_string()
            } else {
                format!("{}.mp4", base)
            }
        }
    };

    let total_size = resp
        .content_length()
        .unwrap_or(0);

    // Create temp file
    let mut tmp = tempfile::NamedTempFile::new()
        .map_err(|e| format!("Failed to create temp file: {}", e))?;

    let tmp_path = tmp.path().to_path_buf();
    let mut file = tokio::fs::File::create(&tmp_path)
        .await
        .map_err(|e| format!("Failed to open temp file for writing: {}", e))?;

    let mut downloaded: u64 = 0;
    let mut stream = resp.bytes_stream();
    use futures_util::StreamExt;

    while let Some(chunk) = stream.next().await {
        let chunk = chunk.map_err(|e| format!("Download stream error: {}", e))?;
        file.write_all(&chunk)
            .await
            .map_err(|e| format!("Write error: {}", e))?;
        downloaded += chunk.len() as u64;

        // Send progress update
        if let Some(tx) = &progress_tx {
            let pct = if total_size > 0 {
                (downloaded as f64 / total_size as f64 * 50.0) as u32 // 0-50% for download
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

    // Re-open as NamedTempFile
    let tmp_file = tempfile::Builder::new()
        .suffix(&format!("_{}", file_name))
        .tempfile()
        .map_err(|e| format!("Tempfile error: {}", e))?;

    // Copy downloaded content to the new named temp file
    std::fs::copy(&tmp_path, tmp_file.path())
        .map_err(|e| format!("Copy temp file error: {}", e))?;

    info!(
        "Downloaded '{}': {} bytes to {:?}",
        file_name,
        downloaded,
        tmp_file.path()
    );

    Ok((tmp_file, file_name))
}

// ──────────────────────────────────────────────
//  Upload File to Google Drive (Multipart)
// ──────────────────────────────────────────────

pub async fn upload_to_drive(
    file_bytes: Vec<u8>,
    file_name: &str,
    folder_id: &str,
    sa: &ServiceAccountKey,
    progress_tx: Option<tokio::sync::broadcast::Sender<String>>,
    job_id: &str,
) -> Result<DriveUploadResult, String> {
    let token = get_access_token(sa).await?;

    // Detect MIME type
    let mime_type = mime_guess::from_path(file_name)
        .first_or_octet_stream()
        .to_string();

    // Metadata
    let metadata = serde_json::json!({
        "name": file_name,
        "parents": [folder_id]
    });

    // Build multipart body manually (Drive API multipart upload)
    let boundary = "ea24_drive_upload_boundary";
    let meta_str = metadata.to_string();

    let mut body: Vec<u8> = Vec::new();
    // Part 1: metadata
    body.extend_from_slice(
        format!(
            "--{}\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n{}\r\n",
            boundary, meta_str
        )
        .as_bytes(),
    );
    // Part 2: file content
    body.extend_from_slice(
        format!(
            "--{}\r\nContent-Type: {}\r\n\r\n",
            boundary, mime_type
        )
        .as_bytes(),
    );
    body.extend_from_slice(&file_bytes);
    body.extend_from_slice(format!("\r\n--{}--", boundary).as_bytes());

    let size_bytes = file_bytes.len() as u64;

    // Send progress update (50% = upload starting)
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

    let resp = client
        .post("https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&fields=id,name,webViewLink")
        .bearer_auth(&token)
        .header(
            "Content-Type",
            format!("multipart/related; boundary={}", boundary),
        )
        .body(body)
        .send()
        .await
        .map_err(|e| format!("Upload request failed: {}", e))?;

    if !resp.status().is_success() {
        let status = resp.status();
        let body = resp.text().await.unwrap_or_default();
        return Err(format!("Upload failed ({}): {}", status, body));
    }

    let result: serde_json::Value = resp
        .json()
        .await
        .map_err(|e| format!("Upload response parse failed: {}", e))?;

    let file_id = result["id"]
        .as_str()
        .ok_or("No file ID in upload response")?
        .to_string();

    let drive_link = result["webViewLink"]
        .as_str()
        .unwrap_or(&format!(
            "https://drive.google.com/file/d/{}/view",
            file_id
        ))
        .to_string();

    info!(
        "Uploaded '{}' to Drive: {} ({} bytes)",
        file_name, file_id, size_bytes
    );

    Ok(DriveUploadResult {
        file_id,
        file_name: file_name.to_string(),
        drive_link,
        size_bytes,
    })
}

// ──────────────────────────────────────────────
//  Full Pipeline: URL → Download → Drive Upload
// ──────────────────────────────────────────────

pub async fn upload_url_to_drive(
    video_url: &str,
    folder_id: &str,
    sa: &ServiceAccountKey,
    progress_tx: Option<tokio::sync::broadcast::Sender<String>>,
    job_id: &str,
) -> Result<DriveUploadResult, String> {
    info!("Starting upload pipeline: {} → Drive folder {}", video_url, folder_id);

    // Step 1: Download
    let (tmp_file, file_name) =
        download_video(video_url, progress_tx.clone(), job_id).await?;

    // Step 2: Read bytes
    let file_bytes =
        std::fs::read(tmp_file.path()).map_err(|e| format!("Failed to read temp file: {}", e))?;

    drop(tmp_file); // Delete temp file

    // Step 3: Upload to Drive
    let result = upload_to_drive(
        file_bytes,
        &file_name,
        folder_id,
        sa,
        progress_tx,
        job_id,
    )
    .await?;

    Ok(result)
}
