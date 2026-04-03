---
description: ขั้นตอนอัพเดท ea-server เมื่อมีการแก้ไขโค้ดฝั่ง Server
---
# วิธีอัปเดตเซิร์ฟเวอร์แบบแมนนวลผ่าน VPS

เนื่องจากระบบ Auto-Update ของเซิร์ฟเวอร์ติดปัญหาชนกันของ Github Actions เราสามารถสร้างปุ่มลัด (Shortcut) สำหรับกดอัปเดตเองได้

1. เปิดหน้าจอ Terminal บน VPS (Ubuntu)
2. ก๊อปปี้คำสั่งด้านล่างนี้ไปวาง แล้วกด Enter:
```bash
cat << 'DESKTOP' > ~/Desktop/Update\ EA24.desktop
[Desktop Entry]
Version=1.0
Name=Update EA-24 Server
Comment=Pull and update the latest ea-server
Exec=gnome-terminal -- bash -c "echo '🚀 ดึงข้อมูลอัปเดตล่าสุด...'; sudo curl -L https://raw.githubusercontent.com/somkid2042-star/ea-24/main/ea-server/deploy/setup-vps.sh -o /tmp/setup-vps.sh && sudo chmod +x /tmp/setup-vps.sh && sudo bash /tmp/setup-vps.sh; echo '✅ เสร็จสิ้น! กดปุ่มใดๆ เพื่อปิดหน้าต่าง'; read -n 1"
Icon=system-software-update
Terminal=false
Type=Application
Categories=Utility;
DESKTOP
chmod +x ~/Desktop/Update\ EA24.desktop
```
3. ดับเบิ้ลคลิกที่ไอคอน **"Update EA24"** บนหน้าจอ Desktop ของ VPS มันจะทำการดึงอัปเดตมาติดตั้งและหลุดออกจาก Loop ให้ทันทีครับ!
