use tokio::sync::watch;
use trayicon::{Icon, MenuBuilder, TrayIconBuilder};
use winit::application::ApplicationHandler;
use winit::event::WindowEvent;
use winit::event_loop::{ActiveEventLoop, EventLoop};

// ──────────────────────────────────────────────
//  Tray State (received from server via watch)
// ──────────────────────────────────────────────

#[derive(Debug, Clone)]
pub struct TrayState {
    pub server_online: bool,
    pub ea_connected: bool,
    pub ea_version: String,
    pub ea_symbol: String,
    pub last_error: Option<String>,
}

impl Default for TrayState {
    fn default() -> Self {
        Self {
            server_online: true,
            ea_connected: false,
            ea_version: "—".to_string(),
            ea_symbol: "".to_string(),
            last_error: None,
        }
    }
}

// ──────────────────────────────────────────────
//  Tray Events
// ──────────────────────────────────────────────

#[derive(Clone, Eq, PartialEq, Debug)]
enum TrayEvent {
    LeftClick,
    RightClick,
    Exit,
}

// ──────────────────────────────────────────────
//  Icon Generator (draws a colored circle)
// ──────────────────────────────────────────────

fn create_icon(r: u8, g: u8, b: u8) -> Icon {
    let size: u32 = 32;
    let mut rgba = vec![0u8; (size * size * 4) as usize];
    let cx = size as f32 / 2.0;
    let cy = size as f32 / 2.0;
    let radius = size as f32 / 2.0 - 1.0;

    for y in 0..size {
        for x in 0..size {
            let dx = x as f32 - cx;
            let dy = y as f32 - cy;
            let dist = (dx * dx + dy * dy).sqrt();
            let idx = ((y * size + x) * 4) as usize;

            if dist <= radius {
                let factor = 1.0 - (dist / radius) * 0.3;
                rgba[idx] = (r as f32 * factor).min(255.0) as u8;
                rgba[idx + 1] = (g as f32 * factor).min(255.0) as u8;
                rgba[idx + 2] = (b as f32 * factor).min(255.0) as u8;
                rgba[idx + 3] = 255;
            } else if dist <= radius + 1.0 {
                let alpha = ((radius + 1.0 - dist) * 255.0) as u8;
                rgba[idx] = r;
                rgba[idx + 1] = g;
                rgba[idx + 2] = b;
                rgba[idx + 3] = alpha;
            }
        }
    }

    // Encode RGBA pixels → ICO format (required by trayicon)
    let img = image::RgbaImage::from_raw(size, size, rgba).expect("Invalid RGBA data");
    let mut ico_buf: Vec<u8> = Vec::new();
    {
        use image::ImageEncoder;
        let encoder = image::codecs::ico::IcoEncoder::new(&mut ico_buf);
        encoder
            .write_image(&img, size, size, image::ExtendedColorType::Rgba8)
            .expect("Failed to encode ICO");
    }

    let leaked: &'static [u8] = Box::leak(ico_buf.into_boxed_slice());
    Icon::from_buffer(leaked, None, None).expect("Failed to create icon")
}

fn green_icon() -> Icon {
    create_icon(76, 175, 80) // Material Green
}

fn yellow_icon() -> Icon {
    create_icon(255, 193, 7) // Material Amber
}

fn red_icon() -> Icon {
    create_icon(244, 67, 54) // Material Red
}

// ──────────────────────────────────────────────
//  Build tooltip string
// ──────────────────────────────────────────────

fn build_tooltip(state: &TrayState) -> String {
    if let Some(ref err) = state.last_error {
        return format!("EA Server: ERROR\n{}", err);
    }
    if !state.server_online {
        return "EA Server: Offline".to_string();
    }
    if state.ea_connected {
        format!(
            "EA Server: Online\nEA v{} | {}",
            state.ea_version, state.ea_symbol
        )
    } else {
        "EA Server: Online\nEA: Waiting...".to_string()
    }
}

// ──────────────────────────────────────────────
//  Application
// ──────────────────────────────────────────────

struct TrayApp {
    tray: trayicon::TrayIcon<TrayEvent>,
    state_rx: watch::Receiver<TrayState>,
    green: Icon,
    yellow: Icon,
    red: Icon,
    last_ea_connected: bool,
    last_has_error: bool,
}

impl ApplicationHandler<TrayEvent> for TrayApp {
    fn resumed(&mut self, _event_loop: &ActiveEventLoop) {}

    fn window_event(
        &mut self,
        _event_loop: &ActiveEventLoop,
        _window_id: winit::window::WindowId,
        _event: WindowEvent,
    ) {
    }

    fn user_event(&mut self, event_loop: &ActiveEventLoop, event: TrayEvent) {
        match event {
            TrayEvent::Exit => {
                log::info!("🛑 Exiting from system tray...");
                event_loop.exit();
                std::process::exit(0);
            }
            TrayEvent::LeftClick | TrayEvent::RightClick => {
                let _ = self.tray.show_menu();
            }
        }
    }

    fn about_to_wait(&mut self, _event_loop: &ActiveEventLoop) {
        // Poll for state changes
        if self.state_rx.has_changed().unwrap_or(false) {
            let state = self.state_rx.borrow_and_update().clone();

            // Update tooltip
            let tooltip = build_tooltip(&state);
            let _ = self.tray.set_tooltip(&tooltip);

            let has_error = state.last_error.is_some();

            // Update icon color based on state
            if has_error != self.last_has_error || state.ea_connected != self.last_ea_connected {
                if has_error {
                    let _ = self.tray.set_icon(&self.red);
                } else if state.ea_connected {
                    let _ = self.tray.set_icon(&self.green);
                } else {
                    let _ = self.tray.set_icon(&self.yellow);
                }
                self.last_ea_connected = state.ea_connected;
                self.last_has_error = has_error;
            }

            // Build menu with error info if present
            let mut menu = MenuBuilder::new();

            if let Some(ref err) = state.last_error {
                menu = menu.item(&format!("ERROR: {}", err), TrayEvent::LeftClick);
                menu = menu.separator();
            }

            let status_text = if state.ea_connected {
                format!("EA Online v{}", state.ea_version)
            } else {
                "Waiting for EA...".to_string()
            };
            menu = menu.item(&status_text, TrayEvent::LeftClick);
            menu = menu.separator();
            menu = menu.item("Exit", TrayEvent::Exit);

            let _ = self.tray.set_menu(&menu);
        }
    }
}

// ──────────────────────────────────────────────
//  Public: run tray on main thread
// ──────────────────────────────────────────────

pub fn run_tray(state_rx: watch::Receiver<TrayState>) {
    let event_loop = EventLoop::<TrayEvent>::with_user_event().build().unwrap();
    let proxy = event_loop.create_proxy();

    let green = green_icon();
    let yellow = yellow_icon();
    let red = red_icon();

    let initial_state = state_rx.borrow().clone();
    let initial_icon = if initial_state.last_error.is_some() {
        &red
    } else if initial_state.ea_connected {
        &green
    } else {
        &yellow
    };
    let tooltip = build_tooltip(&initial_state);

    let sender_proxy = proxy.clone();
    let tray = TrayIconBuilder::new()
        .sender(move |e: &TrayEvent| {
            let _ = sender_proxy.send_event(e.clone());
        })
        .icon(initial_icon.clone())
        .tooltip(&tooltip)
        .on_click(TrayEvent::LeftClick)
        .on_right_click(TrayEvent::RightClick)
        .menu(
            MenuBuilder::new()
                .item("Waiting for EA...", TrayEvent::LeftClick)
                .separator()
                .item("Exit", TrayEvent::Exit),
        )
        .build()
        .unwrap();

    let mut app = TrayApp {
        tray,
        state_rx,
        green,
        yellow,
        red,
        last_ea_connected: initial_state.ea_connected,
        last_has_error: initial_state.last_error.is_some(),
    };

    event_loop.run_app(&mut app).unwrap();
}
