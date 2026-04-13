import Foundation

let jsonString = """
{"success":true,"payload":"HxpUXFoIWwRKR1w\\/SBZeWFxWGg5GS1JARgpdD2YMAkYfFkZYXUZdFl4aUVYDAAdQXQEHAQsGUQ4FBg0BBlxRVldUB1NcAV4GC1YSFRNXV1kFUVlAF1kQT14KCQNfUR5aXl4aGEZIVkddQQhDZUpEGR9PEldQXl0WXhpUVWoAXgRYFwcKUFESFRNFWVgRXRUJF1NWVVpVBwBQA1JcA1ZdVgFaBQUCVgQEDVFWVVcHCA1SVg4FUQAGBwJBHkNdCgsFWlpDGwsRT0MTFlBcWgReBBcGCQkRGBJJUEdQFl4aaxwXHh4aGwsHCVYWChtQRkxcO0xYWFANEE0bEwcIRlESAxNSWVZRXg4FB1JWUV8DBV0DAAdaUAUJAAIOVQoFW1BSCF1SAFABCQoEAgBWXF5RCgcGAlMPBl5UAVEJWldWAQFdGhsRUQxfAFALFUYJFh5eXlxfWAEWVFxYQR5DSQQSDBEOEmUeEUVpSBpDUkcEVxVmEBQIEQ5WWF1AXRhGS0NSQRZBQwNHBwdHXUZcEx8aRwFKQVZHPEYIVABEXgIDBw8BBggFUApK","target_url":false,"expiry_date":1776050142}
"""

guard let json = try? JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!) as? [String: Any],
      let payload = json["payload"] as? String else {
    print("NO PAYLOAD")
    exit(1)
}

let secretKey = "OTP24HRHUB_PROTECT"
guard let data = Data(base64Encoded: payload) else { print("base64 failed"); exit(1) }
let keyBytes = Array(secretKey.utf8)
var decoded = [UInt8]()
for (i, byte) in data.enumerated() {
    decoded.append(byte ^ keyBytes[i % keyBytes.count])
}
let decodedStr = String(bytes: decoded, encoding: .utf8) ?? "utf8 failed"
print(decodedStr)
