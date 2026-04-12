use dirs::home_dir;
use rusqlite::{Connection, Result, OpenFlags};
use std::fs;
use std::path::PathBuf;

fn find_orion_extension_storage() -> Option<PathBuf> {
    if let Some(mut path) = home_dir() {
        path.push("Library/Application Support/Orion/Defaults/Local Storage/Extensions");
        
        println!("🔍 ค้นหาใน: {:?}", path);
        
        if path.exists() {
            if let Ok(entries) = fs::read_dir(&path) {
                for entry in entries.flatten() {
                    let mut store_path = entry.path();
                    store_path.push("Store");
                    
                    if store_path.exists() && store_path.is_file() {
                        // เปิดแบบ Read Only เพื่อกันไม่ให้ติด Lock
                        if let Ok(conn) = Connection::open_with_flags(&store_path, OpenFlags::SQLITE_OPEN_READ_ONLY) {
                            if let Ok(mut stmt) = conn.prepare("SELECT KEY, OBJECT FROM STORAGE") {
                                if let Ok(iter) = stmt.query_map([], |row| {
                                    Ok((row.get::<_, String>(0)?, row.get::<_, String>(1)?))
                                }) {
                                    for row in iter.flatten() {
                                        if row.0 == "csrf_token" || row.0 == "device_id" || row.1.contains("T1RQ") {
                                            return Some(store_path);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    None
}

fn main() -> Result<()> {
    println!("🔍 กำลังค้นหาฐานข้อมูล Orion Extension ของ OTP24...");

    match find_orion_extension_storage() {
        Some(db_path) => {
            println!("✅ พบไฟล์ฐานข้อมูลที่: {:?}", db_path);
            
            let conn = Connection::open_with_flags(&db_path, OpenFlags::SQLITE_OPEN_READ_ONLY)?;
            
            println!("\n📦 === ข้อมูลใน Local Storage ของ Extension ===");
            let mut stmt = conn.prepare("SELECT KEY, OBJECT, TYPE FROM STORAGE")?;
            
            let rows = stmt.query_map([], |row| {
                Ok((
                    row.get::<_, String>(0)?, 
                    row.get::<_, String>(1)?,
                    row.get::<_, String>(2)?
                ))
            })?;

            for row in rows {
                if let Ok((key, value, row_type)) = row {
                    println!("🔑 Key: {}", key);
                    println!("📄 Value: {}", value);
                    println!("🏷  Type: {}", row_type);
                    println!("--------------------------------------");
                    
                    if key == "device_id" {
                        if let Ok(decoded) = base64::Engine::decode(&base64::engine::general_purpose::STANDARD, value.as_bytes()) {
                            if let Ok(decoded_str) = String::from_utf8(decoded) {
                                println!("✨ [Decoded Device ID]: {}\n", decoded_str);
                            }
                        }
                    }
                }
            }
        }
        None => {
            println!("❌ ไม่พบฐานข้อมูล หรือ Extension ยังไม่ได้เก็บข้อมูล (ลองล็อกอินใน Extension ก่อน)");
        }
    }

    Ok(())
}
