import Foundation

let apiBase = "https://otp24hr.com/api/v1/tools/api"
let secretKey = "OTP24HRHUB_PROTECT"
let deviceId = "T1RQfE1hY0ludGVsfDEwfDE2fDE3MTB4MTEwN3xBc2lhL1RhaXBlaXx0aC1USA"
let licenseKey = "EXCLUSIVE-3940-6C1D-7746"

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
