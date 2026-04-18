import urllib.request, json, base64

apiBase = "https://otp24hr.com/api/v1/tools/api"
secretKey = b"OTP24HRHUB_PROTECT"
deviceId = "T1RQfE1hY0ludGVsfDEwfDE2fDE3MTB4MTEwN3xBc2lhL1RhaXBlaXx0aC1USA"
licenseKey = "EXCLUSIVE-3940-6C1D-7746"

url = f"{apiBase}?action=get_cookie&key={licenseKey}&node_id=779"
req = urllib.request.Request(url, headers={
    "x-device-id": deviceId,
    "x-license-key": licenseKey,
    "User-Agent": "Mozilla/5.0"
})
res = urllib.request.urlopen(req).read()
data = json.loads(res.decode('utf-8'))
payload = data["payload"]

def js_atob(encoded):
    # standard base64 decoding with padding fix if needed
    import math
    encoded += "=" * ((4 - len(encoded) % 4) % 4)
    return base64.b64decode(encoded)

binary = js_atob(payload)
decoded = bytearray()
for i in range(len(binary)):
    decoded.append(binary[i] ^ secretKey[i % len(secretKey)])

try:
    print("Parsed JSON:", json.loads(decoded.decode('utf-8'))["target_url"])
except Exception as e:
    print("Error:", e)
    print("First 100 chars:", decoded[:100])
