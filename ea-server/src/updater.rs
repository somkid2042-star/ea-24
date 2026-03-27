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

pub async fn check_and_update(tx: Option<broadcast::Sender<String>>) {
    let current_version = env!("CARGO_PKG_VERSION");
    
    let send_status = |msg: &str| {
        if let Some(ref tx) = tx {
            let json = serde_json::json!({
                "type": "update_status",
                "status": "checking",
                "message": msg
            });
            let _ = tx.send(json.to_string());
        }
    };

    send_status(&format!("Checking for updates... (Current: v{})", current_version));
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
                send_status("Failed to parse release data.");
                return;
            }
        },
        Err(e) => {
            error!("❌ Failed to fetch GitHub release: {}", e);
            send_status("Failed to fetch release from GitHub.");
            return;
        }
    };

    let latest_version = release.tag_name.trim_start_matches('v');
    info!("📦 Latest version on GitHub: v{}", latest_version);

    if latest_version <= current_version {
        info!("✅ You are running the latest version! No update needed.");
        send_status("You are running the latest version.");
        return;
    }

    send_status(&format!("New version found! Downloading v{}...", latest_version));
    info!("🔥 New version found! Downloading v{}...", latest_version);

    let exe_asset = release.assets.iter().find(|a| a.name == "ea-server.exe");
    if let Some(asset) = exe_asset {
        let download_url = &asset.browser_download_url;
        match download_and_install(download_url, client, github_token.as_deref()).await {
            Ok(_) => {
                send_status("Update successful! Restarting server...");
                info!("🚀 Update successful! Restarting server in 2 seconds...");
                tokio::time::sleep(tokio::time::Duration::from_secs(2)).await;
                
                let current_exe = std::env::current_exe().unwrap_or_else(|_| PathBuf::from("ea-server.exe"));
                let mut cmd = std::process::Command::new(&current_exe);
                
                #[cfg(target_os = "windows")]
                {
                    use std::os::windows::process::CommandExt;
                    cmd.creation_flags(0x08000000);
                }
                
                let _ = cmd.spawn();
                std::process::exit(0);
            }
            Err(e) => {
                error!("❌ Update failed: {}", e);
                send_status("Download failed. Check server logs for details.");
            }
        }
    } else {
        error!("❌ Could not find ea-server.exe in the latest GitHub release assets.");
        send_status("Release asset 'ea-server.exe' not found.");
    }
}

async fn download_and_install(url: &str, client: reqwest::Client, token: Option<&str>) -> Result<(), String> {
    let mut req = client.get(url)
        .header(USER_AGENT, "EA-24-Server-Updater")
        .header("Accept", "application/octet-stream");
    if let Some(token) = token {
        req = req.header(AUTHORIZATION, format!("Bearer {}", token));
    }
    let res = req.send().await.map_err(|e| e.to_string())?;
    let bytes = res.bytes().await.map_err(|e| e.to_string())?;

    let current_exe = std::env::current_exe().map_err(|e| e.to_string())?;
    let old_exe = current_exe.with_file_name("ea-server-old.exe");
    let new_exe = current_exe.with_file_name("ea-server-new.exe");

    // Clean up any previous old.exe silently
    let _ = fs::remove_file(&old_exe);

    // Write downloaded bytes to new_exe
    std::fs::write(&new_exe, bytes).map_err(|e| format!("Failed to write new exe: {}", e))?;

    // Rename current to old (which works even when running on Windows)
    std::fs::rename(&current_exe, &old_exe).map_err(|e| format!("Failed to rename current exe: {}", e))?;

    // Rename new to current
    std::fs::rename(&new_exe, &current_exe).map_err(|e| format!("Failed to swap in new exe: {}", e))?;

    Ok(())
}
