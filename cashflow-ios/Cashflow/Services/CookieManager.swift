import Foundation
import WebKit

// MARK: - Cookie Manager for WKWebView

class CookieManager {
    
    /// ฉีด Cookie ทั้งหมด (รวม HttpOnly!) เข้า WKWebView
    static func inject(_ cookies: [OTP24Cookie], into cookieStore: WKHTTPCookieStore) async {
        for c in cookies {
            let domain = c.effectiveDomain
            
            var properties: [HTTPCookiePropertyKey: Any] = [
                .name: c.name,
                .value: c.value,
                .domain: domain,
                .path: c.path ?? "/"
            ]
            
            // Secure
            if c.secure == true {
                properties[.secure] = "TRUE"
            }
            
            // Expiry
            if let exp = c.effectiveExpiry {
                properties[.expires] = Date(timeIntervalSince1970: exp)
            } else {
                // Default: 1 year from now
                properties[.expires] = Date().addingTimeInterval(365 * 24 * 3600)
            }
            
            // SameSite
            if let sameSite = c.sameSite {
                properties[HTTPCookiePropertyKey("SameSitePolicy")] = sameSite
            }
            
            if let cookie = HTTPCookie(properties: properties) {
                await cookieStore.setCookie(cookie)
            }
        }
    }
    
    /// ล้าง Cookie ของ domain ที่ระบุ
    static func clearCookies(for domain: String, from cookieStore: WKHTTPCookieStore) async {
        let allCookies = await cookieStore.allCookies()
        let baseDomain = domain.replacingOccurrences(of: "www.", with: "")
        
        for cookie in allCookies {
            if cookie.domain.contains(baseDomain) {
                await cookieStore.deleteCookie(cookie)
            }
        }
    }
    
    // MARK: - Local Cache (UserDefaults)
    
    private static let cacheKey = "otp24_cookie_cache"
    
    static func save(_ cookies: [OTP24Cookie], for appName: String) {
        var cache = loadAllCache()
        if let data = try? JSONEncoder().encode(cookies) {
            cache[appName] = data
        }
        UserDefaults.standard.set(cache, forKey: cacheKey)
    }
    
    static func load(for appName: String) -> [OTP24Cookie]? {
        let cache = loadAllCache()
        guard let data = cache[appName] else { return nil }
        return try? JSONDecoder().decode([OTP24Cookie].self, from: data)
    }
    
    private static func loadAllCache() -> [String: Data] {
        UserDefaults.standard.dictionary(forKey: cacheKey) as? [String: Data] ?? [:]
    }
    
    static func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
    }
}
