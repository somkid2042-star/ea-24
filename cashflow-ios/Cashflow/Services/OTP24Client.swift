import Foundation

// MARK: - OTP24 API Client

@MainActor
class OTP24Client {
    static let shared = OTP24Client()
    
    private let apiBase = "https://otp24hr.com/api/v1/tools/api"
    private let secretKey = "OTP24HRHUB_PROTECT"
    private var csrf = ""
    
    // ✅ เก็บ deviceId + key ไว้ใช้ทุก request
    var currentDeviceId = ""
    var currentKey = ""
    
    private init() {}
    
    // MARK: - XOR Decode
    
    func xorDecode(_ encoded: String) -> String? {
        guard let data = Data(base64Encoded: encoded) else { return nil }
        let keyBytes = Array(secretKey.utf8)
        var decoded = [UInt8]()
        for (i, byte) in data.enumerated() {
            decoded.append(byte ^ keyBytes[i % keyBytes.count])
        }
        return String(bytes: decoded, encoding: .utf8)
    }
    
    // MARK: - Generate Device ID
    
    func generateDeviceId() -> String {
        let resolutions = ["1920x1080","2560x1440","1366x768","1536x864","1440x900","1680x1050"]
        let timezones = ["America/New_York","America/Chicago","Europe/London","Europe/Paris","Europe/Berlin","Asia/Tokyo"]
        let languages = ["en-US","en-GB","fr-FR","de-DE","ja-JP","ko-KR","es-ES"]
        let cpus = ["4","8","12","16"]
        
        let res = resolutions.randomElement()!
        let tz = timezones.randomElement()!
        let lang = languages.randomElement()!
        let cpu = cpus.randomElement()!
        let rnd = Int.random(in: 1000...9999)
        
        let parts = res.split(separator: "x")
        let w = (Int(parts[0]) ?? 1920) + rnd
        let uniqueRes = "\(w)x\(parts[1])"
        
        let rawId = "OTP|MacIntel|\(cpu)|undefined|\(uniqueRes)|\(tz)|\(lang)"
        let b64 = Data(rawId.utf8).base64EncodedString()
        return b64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    // MARK: - API Call (ใช้ stored deviceId/key ถ้าไม่ได้ระบุ)
    
    private func apiCall(
        action: String,
        params: [String: String] = [:],
        postBody: [String: String]? = nil,
        deviceId: String? = nil,
        key: String? = nil
    ) async -> (data: Data, headers: [String: String])? {
        let useDeviceId = deviceId ?? currentDeviceId
        let useKey = key ?? currentKey
        
        var urlString = "\(apiBase)?action=\(action)"
        if !useKey.isEmpty { urlString += "&key=\(useKey)" }
        for (k, v) in params {
            urlString += "&\(k)=\(v.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? v)"
        }
        
        guard let url = URL(string: urlString) else {
            print("❌ OTP24: Invalid URL: \(urlString)")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
        request.setValue(useDeviceId, forHTTPHeaderField: "x-device-id")
        request.setValue(useKey, forHTTPHeaderField: "x-license-key")
        if !csrf.isEmpty {
            request.setValue(csrf, forHTTPHeaderField: "x-csrf-token")
        }
        
        if let body = postBody {
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            let bodyString = body.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }.joined(separator: "&")
            request.httpBody = bodyString.data(using: .utf8)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Debug log
            if let str = String(data: data, encoding: .utf8) {
                print("🔧 OTP24 [\(action)]: \(str.prefix(200))")
            }
            
            if let httpResponse = response as? HTTPURLResponse,
               let newCSRF = httpResponse.value(forHTTPHeaderField: "x-csrf-token") {
                csrf = newCSRF
            }
            let headers = (response as? HTTPURLResponse)?.allHeaderFields as? [String: String] ?? [:]
            return (data, headers)
        } catch {
            print("❌ OTP24 API Error [\(action)]: \(error)")
            return nil
        }
    }
    
    // MARK: - Create Demo Key
    
    func createDemoKey(deviceId: String) async -> String? {
        self.currentDeviceId = deviceId
        
        guard let result = await apiCall(
            action: "create_order",
            postBody: ["device_id": deviceId, "pkg_id": "1"],
            deviceId: deviceId
        ) else { return nil }
        
        guard let json = try? JSONSerialization.jsonObject(with: result.data) as? [String: Any],
              let payload = json["payload"] as? String,
              let decoded = xorDecode(payload),
              let payloadData = decoded.data(using: .utf8),
              let payloadJSON = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let newKey = payloadJSON["new_key"] as? String else {
            return nil
        }
        
        self.currentKey = newKey
        return newKey
    }
    
    // MARK: - Login
    
    func login(key: String, deviceId: String) async -> LoginResult? {
        // ✅ เก็บไว้ใช้ต่อทุก request
        self.currentKey = key
        self.currentDeviceId = deviceId
        
        guard let result = await apiCall(
            action: "login",
            postBody: ["key": key, "device_id": deviceId],
            deviceId: deviceId,
            key: key
        ) else { return nil }
        
        guard let json = try? JSONSerialization.jsonObject(with: result.data) as? [String: Any],
              let payload = json["payload"] as? String,
              let decoded = xorDecode(payload),
              let payloadData = decoded.data(using: .utf8),
              let d = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else {
            return nil
        }
        
        let packageType = d["package_type"] as? String ?? "demo"
        let usedToday = d["used_today"] as? Int ?? 0
        let dailyLimit = d["daily_limit"] as? Int ?? 5
        let expiryDate = d["expiry_date"] as? String ?? ""
        
        // Parse apps
        var apps: [OTP24App] = []
        if let appsArray = d["apps"] as? [[String: Any]] {
            for appDict in appsArray {
                let app = OTP24App(
                    id: appDict["id"] as? Int ?? 0,
                    name: appDict["name"] as? String ?? "",
                    icon_url: appDict["icon_url"] as? String ?? "",
                    category: appDict["category"] as? String ?? "",
                    is_locked: (appDict["is_locked"] as? Int == 1) || (appDict["is_locked"] as? Bool == true),
                    requirement: appDict["requirement"] as? String
                )
                apps.append(app)
            }
        }
        
        return LoginResult(
            packageType: packageType,
            usedToday: usedToday,
            dailyLimit: dailyLimit,
            expiryDate: expiryDate,
            apps: apps
        )
    }
    
    // MARK: - Get Nodes (ใช้ stored deviceId/key อัตโนมัติ)
    
    func getNodes(appId: Int, key: String) async -> [OTP24Node]? {
        guard let result = await apiCall(
            action: "get_nodes",
            params: ["app_id": "\(appId)"],
            key: key
        ) else { return nil }
        
        guard let json = try? JSONSerialization.jsonObject(with: result.data) as? [String: Any],
              let payload = json["payload"] as? String,
              let decoded = xorDecode(payload),
              let payloadData = decoded.data(using: .utf8),
              let nodesArray = try? JSONSerialization.jsonObject(with: payloadData) as? [[String: Any]] else {
            print("❌ OTP24: getNodes decode failed")
            return nil
        }
        
        return nodesArray.map { d in
            OTP24Node(
                id: d["id"] as? Int ?? 0,
                server_name: d["server_name"] as? String ?? "",
                is_working: (d["is_working"] as? Int == 1) || (d["is_working"] as? Bool == true),
                can_access: (d["can_access"] as? Int == 1) || (d["can_access"] as? Bool == true),
                lock_msg: d["lock_msg"] as? String,
                lock_app: d["lock_app"] as? String
            )
        }
    }
    
    // MARK: - Get Cookie (ใช้ stored deviceId/key อัตโนมัติ)
    
    func getCookie(nodeId: Int, key: String) async -> CookieResult? {
        guard let result = await apiCall(
            action: "get_cookie",
            params: ["node_id": "\(nodeId)"],
            key: key
        ) else { return nil }
        
        guard let json = try? JSONSerialization.jsonObject(with: result.data) as? [String: Any],
              let payload = json["payload"] as? String,
              let decoded = xorDecode(payload),
              let payloadData = decoded.data(using: .utf8) else {
            print("❌ OTP24: getCookie decode failed")
            return nil
        }
        
        do {
            let cookieResult = try JSONDecoder().decode(CookieResult.self, from: payloadData)
            return cookieResult
        } catch {
            print("❌ OTP24 Cookie decode error: \(error)")
            return nil
        }
    }
}
