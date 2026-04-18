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
    var request = URLRequest(url: URL(string: "\(apiBase)?action=get_cookie&key=\(licenseKey)&node_id=779")!)
    request.setValue(deviceId, forHTTPHeaderField: "x-device-id")
    request.setValue(licenseKey, forHTTPHeaderField: "x-license-key")
    
    let (data, _) = try! await URLSession.shared.data(for: request)
    if let str = String(data: data, encoding: .utf8) {
        print("RAW RESPONSE:")
        print(str.prefix(500))
    }
    
    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
        if let payload = json["payload"] as? String, let dec = xorDecode(payload) {
            print("\nDECODED PAYLOAD:")
            print(dec.prefix(500))
        } else {
            print("\nNO PAYLOAD. Error message: \(json["message"] ?? "none")")
        }
    }
    exit(0)
}
RunLoop.main.run()
