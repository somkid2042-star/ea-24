import urllib.request
import json
import base64

url = "https://otp24hr.com/api/v1/tools/api?action=check_version"
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
try:
    with urllib.request.urlopen(req) as response:
        print(response.read().decode('utf-8'))
except Exception as e:
    print(e)
