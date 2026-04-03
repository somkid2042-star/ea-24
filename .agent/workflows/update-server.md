---
description: ขั้นตอนอัพเดท ea-server เมื่อมีการแก้ไขโค้ดฝั่ง Server
---

# Workflow: อัพเดท EA-Server

**Platform:** Ubuntu 22.04 (Linux x86_64)
**Auto-Update:** ✅ Server เช็ค GitHub ทุก 2 ชม. และอัพเดทตัวเองอัตโนมัติ

---

## ระบบ Auto-Update (อัตโนมัติ)

ea-server มี **self-updater** ในตัว ที่จะ:
1. ตรวจสอบ GitHub Releases ทุก **2 ชั่วโมง** อัตโนมัติ
2. เปรียบเทียบ version (semantic versioning)
3. ดาวน์โหลด binary ใหม่จาก release
4. สลับ binary (atomic swap): `ea-server` → `ea-server-old`, `ea-server-new` → `ea-server`
5. ตรวจจับ systemd → ใช้ `systemctl restart ea-server` เพื่อ restart แบบ graceful
6. **ไม่ต้อง SSH เข้าไปทำอะไรเลย!**

### ตรวจสอบ/Trigger อัพเดทจาก Dashboard
- ส่ง WebSocket message: `{"action":"check_update"}` เพื่อเช็คทันที
- Server จะส่ง `update_status` กลับมาแจ้งสถานะ

---

## สำหรับ Developer: ขั้นตอนเพื่อ deploy เวอร์ชันใหม่

### ขั้นตอนที่ 1: Bump Version
// turbo
1. เพิ่มเวอร์ชันในไฟล์ทั้ง 3 (ให้ sync เลขเดียวกัน):
   - `ea-server/Cargo.toml` → `version = "x.y.z"`
   - `ea-client/src-tauri/Cargo.toml` → `version = "x.y.z"`
   - `ea-client/src-tauri/tauri.conf.json` → `"version": "x.y.z"`

### ขั้นตอนที่ 2: Git Commit & Push
2. Stage, commit, push พร้อม tag:
```bash
cd /Users/somkidchaihanid/Desktop/ea-24
git add -A
git commit -m "vX.Y.Z: <สรุปการเปลี่ยนแปลง>"
git tag vX.Y.Z
git push origin main --tags
```

### ขั้นตอนที่ 3: CI/CD Build
3. GitHub Actions จะ compile `ea-server` binary (Linux) อัตโนมัติ
   - Workflow: `.github/workflows/build-server.yml`
   - **Build runs on: `ubuntu-22.04`** (Linux x86_64)
   - Artifacts: `ea-server-linux` (Linux binary)
   - Release: สร้างอัตโนมัติเมื่อ push tag `v*`

### ขั้นตอนที่ 4: VPS อัพเดทตัวเอง
4. **ไม่ต้องทำอะไร!** ea-server บน VPS จะ:
   - ตรวจพบเวอร์ชันใหม่ภายใน ≤ 2 ชม.
   - ดาวน์โหลด, สลับ binary, restart อัตโนมัติ
   - หรือกด "Check Update" จาก Dashboard เพื่อ trigger ทันที

---

## ติดตั้ง VPS ครั้งแรก

```bash
# ดาวน์โหลดและรัน setup script
wget https://raw.githubusercontent.com/somkid2042-star/ea-24/main/ea-server/deploy/setup-vps.sh
sudo bash setup-vps.sh
```

### คำสั่งที่ใช้บ่อย
```bash
sudo systemctl status ea-server        # เช็คสถานะ
sudo systemctl restart ea-server       # Restart
sudo journalctl -u ea-server -f        # ดู Logs
sudo journalctl -u ea-server --since "1 hour ago"  # Logs 1 ชม. ล่าสุด
```

---

## หมายเหตุ
- **ทุกครั้งที่แก้ Server ต้อง bump version** — ห้ามลืม!
- แก้บั๊กเล็กน้อย: เพิ่ม patch (0.0.1)
- ฟีเจอร์ใหม่: เพิ่ม minor (0.1.0)
- Server กับ Client ใช้เวอร์ชันเดียวกัน
- **VPS Platform:** Ubuntu 22.04 LTS (Linux x86_64)
- **GitHub Token:** วาง `github_token.txt` ข้าง binary เพื่อ bypass rate limit (optional)
