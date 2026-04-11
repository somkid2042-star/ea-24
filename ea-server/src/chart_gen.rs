// ──────────────────────────────────────────────
//  Chart Generator: สร้างกราฟ Candlestick จาก candle data
//  ส่งเป็น PNG bytes สำหรับแนบไป Discord
// ──────────────────────────────────────────────

use plotters::prelude::*;
use plotters_bitmap::BitMapBackend;
use crate::strategy::Candle;

/// Generate a candlestick chart as PNG bytes
pub fn generate_candlestick_chart(
    symbol: &str,
    candles: &[Candle],
    direction: &str,
    strategy: &str,
    timeframe: &str,
    score: f64,
) -> Option<Vec<u8>> {
    if candles.len() < 5 { return None; }

    let width = 800u32;
    let height = 400u32;

    let mut buf = vec![0u8; (width * height * 3) as usize];

    {
        let root = BitMapBackend::with_buffer(&mut buf, (width, height))
            .into_drawing_area();
        root.fill(&RGBColor(13, 16, 32)).ok()?; // Dark background

        let min_price = candles.iter().map(|c| c.low).fold(f64::MAX, f64::min);
        let max_price = candles.iter().map(|c| c.high).fold(f64::MIN, f64::max);
        let price_margin = (max_price - min_price) * 0.05;
        let y_min = min_price - price_margin;
        let y_max = max_price + price_margin;

        let n = candles.len();

        // Title
        let dir_color = if direction == "BUY" { RGBColor(34, 197, 94) } else { RGBColor(239, 68, 68) };
        let title = format!(
            "{} | {} {} | {} ({}) | Score {:.0}%",
            symbol, direction, symbol, strategy, timeframe, score
        );

        let mut chart = ChartBuilder::on(&root)
            .caption(title, ("monospace", 14).into_font().color(&WHITE))
            .margin(10)
            .x_label_area_size(25)
            .y_label_area_size(60)
            .build_cartesian_2d(0..n, y_min..y_max)
            .ok()?;

        chart.configure_mesh()
            .label_style(("monospace", 10).into_font().color(&RGBColor(150, 150, 150)))
            .axis_style(RGBColor(40, 40, 60))
            .light_line_style(RGBColor(25, 28, 45))
            .disable_x_mesh()
            .draw().ok()?;

        // Draw candles
        chart.draw_series(candles.iter().enumerate().map(|(i, c)| {
            let is_bull = c.close >= c.open;
            let color = if is_bull { RGBColor(34, 197, 94) } else { RGBColor(239, 68, 68) };

            // Wick (high-low line)
            let wick = PathElement::new(
                vec![(i, c.low), (i, c.high)],
                color.stroke_width(1),
            );

            // Body
            let body_top = if is_bull { c.close } else { c.open };
            let body_bot = if is_bull { c.open } else { c.close };
            let body = Rectangle::new(
                [(i.saturating_sub(0), body_bot), (i + 1, body_top)],
                color.filled(),
            );

            // Return wick first, then body on top
            std::iter::once(wick).chain(std::iter::once(
                PathElement::new(vec![(i, body_bot), (i, body_top)], color.filled().stroke_width(3))
            ))
        }).flatten()).ok()?;

        // Draw signal arrow on last candle
        let last = candles.last()?;
        let arrow_y = if direction == "BUY" { last.low - price_margin * 0.3 } else { last.high + price_margin * 0.3 };
        chart.draw_series(std::iter::once(
            TriangleMarker::new((n - 1, arrow_y), 8, dir_color.filled())
        )).ok()?;

        // Entry price line
        let entry_price = last.close;
        chart.draw_series(std::iter::once(
            PathElement::new(
                vec![(0, entry_price), (n - 1, entry_price)],
                dir_color.stroke_width(1),
            )
        )).ok()?;

        root.present().ok()?;
    }

    // Encode to PNG
    let mut png_buf = Vec::new();
    {
        let mut encoder = image_encoder(width, height, &buf)?;
        encoder.encode_to(&mut png_buf);
    }
    
    Some(png_buf)
}

/// Simple PNG encoder from raw RGB buffer
fn image_encoder(width: u32, height: u32, rgb_buf: &[u8]) -> Option<PngEncoder> {
    Some(PngEncoder { width, height, data: rgb_buf.to_vec() })
}

struct PngEncoder {
    width: u32,
    height: u32,
    data: Vec<u8>,
}

impl PngEncoder {
    fn encode_to(&self, out: &mut Vec<u8>) {
        // Use a minimal BMP format that Discord can display
        // BMP Header (54 bytes) + pixel data
        let row_size = ((self.width * 3 + 3) / 4) * 4; // row must be 4-byte aligned
        let pixel_data_size = row_size * self.height;
        let file_size = 54 + pixel_data_size;
        
        // BMP File Header (14 bytes)
        out.extend_from_slice(b"BM");
        out.extend_from_slice(&(file_size as u32).to_le_bytes());
        out.extend_from_slice(&[0u8; 4]); // reserved
        out.extend_from_slice(&54u32.to_le_bytes()); // pixel data offset
        
        // BMP Info Header (40 bytes)
        out.extend_from_slice(&40u32.to_le_bytes()); // header size
        out.extend_from_slice(&(self.width as i32).to_le_bytes());
        out.extend_from_slice(&(-(self.height as i32)).to_le_bytes()); // negative = top-down
        out.extend_from_slice(&1u16.to_le_bytes()); // planes
        out.extend_from_slice(&24u16.to_le_bytes()); // bits per pixel
        out.extend_from_slice(&[0u8; 24]); // compression + rest of header
        
        // Pixel data (RGB → BGR for BMP, row-padded)
        for y in 0..self.height {
            for x in 0..self.width {
                let i = ((y * self.width + x) * 3) as usize;
                if i + 2 < self.data.len() {
                    out.push(self.data[i + 2]); // B
                    out.push(self.data[i + 1]); // G
                    out.push(self.data[i]);     // R
                } else {
                    out.extend_from_slice(&[0, 0, 0]);
                }
            }
            // Row padding
            let padding = (row_size - self.width * 3) as usize;
            for _ in 0..padding {
                out.push(0);
            }
        }
    }
}
