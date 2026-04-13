import Foundation

let secretKey = "OTP24HRHUB_PROTECT"

func xorDecode(_ encoded: String) -> String? {
    guard let data = Data(base64Encoded: encoded) else { return nil }
    let keyBytes = Array(secretKey.utf8)
    var decoded = [UInt8]()
    for (i, byte) in data.enumerated() {
        decoded.append(byte ^ keyBytes[i % keyBytes.count])
    }
    return String(bytes: decoded, encoding: .utf8)
}

let newId = UUID().uuidString.replacingOccurrences(of: "-", with: "")
print("Using ID:", newId)

let sema = DispatchSemaphore(value: 0)

var req = URLRequest(url: URL(string: "https://otp24hr.com/api/v1/tools/api?action=create_order")!)
req.httpMethod = "POST"
req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
req.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
req.setValue(newId, forHTTPHeaderField: "x-device-id")
req.httpBody = "pkg_id=1&device_id=\(newId)".data(using: .utf8)

URLSession.shared.dataTask(with: req) { data, res, err in
    defer { sema.signal() }
    guard let data = data else { print("no data"); return }
    let str = String(data: data, encoding: .utf8) ?? ""
    print("RES:", str)
    
    if let d = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
       let pay = d["payload"] as? String,
       let dec = xorDecode(pay) {
        print("DECODED PAYLOAD:", dec)
    }
}.resume()

sema.wait()

