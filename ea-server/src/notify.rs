use log::info;

/// Send a LINE Notify message
pub async fn send_line_notify(token: &str, message: &str) -> bool {
    if token.is_empty() {
        return false;
    }
    let client = reqwest::Client::new();
    match client
        .post("https://notify-api.line.me/api/notify")
        .header("Authorization", format!("Bearer {}", token))
        .form(&[("message", message)])
        .send()
        .await
    {
        Ok(resp) => {
            let ok = resp.status().is_success();
            if !ok {
                info!("⚠️ LINE Notify failed: status {}", resp.status());
            }
            ok
        }
        Err(e) => {
            info!("⚠️ LINE Notify error: {}", e);
            false
        }
    }
}

/// Format trade open notification
pub fn format_trade_open(symbol: &str, direction: &str, lot: f64, price: f64, strategy: &str) -> String {
    format!(
        "\n🟢 เปิดออเดอร์ใหม่\n📊 {} {} {:.2} lot\n💰 ราคา: {:.5}\n🎯 กลยุทธ์: {}\n⏰ {}",
        symbol, 
        if direction == "BUY" { "ซื้อ" } else { "ขาย" },
        lot, price, strategy,
        chrono::Local::now().format("%H:%M:%S %d/%m/%Y")
    )
}

/// Format trade close notification  
pub fn format_trade_close(symbol: &str, direction: &str, lot: f64, pnl: f64) -> String {
    let emoji = if pnl >= 0.0 { "🟢" } else { "🔴" };
    format!(
        "\n{} ปิดออเดอร์\n📊 {} {} {:.2} lot\n💵 กำไร/ขาดทุน: {}{:.2} $\n⏰ {}",
        emoji, symbol, 
        if direction == "BUY" { "ซื้อ" } else { "ขาย" },
        lot, if pnl >= 0.0 { "+" } else { "" }, pnl,
        chrono::Local::now().format("%H:%M:%S %d/%m/%Y")
    )
}

/// Format EA disconnect notification
pub fn format_ea_disconnect() -> String {
    format!(
        "\n⚠️ EA หลุดการเชื่อมต่อ!\n🔌 MT5 ไม่ตอบสนอง\n⏰ {}",
        chrono::Local::now().format("%H:%M:%S %d/%m/%Y")
    )
}

/// Format daily summary
pub fn format_daily_summary(profit: f64, trades: i64, win_rate: f64) -> String {
    let emoji = if profit >= 0.0 { "📈" } else { "📉" };
    format!(
        "\n{} สรุปผลประจำวัน\n💰 กำไร/ขาดทุน: {}{:.2} $\n📊 จำนวนเทรด: {} ออเดอร์\n🎯 Win Rate: {:.1}%\n⏰ {}",
        emoji, if profit >= 0.0 { "+" } else { "" }, profit,
        trades, win_rate,
        chrono::Local::now().format("%d/%m/%Y")
    )
}

/// Format risk alert
pub fn format_risk_alert(drawdown: f64, max_dd: f64) -> String {
    format!(
        "\n🚨 แจ้งเตือนความเสี่ยง!\n📉 Drawdown วันนี้: {:.2} $\n⛔ ขีดจำกัด: {:.2} $\n🛑 หยุดเทรดอัตโนมัติ\n⏰ {}",
        drawdown, max_dd,
        chrono::Local::now().format("%H:%M:%S %d/%m/%Y")
    )
}
