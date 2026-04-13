import Foundation

let jsonString = """
{
    "package_type": "demo",
    "used_today": 0,
    "daily_limit": 5,
    "expiry_date": "2024-05-13 00:00:00",
    "apps": []
}
"""

if let data = jsonString.data(using: .utf8),
   let d = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
    print("Parsed JSON successfully: \(d)")
} else {
    print("Failed to parse JSON")
}
