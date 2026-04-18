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
    var req2 = URLRequest(url: URL(string: "\(apiBase)?action=get_cookie&key=\(licenseKey)&node_id=779")!)
    req2.setValue(deviceId, forHTTPHeaderField: "x-device-id")
    req2.setValue(licenseKey, forHTTPHeaderField: "x-license-key")
    
    let (data, _) = try! await URLSession.shared.data(for: req2)
    
    let json = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
    let payload = json["payload"] as! String
    print("Payload starts with: \(payload.prefix(20))")
    
    guard let b64 = Data(base64Encoded: payload) else {
        print("Failed base64")
        exit(1)
    }
    
    print("Base64 decode length: \(b64.count)")
    
    exit(0)
}
RunLoop.main.run()
