import Foundation

// MARK: - App Model (จาก OTP24HR API)

struct OTPApp: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let icon_url: String
    let category: String?
    let is_locked: Bool
    let requirement: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, icon_url, category, is_locked, requirement
    }
    
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: OTPApp, rhs: OTPApp) -> Bool { lhs.id == rhs.id }
}

// MARK: - Server Node Model

struct ServerNode: Identifiable, Codable {
    let id: Int
    let server_name: String
    let is_working: Bool
    let can_access: Bool
    let lock_app: String?
    let lock_msg: String?
    
    enum CodingKeys: String, CodingKey {
        case id, server_name, is_working, can_access, lock_app, lock_msg
    }
}

// MARK: - Account Data (จากข้อมูล Login)

struct AccountData {
    let packageType: String
    let usedToday: Int
    let dailyLimit: Int
    let expiryDate: String?
    let status: String
    let apps: [OTPApp]
}

// MARK: - Cookie Data (จาก EA-Server cache)

struct CookieData: Codable {
    let name: String
    let value: String
    let domain: String?
    let domains: String?
    let path: String?
    let secure: Bool?
    let httpOnly: Bool?
    let expirationDate: Double?
    let ExpiresDate: Double?
    let sameSite: String?
    
    var effectiveDomain: String {
        domain ?? domains ?? ""
    }
}

// MARK: - API Response Models

struct LoginResponse: Codable {
    let success: Bool
    let payload: String?
    let message: String?
}

struct NodeResponse: Codable {
    let success: Bool
    let payload: String?
}

struct CachedAppsResponse: Codable {
    let cached_app_ids: [Int]
}
