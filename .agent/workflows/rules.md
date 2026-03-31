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
