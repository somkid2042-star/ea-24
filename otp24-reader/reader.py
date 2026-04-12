import urllib.request
import json
import base64

SECRET_KEY = "OTP24HRHUB_PROTECT"
API_BASE = "https://otp24hr.com/api/v1/tools/api"

def decode_data(encoded_str, key):
    # 1. ถอดรหัส Base64 เป็น Bytes
    binary_data = base64.b64decode(encoded_str)
    
    # 2. นำข้อมูลมาเข้าสมการ XOR กับ Key ของเรา
    decoded_bytes = bytearray()
    for i in range(len(binary_data)):
        decoded_bytes.append(binary_data[i] ^ ord(key[i % len(key)]))
        
    # 3. แปลง Bytes เป็น Text (UTF-8)
    return decoded_bytes.decode('utf-8')

def run():
    print("=========================================")
    print("🚀 Starting OTP24 Data Reader App (Python)...")
    print("=========================================\n")

    # ทดลองเรียก Action: check_version หรือ action อื่นๆ
    url = f"{API_BASE}?action=check_version"
    print(f"📡 Fetching API Endpoint: {url}")
    
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode('utf-8'))
            
            if 'payload' in data:
                print("\n✅ Success! Received encrypted Base64 payload.")
                print("🛡️  Decrypting using Secret Key...\n")
                
                real_data = decode_data(data['payload'], SECRET_KEY)
                parsed_data = json.loads(real_data)
                
                print("📦 --- DECODED DATA ---")
                print(json.dumps(parsed_data, indent=2, ensure_ascii=False))
                print("------------------------\n")
                
                # ถ้ามี UI HTML ให้เซฟลงไฟล์แล้วเปิดให้ดู
                if 'ui_html' in parsed_data:
                    with open("ui_preview.html", "w", encoding="utf-8") as f:
                        f.write(parsed_data['ui_html'])
                    print("🌐 บันทึกหน้า UI เป็นไฟล์ ui_preview.html แล้ว! กำลังเปิดในเบราว์เซอร์...")
                    import os
                    os.system("open ui_preview.html")
                
    except Exception as e:
        print(f"\n❌ Error fetching data: {e}")

if __name__ == "__main__":
    run()
