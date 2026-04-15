import json
import re
import requests

swift_file = "Cashflow/Models/OTP24Models.swift"
with open(swift_file, 'r') as f:
    content = f.read()

# Extract json
try:
    json_str_match = re.search(r'static let jsonString = """\n(.*?)\n"""', content, re.DOTALL)
    if not json_str_match:
        print("Failed to find JSON string.")
        exit(1)
    
    data = json.loads(json_str_match.group(1))
    cookies_list = data.get("cookies", [])
    
    session = requests.Session()
    session.headers.update({
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.5',
    })
    
    print(f"Loaded {len(cookies_list)} cookies.")
    for c in cookies_list:
        domain = c.get('domains', '')
        if domain.startswith('.'):
            domain = domain[1:]
        session.cookies.set(c['name'], c['value'], domain=domain)
        
    print("Testing against https://www.netflix.com/browse...")
    response = session.get("https://www.netflix.com/browse", allow_redirects=False)
    
    if response.status_code == 302:
        loc = response.headers.get("Location", "")
        if "login" in loc or "clearcookies" in loc.lower():
            print(f"❌ Cookies have EXPIRED or are INVALID! Redirected to: {loc}")
        else:
            print(f"⚠️ Redirected to: {loc}")
    elif response.status_code == 200:
        if "profile-icon" in response.text or "SignOut" in response.text or "user-account" in response.text or "profiles-gate" in response.text:
            print("✅ Cookies are still VALID! Successfully accessed Netflix Browse or Profiles page.")
        else:
            if "Sign In" in response.text:
                print("❌ Cookies have EXPIRED or are INVALID! (Got 200 but see 'Sign In' button)")
            else:
                print("❓ Cannot conclusively determine. Status 200, but couldn't find profile indicators.")
    else:
        print(f"Unknown status: {response.status_code}")
except Exception as e:
    print(f"Error: {e}")
