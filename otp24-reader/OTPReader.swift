import SwiftUI
import Foundation

@main
struct OTPApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var deviceId = "T1RQfE1hY0ludGVsfDh8dW5kZWZpbmVkfDE3MTB4MTEwN3xBc2lhL1RhaXBlaXx0aC1USA"
    @State private var action = "check_version"
    @State private var outputText = "🚀 Welcome to OTP24 Native Mac Explorer!\n----------------------------------------\n"
    
    @State private var csrfToken = ""
    @State private var licenseKey = ""
    @State private var isFetching = false

    var body: some View {
        VStack(spacing: 20) {
            
            // Header
            HStack {
                Text("🔐 OTP24 Native Explorer")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text(csrfToken.isEmpty ? "CSRF: Not Set" : "CSRF: \(csrfToken.prefix(8))...")
                    .foregroundColor(csrfToken.isEmpty ? .red : .green)
                    .font(.headline)
            }
            .padding(.bottom, 5)
            
            // Controls
            VStack(spacing: 15) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Device ID").font(.caption).foregroundColor(.secondary)
                        TextField("Enter Device ID", text: $deviceId)
                            .textFieldStyle(.roundedBorder)
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text("License Key (ถ้ามี)").font(.caption).foregroundColor(.secondary)
                        TextField("Enter License Key", text: $licenseKey)
                            .textFieldStyle(.roundedBorder)
                    }
                    VStack {
                        Text("").font(.caption)
                        Button("🔑 1. Login") { doLogin() }
                            .foregroundColor(.pink)
                            .disabled(isFetching)
                    }
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Action").font(.caption).foregroundColor(.secondary)
                        TextField("E.g. check_auth", text: $action)
                            .textFieldStyle(.roundedBorder)
                    }
                    VStack {
                        Text("").font(.caption)
                        Button("⚡️ 2. Fetch Data") { doFetch() }
                            .foregroundColor(.blue)
                            .disabled(isFetching)
                    }
                }
            }
            
            // Output Window
            TextEditor(text: $outputText)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.green)
                .padding(8)
                .background(Color.black)
                .cornerRadius(8)
        }
        .padding(20)
        .frame(minWidth: 700, minHeight: 500)
    }
    
    func log(_ msg: String) {
        DispatchQueue.main.async {
            self.outputText += msg + "\n"
        }
    }
    
    func doLogin() {
        self.isFetching = true
        
        let urlStr = licenseKey.isEmpty ? "https://otp24hr.com/api/v1/tools/api?action=login_by_device" : "https://otp24hr.com/api/v1/tools/api?action=login"
        guard let url = URL(string: urlStr) else { return }
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        
        let bodyString = licenseKey.isEmpty ? "device_id=\(deviceId)" : "key=\(licenseKey)&device_id=\(deviceId)"
        req.httpBody = bodyString.data(using: .utf8)
        
        log("\n🛡️ [LOGIN] Trying to login...")
        
        URLSession.shared.dataTask(with: req) { data, response, error in
            DispatchQueue.main.async { self.isFetching = false }
            if let httpRes = response as? HTTPURLResponse,
               let token = httpRes.value(forHTTPHeaderField: "x-csrf-token") {
                DispatchQueue.main.async { self.csrfToken = token }
                log("✅ [SYSTEM] Got CSRF Token!")
            }
            if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let payload = json["payload"] as? String {
                    let decoded = decodeXOR(payload)
                    if let dict = try? JSONSerialization.jsonObject(with: decoded.data(using: .utf8)!) as? [String: Any],
                       let lKey = dict["license_key"] as? String {
                        DispatchQueue.main.async { self.licenseKey = lKey }
                        log("✅ [SYSTEM] Login Success! Key: \(lKey)")
                    }
                } else if let success = json["success"] as? Bool, !success {
                    if let msg = json["message"] as? String {
                        log("❌ Server Error: \(msg)")
                    }
                }
            }
        }.resume()
    }
    
    func doFetch() {
        self.isFetching = true
        var urlStr = "https://otp24hr.com/api/v1/tools/api?action=\(action)"
        if !licenseKey.isEmpty { urlStr += "&key=\(licenseKey)" }
        
        guard let url = URL(string: urlStr) else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        req.addValue(deviceId, forHTTPHeaderField: "x-device-id")
        if !csrfToken.isEmpty { req.addValue(csrfToken, forHTTPHeaderField: "x-csrf-token") }
        if !licenseKey.isEmpty { req.addValue(licenseKey, forHTTPHeaderField: "x-license-key") }
        
        let bodyString = "key=\(licenseKey)&device_id=\(deviceId)"
        req.httpBody = bodyString.data(using: .utf8)
        
        log("\n📡 Requesting \(action)...")
        URLSession.shared.dataTask(with: req) { data, response, error in
            DispatchQueue.main.async { self.isFetching = false }
            if let httpRes = response as? HTTPURLResponse,
               let token = httpRes.value(forHTTPHeaderField: "x-csrf-token") {
                DispatchQueue.main.async { self.csrfToken = token }
            }
            if let e = error { log("❌ Request Failed: \(e)"); return }
            if let data = data, let str = String(data: data, encoding: .utf8) {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String:Any],
                   let payload = json["payload"] as? String {
                    let decoded = decodeXOR(payload)
                    // Format JSON beautifully
                    if let dict = try? JSONSerialization.jsonObject(with: decoded.data(using: .utf8)!),
                       let prettyData = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
                       let prettyStr = String(data: prettyData, encoding: .utf8) {
                        log("📦 --- DECODED DATA ---\n" + prettyStr)
                    } else {
                        log("📦 --- DECODED DATA ---\n" + decoded)
                    }
                } else {
                    log("❌ Raw Response:\n" + str)
                }
            }
        }.resume()
    }
    
    func decodeXOR(_ encoded: String) -> String {
        guard let data = Data(base64Encoded: encoded) else { return "" }
        let secret = Array("OTP24HRHUB_PROTECT".utf8)
        var result = [UInt8]()
        for (i, byte) in data.enumerated() {
            result.append(byte ^ secret[i % secret.count])
        }
        return String(bytes: result, encoding: .utf8) ?? ""
    }
}
