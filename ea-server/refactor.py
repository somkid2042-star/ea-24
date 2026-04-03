import re
import sys

def process(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Remove `mod gui;`
    content = re.sub(r'mod gui;\n', '', content)
    
    # 2. Remove `use crate::gui::ServerState as TrayState;`
    content = re.sub(r'use crate::gui::ServerState as TrayState;\n', '', content)

    # 3. Rewrite main fn
    main_replacement = """#[tokio::main]
async fn main() {
    // ---------------------------------------------------------
    // Single Instance Lock
    // ---------------------------------------------------------
    let lock_addr = std::net::SocketAddr::from(([127, 0, 0, 1], 4174));
    let _app_lock = match std::net::UdpSocket::bind(lock_addr) {
        Ok(s) => s,
        Err(_) => {
            eprintln!("Another instance of EA Server is already running. Exiting.");
            std::process::exit(0);
        }
    };

    // Redirect log output to file (no console window available)
    let log_file = std::fs::File::create("ea-server.log").ok();
    let mut builder = env_logger::Builder::from_env(env_logger::Env::default().default_filter_or("info"));
    if let Some(file) = log_file {
        builder.target(env_logger::Target::Pipe(Box::new(file)));
    }
    builder.init();

    run_server().await;
}

async fn run_server() {"""
    
    content = re.sub(r'fn main\(\) \{.*?(?=async fn run_server)async fn run_server\(tray_tx: Arc<watch::Sender<TrayState>>\) \{', main_replacement, content, flags=re.DOTALL)
    
    # 4. Remove tokio::sync::watch
    content = re.sub(r'use tokio::sync::\{broadcast, watch, RwLock\};', 'use tokio::sync::{broadcast, RwLock};', content)

    # 5. Remove all tray_tx lines
    content = re.sub(r'[ \t]*let tray_tx_.*= tray_tx\.clone\(\);\n', '', content)
    content = re.sub(r'[ \t]*let sys_tx = tray_tx\.clone\(\);\n', '', content)
    content = re.sub(r'[ \t]*tray_tx: Arc<watch::Sender<TrayState>>,\n', '', content)
    content = re.sub(r'[ \t]*tray_tx_mt5\.clone\(\),\n', '', content)
    content = re.sub(r'[ \t]*let _ = tray_tx.*?(?=\}\);\n| \}\n).*?\}\)(?:;|\n)', '', content, flags=re.DOTALL)

    # Clean up the `let _ = tray_tx.send(TrayState { ... });` blocks specifically
    content = re.sub(r'[ \t]*let _ = tray_tx\.send\(TrayState \{[^\}]+\}\);\n', '', content)

    # 6. Remove the Wine deployment code inside `update_ea`.
    # Wait, the `update_ea` is inside a match block for MT5 commands.
    # It's better to just write over the `update_ea` string match block manually later,
    # or just use regex to stub it out.
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
        
    print("Refactoring complete.")

process("/Users/somkidchaihanid/Desktop/ea-24/ea-server/src/main.rs")
