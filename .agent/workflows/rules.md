---
description: กฎการทำงาน (Development Workflow Rules) สำคัญมาก
---

# กฎการรันและพัฒนาโปรแกรม (Development Workflow Rules)

**นี่คือกฎเหล็กสำหรับโปรเจกต์นี้ ห้ามฝ่าฝืน:**

### 1. ฝั่ง Server (ea-server)
- สามารถรัน Server ในระหว่างการพัฒนาได้ด้วยคำสั่ง `cargo run` หรือรันผ่าน IDE ได้ตามปกติ
- สำหรับการแก้ไขโค้ดฝั่ง Server เพื่อขึ้น Production ยังคงสามารถนำโค้ดขึ้น GitHub เพื่อให้ระบบ CI/CD คอมไพล์และอัปเดตให้ได้

### 2. ฝั่ง Client (ea-client / Rust Desktop)
- **ในการทำงานปกติ ให้รันแค่ Client ที่เป็น Rust Desktop (Tauri) เท่านั้น**
- คำสั่งสำหรับรัน Client เพื่อพัฒนาและทดสอบ: ไปที่โฟลเดอร์ `ea-client` แล้วรันคำสั่งสำหรับ Tauri dev (เช่น `npm run tauri dev`)

### 3. กฎการจัดการเวอร์ชัน (Versioning Rules) — สำคัญมาก!

**ทุกครั้งที่ rebuild/deploy ต้องเพิ่มเวอร์ชันเสมอ** กฎนี้ใช้กับทุก component:

#### หลักการเพิ่มเวอร์ชัน:
- **อัพเดทเล็กน้อย** (แก้บั๊ก, เปลี่ยน UI เล็กน้อย, ปรับ config): **เพิ่มเลขหลังจุดทศนิยม** เช่น `0.5.3` → `0.5.4`
- **อัพเดทครั้งใหญ่** (เพิ่มฟีเจอร์ใหม่, เปลี่ยนโครงสร้าง, breaking changes): **เพิ่มเลขหน้าจุดทศนิยม** เช่น `0.5.3` → `0.6.0`

#### ไฟล์ที่ต้องอัพเดทเวอร์ชัน:

| Component | ไฟล์ที่ต้องแก้ | ตัวอย่าง |
|-----------|---------------|----------|
| **ea-server** | `ea-server/Cargo.toml` → field `version` | `version = "0.5.4"` |
| **Tauri (ea-client)** | `ea-client/src-tauri/Cargo.toml` → field `version` | `version = "0.5.4"` |
| **Tauri (ea-client)** | `ea-client/src-tauri/tauri.conf.json` → field `version` | `"version": "0.5.4"` |
| **EA (MQ5)** | `ea-server/mt5/EATradingClient.mq5` → `#property version` + `#define EA_VERSION` | `"2.06"` |
| **EA (Server ref)** | `ea-server/src/main.rs` → `LATEST_EA_VERSION` | `const LATEST_EA_VERSION: &str = "2.06";` |

#### ⚠️ หมายเหตุ:
- ea-server + Tauri ให้ใช้เวอร์ชันเดียวกัน (sync กัน)
- EA version แยกเพราะเป็น MQ5 ใช้เลขเวอร์ชัน 2 ตำแหน่ง (เช่น `2.05`)
- **ห้ามลืม bump version ก่อน build/deploy เด็ดขาด!**
