#!/usr/bin/env python3
"""
OTP24 Netflix Cookie Injector via Chrome CDP
- เปิด Chrome ในโหมด Debug
- ฉีด Cookie ผ่าน CDP (รวม HttpOnly)
- เปิดหน้า Netflix Premium อัตโนมัติ
"""

import base64, json, urllib.request, urllib.parse, http.cookiejar
import subprocess, time, socket, os, signal

SECRET_KEY = 'OTP24HRHUB_PROTECT'
API_BASE = 'https://otp24hr.com/api/v1/tools/api'
DEVICE = 'T1RQfE1hY0ludGVsfDEwfDE2fDE3MTB4MTEwN3xBc2lhL1RhaXBlaXx0aC1USA'
KEY = 'EXCLUSIVE-3940-6C1D-7746'
CDP_PORT = 9222

def xor_decode(s, k):
    d = base64.b64decode(s)
    return bytes([b ^ ord(k[i % len(k)]) for i, b in enumerate(d)]).decode('utf-8', errors='replace')

# === STEP 1: ดึง Cookie จาก API ===
print("🔐 [1/4] Login & ดึง Cookie จาก OTP24...")

cj = http.cookiejar.CookieJar()
opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cj))
csrf = ''

def api(action, params=None, post=None):
    global csrf
    url = f'{API_BASE}?action={action}'
    if params: url += '&' + urllib.parse.urlencode(params)
    body = urllib.parse.urlencode(post).encode() if post else None
    req = urllib.request.Request(url, data=body, method='POST' if body else 'GET')
    req.add_header('User-Agent', 'Mozilla/5.0')
    req.add_header('x-device-id', DEVICE)
    req.add_header('x-license-key', KEY)
    if csrf: req.add_header('x-csrf-token', csrf)
    res = opener.open(req, timeout=10)
    t = res.headers.get('x-csrf-token')
    if t: csrf = t
    return json.loads(res.read().decode())

# Login
r = api('login', None, {'key': KEY, 'device_id': DEVICE})
d = json.loads(xor_decode(r['payload'], SECRET_KEY))
print(f"   ✅ Login OK | Quota: {d['used_today']}/{d['daily_limit']}")

# Get nodes
r2 = api('get_nodes', {'app_id': '26', 'key': KEY})
nodes = json.loads(xor_decode(r2['payload'], SECRET_KEY))
avail = [n for n in nodes if n.get('can_access') and n.get('is_working')]
node = avail[0]
print(f"   ✅ Server: {node['server_name']}")

# Get cookie
r3 = api('get_cookie', {'node_id': str(node['id']), 'key': KEY})
cookie_data = json.loads(xor_decode(r3['payload'], SECRET_KEY))
target_url = cookie_data['target_url']
cookies = cookie_data['cookies']
print(f"   ✅ ได้ {len(cookies)} cookies | Target: {target_url}")

# === STEP 2: เปิด Chrome ในโหมด Debug ===
print(f"\n🌐 [2/4] เปิด Chrome (Debug Port {CDP_PORT})...")

# ปิด Chrome เก่าก่อน (ถ้ามี)
subprocess.run(['pkill', '-f', 'Google Chrome'], capture_output=True)
time.sleep(1)

# เปิด Chrome ใหม่พร้อม remote debugging
chrome_path = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
profile_dir = '/tmp/otp24-chrome-profile'
os.makedirs(profile_dir, exist_ok=True)

chrome_proc = subprocess.Popen([
    chrome_path,
    f'--remote-debugging-port={CDP_PORT}',
    f'--user-data-dir={profile_dir}',
    '--no-first-run',
    '--no-default-browser-check',
    '--remote-allow-origins=*',
    'about:blank'
], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

# รอ Chrome เปิด
for i in range(15):
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(1)
        s.connect(('127.0.0.1', CDP_PORT))
        s.close()
        break
    except:
        time.sleep(1)
else:
    print("❌ Chrome ไม่เปิด!")
    exit(1)

print("   ✅ Chrome พร้อมแล้ว")

# === STEP 3: ฉีด Cookie ผ่าน CDP ===
print(f"\n🍪 [3/4] ฉีด Cookie {len(cookies)} ตัว...")

import websocket

# ดึง WebSocket URL จาก CDP
cdp_info = json.loads(urllib.request.urlopen(f'http://127.0.0.1:{CDP_PORT}/json').read())
ws_url = cdp_info[0]['webSocketDebuggerUrl']

ws = websocket.create_connection(ws_url)
msg_id = 1

def cdp_send(method, params=None):
    global msg_id
    msg = {"id": msg_id, "method": method}
    if params: msg["params"] = params
    ws.send(json.dumps(msg))
    msg_id += 1
    return json.loads(ws.recv())

# นำทางไป netflix.com ก่อน (เพื่อให้ Cookie domain ตรง)
cdp_send("Page.navigate", {"url": "https://www.netflix.com"})
time.sleep(3)

# ฉีด Cookie ทีละตัว!
injected = 0
for c in cookies:
    domain = c.get('domain', c.get('domains', '.netflix.com'))
    
    cookie_params = {
        "name": c['name'],
        "value": c.get('value', ''),
        "domain": domain,
        "path": c.get('path', '/'),
        "secure": bool(c.get('secure', False)),
        "httpOnly": bool(c.get('httpOnly', False)),
    }
    
    # ตั้งวันหมดอายุ 1 ปีข้างหน้า
    cookie_params["expires"] = time.time() + 86400 * 365
    
    result = cdp_send("Network.setCookie", cookie_params)
    if result.get('result', {}).get('success', False):
        injected += 1
        flag = "🔒" if c.get('httpOnly') else "🍪"
        print(f"   {flag} {c['name']}: OK")
    else:
        print(f"   ❌ {c['name']}: FAILED - {result}")

print(f"\n   ✅ ฉีดสำเร็จ {injected}/{len(cookies)} cookies")

# === STEP 4: เปิดหน้า Netflix! ===
print(f"\n🎬 [4/4] เปิด Netflix Premium...")
cdp_send("Page.navigate", {"url": target_url})

ws.close()
print(f"\n🎉 เสร็จสิ้น! ดูหน้า Chrome ได้เลยครับ")
