import Foundation

let apiBase = "https://otp24hr.com/api/v1/tools/api"
let secretKey = "OTP24HRHUB_PROTECT"
let deviceId = "T1RQfE1hY0ludGVsfDh8dW5kZWZpbmVkfDE5MjB4MTA4MHxBbWVyaWNhL05ld19Zb3JrfGVuLVVT"
let licenseKey = "DEMO-2840-3DA8-5345"
var csrf = ""

func apiCall(action: String, body: [String: String]? = nil, params: [String: String] = [:]) async -> Data? {
    var urlString = "\(apiBase)?action=\(action)&key=\(licenseKey)"
    for (k, v) in params { urlString += "&\(k)=\(v)" }
    
    var request = URLRequest(url: URL(string: urlString)!)
    request.setValue(deviceId, forHTTPHeaderField: "x-device-id")
    request.setValue(licenseKey, forHTTPHeaderField: "x-license-key")
    if !csrf.isEmpty { request.setValue(csrf, forHTTPHeaderField: "x-csrf-token") }
    request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
    
    if let body = body {
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = body.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }.joined(separator: "&").data(using: .utf8)
    }
    
    let (data, res) = try! await URLSession.shared.data(for: request)
    if let h = res as? HTTPURLResponse, let c = h.value(forHTTPHeaderField: "x-csrf-token") { csrf = c }
    return data
}

Task {
    print("Logging in...")
    let loginData = await apiCall(action: "login", body: ["key": licenseKey, "device_id": deviceId])!
    
    print("\nGetting cookie for node 779...")
    let cookieData = await apiCall(action: "get_cookie", params: ["node_id": "779"])!
    if let str = String(data: cookieData, encoding: .utf8) {
        print("Raw cookie output: \(str.prefix(500))")
    }
    exit(0)
}

RunLoop.main.run()
