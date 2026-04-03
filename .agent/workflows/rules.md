---
description: กฎการทำงาน (Development Workflow Rules) สำคัญมาก
---

# กฎการรันและพัฒนาโปรแกรม (Development Workflow Rules)

**นี่คือกฎเหล็กสำหรับโปรเจกต์นี้ ห้ามฝ่าฝืน:**

### 1. ฝั่ง Server (ea-server) — กฎเหล็ก!
- **การอัปเดตเซิร์ฟเวอร์ (ea-server) ต้องทำผ่าน GitHub เท่านั้น** ห้ามแก้ไขแล้วปล่อยไว้ที่เครื่อง local เด็ดขาด
- **ทุกครั้ง** ที่มีการแก้ไขโค้ดใน `ea-server` (รวมถึง `src/main.rs`, `src/db.rs`, EA `EATradingClient.mq5`, หรือไฟล์ใดๆ ภายใต้ `ea-server/`) จะต้อง:
  1. **เพิ่มเวอร์ชัน (Bump version) ใน `ea-server/Cargo.toml`** เสมอ (ตามกฎข้อ 3)
  2. **Commit และ Push ขึ้น GitHub ทันที** (`git commit -am "..." && git push origin main`)
- **เหตุผล:** เซิร์ฟเวอร์ที่รันอยู่บน VPS มีระบบ Auto-Update ที่เช็คเวอร์ชันจาก GitHub Release — ถ้าเวอร์ชันไม่เพิ่ม ระบบจะไม่รู้ว่ามีโค้ดใหม่ และจะ **ไม่ดาวน์โหลดอัปเดต**
- **ขั้นตอนหลังแก้โค้ด ea-server ทุกครั้ง:**
  1. Bump version ใน `ea-server/Cargo.toml`
  2. `git commit -am "fix/feat: ..." && git push origin main`
  3. รอ GitHub Actions คอมไพล์ Release ใหม่ (หรือกดปุ่ม "Update EA-24 Server" บน VPS)

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
