import tkinter as tk
from tkinter import ttk, messagebox
from tkinter.scrolledtext import ScrolledText
import urllib.request
import urllib.parse
import json
import base64
import os
import threading

SECRET_KEY = "OTP24HRHUB_PROTECT"
API_BASE = "https://otp24hr.com/api/v1/tools/api"

# Default Device ID ที่เราแฮกมาได้จากเครื่อง
DEFAULT_DEVICE_ID = "T1RQfE1hY0ludGVsfDEwfDE2fDE3MTB4MTEwN3xBc2lhL1RhaXBlaXx0aC1USA"

def decode_data(encoded_str, key):
    try:
        binary_data = base64.b64decode(encoded_str)
        decoded_bytes = bytearray()
        for i in range(len(binary_data)):
            decoded_bytes.append(binary_data[i] ^ ord(key[i % len(key)]))
        return decoded_bytes.decode('utf-8')
    except Exception as e:
        return f"Decode Error: {e}"

class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("OTP24 Advanced Explorer (Auto-Login Edition)")
        self.geometry("900x700")
        self.configure(bg="#1E1E1E")
        
        # Storage สำหรับเก็บ Token และ Key
        self.csrf_token = ""
        self.license_key = ""
        self.device_id = DEFAULT_DEVICE_ID
        
        style = ttk.Style(self)
        style.theme_use('default')
        style.configure("TLabel", background="#1E1E1E", foreground="#FFFFFF", font=("Kanit", 12))
        
        # --- Auth Panel (บนสุด) ---
        auth_frame = tk.Frame(self, bg="#252526", pady=10, padx=15)
        auth_frame.pack(fill=tk.X, padx=15, pady=(15, 5))
        
        ttk.Label(auth_frame, text="Device ID:", background="#252526").pack(side=tk.LEFT, padx=5)
        self.device_entry = tk.Entry(auth_frame, width=15, bg="#3C3C3C", fg="white", insertbackground="white", font=("Kanit", 10))
        self.device_entry.insert(0, self.device_id)
        self.device_entry.pack(side=tk.LEFT, padx=5)
        
        self.login_btn = tk.Button(auth_frame, text="🔑 1. Auto Login", bg="#E91E63", fg="white",
                                   activebackground="#C2185B", activeforeground="white",
                                   command=self.on_login, font=("Kanit", 12, "bold"), borderwidth=0, padx=10, pady=2)
        self.login_btn.pack(side=tk.LEFT, padx=15)
        
        self.token_label = ttk.Label(auth_frame, text="CSRF Token: Not Set", foreground="#FFD700", background="#252526")
        self.token_label.pack(side=tk.RIGHT, padx=5)

        # --- Request Panel (กลาง) ---
        req_frame = tk.Frame(self, bg="#2D2D30", pady=15, padx=15)
        req_frame.pack(fill=tk.X, padx=15, pady=5)
        
        ttk.Label(req_frame, text="API Action:", background="#2D2D30").pack(side=tk.LEFT, padx=5)
        
        self.action_var = tk.StringVar(value="check_auth")
        self.action_entry = tk.Entry(req_frame, textvariable=self.action_var, 
                                     font=("Kanit", 13), width=20, bg="#3C3C3C", fg="white", insertbackground="white")
        self.action_entry.pack(side=tk.LEFT, padx=5)
        
        self.fetch_btn = tk.Button(req_frame, text="⚡️ 2. Fetch Data", bg="#007ACC", fg="white", 
                                   activebackground="#005C99", activeforeground="white",
                                   command=self.on_fetch, font=("Kanit", 13, "bold"), borderwidth=0, padx=15, pady=2)
        self.fetch_btn.pack(side=tk.LEFT, padx=10)
        
        self.preview_btn = tk.Button(req_frame, text="🌐 Preview HTML", bg="#FF8C33", fg="white", 
                                     command=self.preview_html, state=tk.DISABLED, 
                                     font=("Kanit", 13, "bold"), borderwidth=0, padx=15, pady=2)
        self.preview_btn.pack(side=tk.LEFT, padx=5)

        # --- Output Display (ล่าง) ---
        self.output_text = ScrolledText(self, bg="#0D0D0D", fg="#4AF626", font=("Menlo", 12), 
                                        wrap=tk.WORD, insertbackground="white", padx=10, pady=10)
        self.output_text.pack(fill=tk.BOTH, expand=True, padx=15, pady=(5, 15))
        
        self.current_parsed_data = None
        self.log("🚀 Welcome to OTP24 Advanced Explorer (HACKER EDITION)")
        self.log("-----------------------------------------")
        self.log("ระบบพร้อมแล้ว! กรุณากดปุ่ม 🔑 '1. Auto Login'")
        self.log("เพื่อให้ระบบปลอมตัวเป็นเบราว์เซอร์ไปขโมย Token มาแปะไว้ก่อน\n")

    def log(self, msg):
        self.output_text.insert(tk.END, str(msg) + "\n")
        self.output_text.see(tk.END)
        
    def _create_request(self, url, method="GET", data=None):
        # ฟังก์ชันเตรียม Request ที่แนบทุกอย่างเหมือน Extension เลย
        req = urllib.request.Request(url, method=method)
        req.add_header('User-Agent', 'Mozilla/5.0')
        req.add_header('x-device-id', self.device_id)
        
        if self.csrf_token:
            req.add_header('x-csrf-token', self.csrf_token)
        if self.license_key:
            req.add_header('x-license-key', self.license_key)
            
        if data:
            encoded_data = urllib.parse.urlencode(data).encode('utf-8')
            req.data = encoded_data
            
        return req

    def process_response(self, response):
        # ระบบดูดคุกกี้ / Header อัตโนมัติทุกครั้งที่ยิง
        new_token = response.headers.get('x-csrf-token')
        if new_token:
            self.csrf_token = new_token
            self.token_label.config(text=f"CSRF: {self.csrf_token[:12]}...")
            self.log(f"🔑 [SYSTEM] ดูด CSRF Token สำเร็จ!")

    def on_login(self):
        self.device_id = self.device_entry.get().strip()
        if not self.device_id: return
        self.login_btn.config(state=tk.DISABLED, text="⏳ Logging In...")
        threading.Thread(target=self.do_login, daemon=True).start()

    def do_login(self):
        self.log(f"🛡️ [AUTH] ยิงระบบ Login ด้วย Device ID: {self.device_id[:8]}...")
        url = f"{API_BASE}?action=login_by_device"
        try:
            req = self._create_request(url, method="POST", data={'device_id': self.device_id})
            with urllib.request.urlopen(req) as res:
                self.process_response(res) # เก็บ Token ที่ได้
                rj = json.loads(res.read().decode('utf-8'))
                
                if 'payload' in rj:
                    dec = decode_data(rj['payload'], SECRET_KEY)
                    dt = json.loads(dec)
                    self.log(f"✅ Login สำเร็จ!")
                    
                    if 'license_key' in dt:
                        self.license_key = dt['license_key']
                        self.log(f"🎫 ได้ຮັບ License Key หลัก: {self.license_key}")
                        self.log(f"พร้อมเจาะข้อมูลแล้ว! ลองพิมพ์คำสั่ง 'check_auth' หรือ 'get_packages' แล้วกด Fetch ดูครับ\n")
                else:
                    self.log(f"❌ Login ตอบกลับแบบไม่มี Payload (อาจจะโดนแบน หรือรหัสผิด): {rj}")
        except Exception as e:
            self.log(f"❌ Login ร่ม Error: {e}")
            
        self.login_btn.config(state=tk.NORMAL, text="🔑 1. Auto Login")
            
    def on_fetch(self):
        action = self.action_var.get().strip()
        if not action: return
        self.fetch_btn.config(state=tk.DISABLED, text="⏳ Fetching...")
        threading.Thread(target=self.do_fetch, args=(action,), daemon=True).start()
        
    def do_fetch(self, action):
        self.log(f"\n📡 Requesting Action: {action}...")
        self.preview_btn.config(state=tk.DISABLED)
        
        url = f"{API_BASE}?action={action}"
        
        # จำลองการแนบ ?key=XXX แบบที่เซิร์ฟเวอร์หลักบังคับให้มี
        if self.license_key:
            url += f"&key={self.license_key}"
            
        try:
            # ใช้ POST สำหรับ action ที่สำคัญ (หลายอันบังคับ POST เช่น check_auth)
            req = self._create_request(url, method="POST", data={'key': self.license_key, 'device_id': self.device_id})
            with urllib.request.urlopen(req) as res:
                self.process_response(res)
                rj = json.loads(res.read().decode('utf-8'))
                
                if 'payload' in rj:
                    real = decode_data(rj['payload'], SECRET_KEY)
                    parsed = json.loads(real)
                    self.current_parsed_data = parsed
                    self.log("📦 --- DECRYPTED DATA ---")
                    self.log(json.dumps(parsed, indent=2, ensure_ascii=False))
                    self.log("--------------------------")
                    
                    if 'ui_html' in parsed:
                        self.preview_btn.config(state=tk.NORMAL)
                else:
                    self.log(f"❌ เซิร์ฟเวอร์เตะออก หรือไม่มี Payload: {json.dumps(rj, indent=2)}")
        except urllib.error.HTTPError as e:
            err_msg = e.read().decode('utf-8')
            self.log(f"❌ Backend ปฏิเสธ (HTTP Error): {err_msg}")
        except Exception as e:
            self.log(f"❌ Fetch Error ทั่วไป: {e}")
            
        self.fetch_btn.config(state=tk.NORMAL, text="⚡️ 2. Fetch Data")

    def preview_html(self):
        if self.current_parsed_data and 'ui_html' in self.current_parsed_data:
            path = os.path.join(os.getcwd(), "ui_preview.html")
            with open(path, "w", encoding="utf-8") as f:
                f.write(self.current_parsed_data['ui_html'])
            os.system(f"open '{path}'")
            self.log("\n🌐 เปิดหน้าต่าง UI Preview ในเบราว์เซอร์แล้ว!")

if __name__ == "__main__":
    app = App()
    app.mainloop()
