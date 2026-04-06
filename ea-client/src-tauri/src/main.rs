// Prevents additional console window on Windows in release
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

#[tauri::command]
fn open_chrome_incognito(url: String) -> Result<(), String> {
    #[cfg(target_os = "macos")]
    let res = std::process::Command::new("open")
        .args(["-a", "Google Chrome", "-n", "--args", "--incognito", &url])
        .spawn();

    #[cfg(target_os = "windows")]
    let res = std::process::Command::new("cmd")
        .args(["/c", "start", "chrome", "--incognito", &url])
        .spawn();

    #[cfg(target_os = "linux")]
    let res = std::process::Command::new("google-chrome")
        .args(["--incognito", &url])
        .spawn();

    match res {
        Ok(_) => Ok(()),
        Err(e) => Err(e.to_string())
    }
}

fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_single_instance::init(|app, args, cwd| {}))
        .plugin(tauri_plugin_updater::Builder::new().build())
        .invoke_handler(tauri::generate_handler![open_chrome_incognito])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
