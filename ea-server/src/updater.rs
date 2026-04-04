use log::{error, info, warn};
use reqwest::header::{AUTHORIZATION, USER_AGENT};
use serde::Deserialize;
use std::fs;
use std::path::PathBuf;
use tokio::sync::broadcast;

/// Load GitHub PAT from `github_token.txt` next to the executable
fn load_github_token() -> Option<String> {
    let exe_dir = std::env::current_exe().ok()?.parent()?.to_path_buf();
    let token_path = exe_dir.join("github_token.txt");
    match fs::read_to_string(&token_path) {
        Ok(token) => {
            let token = token.trim().to_string();
            if token.is_empty() { None } else { Some(token) }
        }
        Err(_) => {
            warn!("⚠️ github_token.txt not found at {:?} — update check will use public API", token_path);
            None
        }
    }
}

#[derive(Deserialize)]
struct Release {
    tag_name: String,
    assets: Vec<Asset>,
}

#[derive(Deserialize)]
struct Asset {
    name: String,
    browser_download_url: String,
}

/// Check for new version on GitHub and auto-update if available.
/// Supports Ubuntu/Linux with systemd restart.
pub async fn check_and_update(tx: Option<broadcast::Sender<String>>) {
    let current_version = env!("CARGO_PKG_VERSION");
    
    let send_status = |status: &str, msg: &str| {
        if let Some(ref tx) = tx {
            let json = serde_json::json!({
                "type": "update_status",
                "status": status,
                "message": msg,
                "current_version": current_version,
            });
            let _ = tx.send(json.to_string());
        }
    };

    send_status("checking", &format!("Checking for updates... (Current: v{})", current_version));
    info!("🔄 Checking for server updates on GitHub... (Current: v{})", current_version);

    let github_token = load_github_token();

    let client = reqwest::Client::new();
    let mut req = client
        .get("https://api.github.com/repos/somkid2042-star/ea-24/releases/latest")
        .header(USER_AGENT, "EA-24-Server-Updater");
    if let Some(ref token) = github_token {
        req = req.header(AUTHORIZATION, format!("Bearer {}", token));
    }
    let res = req.send().await;

    let release: Release = match res {
        Ok(r) => match r.json().await {
            Ok(json) => json,
            Err(e) => {
                error!("❌ Failed to parse GitHub release JSON: {}", e);
                send_status("error", "Failed to parse release data.");
                return;
            }
        },
        Err(e) => {
            error!("❌ Failed to fetch GitHub release: {}", e);
            send_status("error", "Failed to fetch release from GitHub.");
            return;
        }
    };

    let latest_version = release.tag_name.trim_start_matches('v');
    info!("📦 Latest version on GitHub: v{}", latest_version);

    // Semantic version comparison
    if !is_newer_version(current_version, latest_version) {
        info!("✅ You are running the latest version! No update needed.");
        send_status("up_to_date", &format!("Running latest version (v{}).", current_version));
        return;
    }

    send_status("downloading", &format!("New version found! v{} → v{}. Downloading...", current_version, latest_version));
    info!("🔥 New version found! v{} → v{}. Downloading...", current_version, latest_version);

    // Look for Linux binary (no .exe extension)
    let exe_asset = release.assets.iter().find(|a| a.name == "ea-server");
    if let Some(asset) = exe_asset {
        let download_url = &asset.browser_download_url;
        match download_and_install(download_url, client, github_token.as_deref()).await {
            Ok(_) => {
                send_status("restarting", &format!("Update to v{} successful! Restarting server...", latest_version));
                info!("🚀 Update to v{} successful! Restarting...", latest_version);
                tokio::time::sleep(tokio::time::Duration::from_secs(2)).await;
                
                restart_server();
            }
            Err(e) => {
                error!("❌ Update failed: {}", e);
                send_status("error", &format!("Update failed: {}", e));
            }
        }
    } else {
        let asset_names: Vec<&str> = release.assets.iter().map(|a| a.name.as_str()).collect();
        error!("❌ 'ea-server' binary not found in release assets. Available: {:?}", asset_names);
        send_status("error", "Release asset 'ea-server' not found.");
    }
}

/// Semantic version comparison: returns true if latest > current
fn is_newer_version(current: &str, latest: &str) -> bool {
    let parse = |v: &str| -> Vec<u32> {
        v.split('.').filter_map(|s| s.parse().ok()).collect()
    };
    let cur = parse(current);
    let lat = parse(latest);
    for i in 0..std::cmp::max(cur.len(), lat.len()) {
        let c = cur.get(i).copied().unwrap_or(0);
        let l = lat.get(i).copied().unwrap_or(0);
        if l > c { return true; }
        if l < c { return false; }
    }
    false
}

async fn download_and_install(url: &str, client: reqwest::Client, token: Option<&str>) -> Result<(), String> {
    let mut req = client.get(url)
        .header(USER_AGENT, "EA-24-Server-Updater")
        .header("Accept", "application/octet-stream");
    if let Some(token) = token {
        req = req.header(AUTHORIZATION, format!("Bearer {}", token));
    }
    let res = req.send().await.map_err(|e| e.to_string())?;
    
    let status = res.status();
    if !status.is_success() {
        return Err(format!("Download failed with HTTP {}", status));
    }
    
    let bytes = res.bytes().await.map_err(|e| e.to_string())?;
    info!("📥 Downloaded {} bytes", bytes.len());

    let current_exe = std::env::current_exe().map_err(|e| e.to_string())?;
    let old_exe = current_exe.with_file_name("ea-server-old");
    let new_exe = current_exe.with_file_name("ea-server-new");

    // Clean up any previous old binary silently
    let _ = fs::remove_file(&old_exe);

    // Write downloaded bytes to new binary
    std::fs::write(&new_exe, bytes).map_err(|e| format!("Failed to write new binary: {}", e))?;

    // Make it executable (Linux)
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        let mut perms = std::fs::metadata(&new_exe).map_err(|e| format!("Failed to read metadata: {}", e))?.permissions();
        perms.set_mode(0o755);
        std::fs::set_permissions(&new_exe, perms).map_err(|e| format!("Failed to set executable permission: {}", e))?;
    }

    // Atomic swap: current → old, new → current
    std::fs::rename(&current_exe, &old_exe).map_err(|e| format!("Failed to rename current binary: {}", e))?;
    std::fs::rename(&new_exe, &current_exe).map_err(|e| format!("Failed to swap in new binary: {}", e))?;

    info!("✅ Binary swapped successfully: {:?}", current_exe);
    Ok(())
}

/// Restart the server process.
/// Kills all old ea-server processes first, then restarts via systemd.
fn restart_server() {
    info!("🔪 Killing all old ea-server processes before restart...");
    
    // Kill ALL ea-server processes (including this one — systemd will restart us)
    let _ = std::process::Command::new("bash")
        .args(["-c", "pkill -9 -f ea-server || true"])
        .output();

    // Check if running under systemd
    if std::env::var("INVOCATION_ID").is_ok() || is_systemd_service() {
        info!("🔄 Detected systemd — using systemctl restart...");
        match std::process::Command::new("systemctl")
            .args(["restart", "ea-server"])
            .spawn()
        {
            Ok(_) => {
                info!("🚀 systemctl restart issued. Exiting current process...");
                std::process::exit(0);
            }
            Err(e) => {
                warn!("⚠️ systemctl restart failed: {}. Trying direct re-exec...", e);
            }
        }
    }

    // Fallback: direct re-exec
    info!("🔄 Restarting via direct re-exec...");
    let current_exe = std::env::current_exe().unwrap_or_else(|_| PathBuf::from("./ea-server"));
    let _ = std::process::Command::new(&current_exe).spawn();
    std::process::exit(0);
}

/// Check if the process is managed by a systemd service
fn is_systemd_service() -> bool {
    // Check if ea-server.service is active
    if let Ok(output) = std::process::Command::new("systemctl")
        .args(["is-active", "ea-server"])
        .output()
    {
        let status = String::from_utf8_lossy(&output.stdout);
        return status.trim() == "active";
    }
    false
}
