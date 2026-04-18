import Foundation

let apiBase = "https://otp24hr.com/api/v1/tools/api"
let secretKey = "OTP24HRHUB_PROTECT"
let deviceId = "T1RQfE1hY0ludGVsfDEwfDE2fDE3MTB4MTEwN3xBc2lhL1RhaXBlaXx0aC1USA"
let licenseKey = "EXCLUSIVE-3940-6C1D-7746"

func xorDecode(_ encoded: String) -> String? {
    guard let data = Data(base64Encoded: encoded) else { return nil }
    let keyBytes = Array(secretKey.utf8)
    var decoded = [UInt8]()
    for (i, byte) in data.enumerated() {
        decoded.append(byte ^ keyBytes[i % keyBytes.count])
    }
    return String(bytes: decoded, encoding: .utf8)
}

Task {
    print("Checking current cookie fetching capability...")
    var req = URLRequest(url: URL(string: "\(apiBase)?action=get_cookie&key=\(licenseKey)&node_id=779")!)
    req.setValue(deviceId, forHTTPHeaderField: "x-device-id")
    req.setValue(licenseKey, forHTTPHeaderField: "x-license-key")
    
    do {
        let (data, _) = try await URLSession.shared.data(for: req)
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let success = json["success"] as? Bool {
            
            print("API Success: \(success)")
            
            if success, let payload = json["payload"] as? String {
                if let decoded = xorDecode(payload), decoded.contains("\"cookies\":") {
                    print("✅ YES! We can fetch actual live cookies. Decoded payload is valid JSON and contains actual cookies.")
                } else {
                    print("❌ NO. The decoded payload doesn't contain valid cookies. It might be an error encoded in base64. (Quota empty or key error)")
                    if json["expiry_date"] != nil {
                        print("Returned expiry_date: \(json["expiry_date"]!)")
                    }
                }
            } else {
                print("❌ NO PAYLOAD RETURNED.")
            }
            
        }
    } catch {
        print("Request failed: \(error)")
    }
    
    exit(0)
}
RunLoop.main.run()
