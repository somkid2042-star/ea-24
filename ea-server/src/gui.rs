use tokio::sync::watch;
use eframe::egui;

#[derive(Debug, Clone)]
pub struct ServerState {
    pub server_online: bool,
    pub ea_connected: bool,
    pub ea_version: String,
    pub ea_symbol: String,
    pub last_error: Option<String>,
    pub cpu_usage: f32,
    pub ram_usage_mb: u64,
    pub total_ram_mb: u64,
    pub net_rx_kb: f32,
    pub net_tx_kb: f32,
    pub db_pool_size: u32,
}

impl Default for ServerState {
    fn default() -> Self {
        Self {
            server_online: true,
            ea_connected: false,
            ea_version: "—".to_string(),
            ea_symbol: "".to_string(),
            last_error: None,
            cpu_usage: 0.0,
            ram_usage_mb: 0,
            total_ram_mb: 0,
            net_rx_kb: 0.0,
            net_tx_kb: 0.0,
            db_pool_size: 0,
        }
    }
}

struct EaServerApp {
    state_rx: watch::Receiver<ServerState>,
}

impl EaServerApp {
    fn new(state_rx: watch::Receiver<ServerState>) -> Self {
        Self { state_rx }
    }
}

impl eframe::App for EaServerApp {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        // Force repaint every 500ms so we see updates quickly
        ctx.request_repaint_after(std::time::Duration::from_millis(500));

        let state = self.state_rx.borrow().clone();

        egui::CentralPanel::default().show(ctx, |ui| {
            ui.heading("EA Server Console");
            ui.separator();

            if let Some(ref err) = state.last_error {
                ui.colored_label(egui::Color32::RED, format!("ERROR: {}", err));
            } else if state.server_online {
                ui.colored_label(egui::Color32::GREEN, "Server Status: Online");
            } else {
                ui.colored_label(egui::Color32::YELLOW, "Server Status: Offline");
            }
            ui.separator();

            ui.heading("MT5 Connection");
            if state.ea_connected {
                ui.colored_label(egui::Color32::GREEN, "EA Status: Connected");
                ui.label(format!("Version: {}", state.ea_version));
                ui.label(format!("Symbol: {}", state.ea_symbol));
            } else {
                ui.colored_label(egui::Color32::YELLOW, "EA Status: Waiting for connection...");
            }
            ui.separator();

            ui.heading("EA-Server Process");
            
            let progress_color = |p: f32| -> egui::Color32 {
                if p >= 0.8 { egui::Color32::from_rgb(220, 50, 50) } // Red
                else if p >= 0.5 { egui::Color32::from_rgb(220, 180, 50) } // Yellow
                else { egui::Color32::from_rgb(50, 200, 100) } // Green
            };

            // Database Pool Bar
            ui.label("Database Pool:");
            let db_progress = (state.db_pool_size as f32 / 20.0).clamp(0.0, 1.0);
            ui.add(egui::ProgressBar::new(db_progress)
                .fill(progress_color(db_progress))
                .text(format!("{} / 20 Conns", state.db_pool_size)));

            // CPU Progress Bar
            ui.label("Process CPU:");
            let mut cpu_progress = state.cpu_usage / 100.0;
            if cpu_progress > 1.0 { cpu_progress = 1.0; }
            ui.add(egui::ProgressBar::new(cpu_progress)
                .fill(progress_color(cpu_progress))
                .text(format!("{:.1}%", state.cpu_usage)));

            // RAM Progress Bar
            ui.label("Process RAM:");
            let ram_progress = if state.total_ram_mb > 0 {
                (state.ram_usage_mb as f32 / state.total_ram_mb as f32).clamp(0.0, 1.0)
            } else {
                0.0
            };
            ui.add(egui::ProgressBar::new(ram_progress)
                .fill(progress_color(ram_progress))
                .text(format!("{} MB / {} MB", state.ram_usage_mb, state.total_ram_mb)));

            // Network Traffic Progress Bars
            ui.label("Network Traffic:");
            let max_kbps = 10000.0; // 10 MB/s full scale assumption
            let rx_progress = (state.net_rx_kb / max_kbps).clamp(0.0, 1.0);
            ui.add(egui::ProgressBar::new(rx_progress)
                .fill(progress_color(rx_progress))
                .text(format!("RX: {:.1} KB/s", state.net_rx_kb)));
            
            let tx_progress = (state.net_tx_kb / max_kbps).clamp(0.0, 1.0);
            ui.add(egui::ProgressBar::new(tx_progress)
                .fill(progress_color(tx_progress))
                .text(format!("TX: {:.1} KB/s", state.net_tx_kb)));
        });
    }
}

fn load_icon() -> Result<std::sync::Arc<egui::IconData>, String> {
    let icon_data = include_bytes!("../assets/icon.png");
    let image = image::load_from_memory(icon_data)
        .map_err(|e| format!("Error loading icon: {}", e))?
        .into_rgba8();
    let (width, height) = image.dimensions();
    Ok(std::sync::Arc::new(egui::IconData {
        rgba: image.into_raw(),
        width,
        height,
    }))
}

pub fn run_gui(state_rx: watch::Receiver<ServerState>) {
    let title = format!("EA-SERVER v{}", env!("CARGO_PKG_VERSION"));
    
    let mut viewport = egui::ViewportBuilder::default()
        .with_app_id("ea-server")
        .with_inner_size([400.0, 480.0])
        .with_resizable(false)
        .with_title(&title);
        
    if let Ok(icon) = load_icon() {
        viewport = viewport.with_icon(icon);
    }

    let options = eframe::NativeOptions {
        viewport,
        ..Default::default()
    };
    
    let _ = eframe::run_native(
        &title,
        options,
        Box::new(|cc| {
            let mut fonts = egui::FontDefinitions::default();
            fonts.font_data.insert(
                "CamingoCode".to_owned(),
                egui::FontData::from_static(include_bytes!("../../font/camingocode/CamingoCode-Regular.ttf")),
            );
            if let Some(family) = fonts.families.get_mut(&egui::FontFamily::Proportional) {
                family.insert(0, "CamingoCode".to_owned());
            }
            if let Some(family) = fonts.families.get_mut(&egui::FontFamily::Monospace) {
                family.insert(0, "CamingoCode".to_owned());
            }
            cc.egui_ctx.set_fonts(fonts);

            Ok(Box::new(EaServerApp::new(state_rx)))
        }),
    );
}
