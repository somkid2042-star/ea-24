---
description: กฎการทำงาน (Development Workflow Rules) สำคัญมาก
---

# กฎการรันและพัฒนาโปรแกรม (Development Workflow Rules)

**นี่คือกฎเหล็กสำหรับโปรเจกต์นี้ ห้ามฝ่าฝืน:**

### 1. ฝั่ง Server (ea-server)
- **ห้ามรัน Server ใน IDE เด็ดขาด** (ไม่ต้องใช้คำสั่ง `cargo run` สำหรับ ea-server)
- ให้ใช้ `ea-server.exe` จากตัวติดตั้ง (Installer) ที่โหลดมาจาก GitHub ซึ่งปัจจุบันติดตั้งและรันอยู่เป็น Background process แล้ว
- **ถ้ามีการแก้ไขโค้ดฝั่ง Server:** ต้อง Push ขึ้น GitHub ทันที เพื่อให้ GitHub Actions คอมไพล์ จากนั้นปล่อยให้ "ระบบ Auto Update" โหลดตัวใหม่มาติดตั้งบนเครื่องโดยอัตโนมัติ

### 2. ฝั่ง Client (ea-client / Rust Desktop)
- **ในการทำงานปกติ ให้รันแค่ Client ที่เป็น Rust Desktop (Tauri) เท่านั้น**
- คำสั่งสำหรับรัน Client เพื่อพัฒนาและทดสอบ: ไปที่โฟลเดอร์ `ea-client` แล้วรันคำสั่งสำหรับ Tauri dev (เช่น `npm run tauri dev`)
