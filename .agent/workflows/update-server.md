---
description: ขั้นตอนอัพเดท ea-server เมื่อมีการแก้ไขโค้ดฝั่ง Server
---

# Workflow: อัพเดท EA-Server

**Platform:** Ubuntu 22.04 (Linux x86_64)

ทุกครั้งที่มีการแก้ไขโค้ดใน `ea-server/` จะต้องทำตามขั้นตอนนี้:

## ขั้นตอนที่ 1: Bump Version
// turbo
1. เพิ่มเวอร์ชันในไฟล์ทั้ง 3 (ให้ sync เลขเดียวกัน):
   - `ea-server/Cargo.toml` → `version = "x.y.z"`
   - `ea-client/src-tauri/Cargo.toml` → `version = "x.y.z"`
   - `ea-client/src-tauri/tauri.conf.json` → `"version": "x.y.z"`

## ขั้นตอนที่ 2: Git Commit & Push
2. Stage, commit, push พร้อม tag:
```bash
cd /Users/somkidchaihanid/Desktop/ea-24
git add -A
git commit -m "vX.Y.Z: <สรุปการเปลี่ยนแปลง>"
git tag vX.Y.Z
git push origin main --tags
```

## ขั้นตอนที่ 3: CI/CD Build
3. GitHub Actions จะ compile `ea-server` binary (Linux) อัตโนมัติ
   - Workflow: `.github/workflows/build-server.yml`
   - **Build runs on: `ubuntu-22.04`** (Linux x86_64)
   - Artifacts: `ea-server-linux` (Linux binary)
   - Release: สร้างอัตโนมัติเมื่อ push tag `v*`

## ขั้นตอนที่ 4: อัพเดท VPS (Ubuntu 22.04)
4. เมื่อ CI/CD build เสร็จ ดาวน์โหลด binary จาก GitHub Releases:
   - URL: https://github.com/somkid2042-star/ea-24/releases/latest
   - ไฟล์: `ea-server` (Linux binary, ไม่มี .exe)

5. บน VPS (Ubuntu 22.04):
```bash
# หยุด service เดิม
sudo systemctl stop ea-server

# ดาวน์โหลดไฟล์ใหม่
cd /opt/ea-24
sudo wget -O ea-server https://github.com/somkid2042-star/ea-24/releases/latest/download/ea-server
sudo chmod +x ea-server

# รีสตาร์ท service
sudo systemctl start ea-server
sudo systemctl status ea-server
```

## หมายเหตุ
- **ทุกครั้งที่แก้ Server ต้อง bump version** — ห้ามลืม!
- แก้บั๊กเล็กน้อย: เพิ่ม patch (0.0.1)
- ฟีเจอร์ใหม่: เพิ่ม minor (0.1.0)
- Server กับ Client ใช้เวอร์ชันเดียวกัน
- **VPS Platform:** Ubuntu 22.04 LTS (Linux x86_64)
- **ไม่ใช้ Windows อีกต่อไป** สำหรับ ea-server
