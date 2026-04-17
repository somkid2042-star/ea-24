import Foundation
import UIKit

// MARK: - XOR Decode (เหมือน Extension)
// ใช้ถอดรหัส payload จาก OTP24HR API

func xorDecode(_ base64Input: String, _ key: String) -> String? {
    guard let data = Data(base64Encoded: base64Input) else { return nil }
    let keyBytes = Array(key.utf8)
    var result = [UInt8]()
    for (i, byte) in data.enumerated() {
        result.append(byte ^ keyBytes[i % keyBytes.count])
    }
    return String(bytes: result, encoding: .utf8)
}

// MARK: - API Service

@MainActor
class APIService: ObservableObject {
    static let shared = APIService()
    
    private let apiBase = "https://manage.otp24hr.com/api/app_api.php"
    private let eaServerBase = "http://35.201.156.240:4173"
    
    // Secret key (เหมือน Extension)
    private let secretKey: String = {
        let k1 = "JF93hfn2"
        let k2 = "Kd82nfK3"
        let k3 = "mF93jfNa"
        return k1 + k2 + k3
    }()
    
    @Published var isLoggedIn = false
    @Published var accountData: AccountData?
    @Published var apps: [OTPApp] = []
    @Published var cachedAppIds: Set<Int> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var csrfToken: String?
    private var licenseKey: String?
    
    // MARK: - Login
    
    func login(key: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        // Step 1: ดึง CSRF Token
        csrfToken = try await fetchCSRFToken()
        
        // Step 2: Login
        var request = URLRequest(url: URL(string: "\(apiBase)?action=login")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        if let token = csrfToken {
            request.setValue(token, forHTTPHeaderField: "X-CSRF-TOKEN")
        }
        request.httpBody = "key=\(key)".data(using: .utf8)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(LoginResponse.self, from: data)
        
        guard response.success, let payload = response.payload else {
            throw APIError.loginFailed(response.message ?? "Invalid Key")
        }
        
        // Step 3: Decode payload
        guard let decoded = xorDecode(payload, secretKey),
              let jsonData = decoded.data(using: .utf8) else {
            throw APIError.decodeFailed
        }
        
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] ?? [:]
        
        // Parse apps
        let appsData = try JSONSerialization.data(withJSONObject: json["apps"] ?? [])
        let decodedApps = try JSONDecoder().decode([OTPApp].self, from: appsData)
        
        // Parse account info
        let account = AccountData(
            packageType: json["package_type"] as? String ?? json["plan"] as? String ?? "FREE",
            usedToday: json["used_today"] as? Int ?? 0,
            dailyLimit: json["daily_limit"] as? Int ?? 0,
            expiryDate: json["expiry_date"] as? String,
            status: json["status"] as? String ?? "active",
            apps: decodedApps
        )
        
        self.licenseKey = key
        self.accountData = account
        self.apps = decodedApps
        self.isLoggedIn = true
        
        // Save key
        UserDefaults.standard.set(key, forKey: "license_key")
        
        // Sync device + fetch cached apps
        Task {
            await syncDevice()
            await fetchCachedApps()
        }
    }
    
    // MARK: - Fetch CSRF Token
    
    private func fetchCSRFToken() async throws -> String {
        let (data, _) = try await URLSession.shared.data(from: URL(string: "\(apiBase)?action=get_csrf_token")!)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["csrf_token"] as? String ?? ""
    }
    
    // MARK: - Load Servers for App
    
    func loadNodes(appId: Int) async throws -> [ServerNode] {
        guard let token = csrfToken else { throw APIError.noCSRF }
        
        var request = URLRequest(url: URL(string: "\(apiBase)?action=get_nodes&app_id=\(appId)")!)
        request.setValue(token, forHTTPHeaderField: "X-CSRF-TOKEN")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(NodeResponse.self, from: data)
        
        guard let payload = response.payload,
              let decoded = xorDecode(payload, secretKey),
              let jsonData = decoded.data(using: .utf8) else {
            throw APIError.decodeFailed
        }
        
        return try JSONDecoder().decode([ServerNode].self, from: jsonData)
    }
    
    // MARK: - Fetch Cookie from EA-Server (cache)
    
    func fetchCookie(nodeId: Int, forceRefresh: Bool = false) async throws -> (cookies: [CookieData], targetUrl: String) {
        let forceParam = forceRefresh ? "&force=true" : ""
        let url = URL(string: "\(eaServerBase)/api/otp24/cookie?node_id=\(nodeId)\(forceParam)")!
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        
        if let status = json["status"] as? String, status == "error" {
            throw APIError.serverError(json["message"] as? String ?? "Cache error")
        }
        
        // Extract cookies and target URL
        let targetUrl = json["target_url"] as? String ?? json["url"] as? String ?? ""
        
        let cookiesRaw = json["cookies"] ?? json["data"] ?? []
        let cookiesData = try JSONSerialization.data(withJSONObject: cookiesRaw)
        let cookies = try JSONDecoder().decode([CookieData].self, from: cookiesData)
        
        return (cookies, targetUrl)
    }
    
    // MARK: - Sync Device ID
    
    private func syncDevice() async {
        guard let key = licenseKey else { return }
        do {
            let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "ios-unknown"
            var request = URLRequest(url: URL(string: "\(eaServerBase)/api/otp24/sync_device")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body: [String: String] = [
                "device_id": deviceId,
                "csrf_token": csrfToken ?? "",
                "license_key": key
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let _ = try await URLSession.shared.data(for: request)
        } catch {
            print("[SYNC] Device sync failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Fetch Cached Apps
    
    func fetchCachedApps() async {
        do {
            let url = URL(string: "\(eaServerBase)/api/otp24/cached_apps")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(CachedAppsResponse.self, from: data)
            self.cachedAppIds = Set(response.cached_app_ids)
        } catch {
            print("[CACHE] Fetch cached apps failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Auto Login
    
    func autoLogin() async {
        // ลองใช้ key ที่เก็บไว้ก่อน
        if let savedKey = UserDefaults.standard.string(forKey: "license_key"), !savedKey.isEmpty {
            try? await login(key: savedKey)
            return
        }
        // ถ้าไม่มี ลองดึงจาก EA-Server
        await skipLogin()
    }
    
    // MARK: - Skip Login (ดึง key จาก EA-Server ที่ Extension sync ไว้)
    
    func skipLogin() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let url = URL(string: "\(eaServerBase)/api/otp24/get_license")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            
            if let status = json["status"] as? String, status == "success",
               let key = json["license_key"] as? String, !key.isEmpty {
                try await login(key: key)
            } else {
                errorMessage = "ไม่พบ License Key บนเซิร์ฟเวอร์ กรุณาใส่ Key ด้านบน"
            }
        } catch {
            errorMessage = "ไม่สามารถเชื่อมต่อ EA-Server: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Logout
    
    func logout() {
        isLoggedIn = false
        accountData = nil
        apps = []
        licenseKey = nil
        UserDefaults.standard.removeObject(forKey: "license_key")
    }
}

// MARK: - Errors

enum APIError: LocalizedError {
    case loginFailed(String)
    case decodeFailed
    case noCSRF
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .loginFailed(let msg): return msg
        case .decodeFailed: return "ข้อมูลถอดรหัสไม่สำเร็จ"
        case .noCSRF: return "ไม่มี CSRF Token"
        case .serverError(let msg): return msg
        }
    }
}
