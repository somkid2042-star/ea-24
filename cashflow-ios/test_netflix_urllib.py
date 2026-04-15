import json
import re
import urllib.request
import urllib.parse
from http.cookiejar import CookieJar, Cookie

swift_file = "Cashflow/Models/OTP24Models.swift"
with open(swift_file, 'r') as f:
    content = f.read()

json_str_match = re.search(r'static let jsonString = """\n(.*?)\n"""', content, re.DOTALL)
if not json_str_match:
    print("Failed to find JSON string.")
    exit(1)

data = json.loads(json_str_match.group(1))
cookies_list = data.get("cookies", [])

cj = CookieJar()
for c in cookies_list:
    domain = c.get('domains', '')
    if domain.startswith('.'):
        domain = domain[1:]
    
    cookie = Cookie(version=0, name=c['name'], value=c['value'], port=None, port_specified=False, domain=domain, domain_specified=True, domain_initial_dot=False, path=c.get('path', '/'), path_specified=True, secure=c.get('secure', False), expires=c.get('ExpiresDate', None), discard=False, comment=None, comment_url=None, rest={'HttpOnly': c.get('httpOnly', False)}, rfc2109=False)
    cj.set_cookie(cookie)

opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cj))
opener.addheaders = [
    ('User-Agent', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36'),
    ('Accept', 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8')
]

print("Testing against https://www.netflix.com/browse...")
try:
    response = opener.open("https://www.netflix.com/browse")
    html = response.read().decode('utf-8')
    if "profile-icon" in html or "SignOut" in html or "user-account" in html or "profiles-gate" in html:
        print("✅ Cookies are still VALID! Successfully accessed Netflix Browse or Profiles page.")
    elif "Sign In" in html:
        print("❌ Cookies have EXPIRED or are INVALID! (Got 200 but see 'Sign In' button)")
    else:
        print("❓ Cannot conclusively determine. Status 200, but couldn't find profile indicators.")
    
except urllib.error.HTTPError as e:
    if e.code == 302 or e.code == 301:
        loc = e.headers.get("Location", "")
        if "login" in loc or "clearcookies" in loc.lower():
            print(f"❌ Cookies have EXPIRED or are INVALID! Redirected to: {loc}")
        else:
            print(f"⚠️ Redirected to: {loc}")
    else:
         print(f"HTTP Error: {e.code}")
except Exception as e:
    print(f"Error: {e}")
