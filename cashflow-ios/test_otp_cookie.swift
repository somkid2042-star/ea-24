import Foundation

let apiBase = "https://otp24hr.com/api/v1/tools/api"
let secretKey = "OTP24HRHUB_PROTECT"
let deviceId = "T1RQfE1hY0ludGVsfDh8dW5kZWZpbmVkfDE5MjB4MTA4MHxBbWVyaWNhL05ld19Zb3JrfGVuLVVT"
let licenseKey = "DEMO-2840-3DA8-5345"

Task {
    var req = URLRequest(url: URL(string: "\(apiBase)?action=get_cookie&key=\(licenseKey)&node_id=779")!)
    req.setValue(deviceId, forHTTPHeaderField: "x-device-id")
    req.setValue(licenseKey, forHTTPHeaderField: "x-license-key")
    
    let (data, _) = try! await URLSession.shared.data(for: req)
    print("RAW JSON FROM GET_COOKIE:")
    print(String(data: data, encoding: .utf8)!)
    exit(0)
}
RunLoop.main.run()
