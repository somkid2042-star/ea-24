import Foundation

let apiBase = "https://otp24hr.com/api/v1/tools/api"
let secretKey = "OTP24HRHUB_PROTECT"
let deviceId = "T1RQfE1hY0ludGVsfDh8dW5kZWZpbmVkfDE5MjB4MTA4MHxBbWVyaWNhL05ld19Zb3JrfGVuLVVT"
let licenseKey = "DEMO-2840-3DA8-5345"

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
    
    do {
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let payload = json["payload"] as? String {
                if let dec = xorDecode(payload) {
                    print("\nDECODED SUCCESS. First 100 chars: \(dec.prefix(100))")
                } else {
                    print("\nxorDecode failed. Invalid base64 or encoding.")
                }
            } else {
                print("\nNO PAYLOAD. JSON: \(json)")
            }
        }
    } catch {
        print("JSON Error: \(error)")
        print("Raw: \(String(data: data, encoding:.utf8)?.prefix(200) ?? "")")
    }
    exit(0)
}
RunLoop.main.run()
