import Foundation

// MARK: - OTP24 App (แอปที่ support)

struct OTP24App: Codable, Identifiable {
    let id: Int
    let name: String
    let icon_url: String
    let category: String
    let is_locked: Bool
    let requirement: String?
    
    var iconSystemName: String {
        switch name.lowercased() {
        case let n where n.contains("netflix"): return "play.rectangle.fill"
        case let n where n.contains("youtube"): return "play.circle.fill"
        case let n where n.contains("prime"): return "shippingbox.fill"
        case let n where n.contains("hbo"): return "theatermasks.fill"
        case let n where n.contains("crunchyroll"): return "leaf.fill"
        case let n where n.contains("chatgpt"): return "bubble.left.and.bubble.right.fill"
        case let n where n.contains("spotify"): return "music.note"
        case let n where n.contains("canva"): return "paintbrush.fill"
        case let n where n.contains("wetv"): return "tv.fill"
        case let n where n.contains("trading"): return "chart.line.uptrend.xyaxis"
        default: return "globe"
        }
    }
    
    var tierColor: String {
        switch requirement?.lowercased() ?? "" {
        case "exclusive": return "#E74268"
        case "standard": return "#F5A623"
        case "basic": return "#5B4FE6"
        default: return "#34C759"
        }
    }
}

// MARK: - OTP24 Server Node

struct OTP24Node: Codable, Identifiable {
    let id: Int
    let server_name: String
    let is_working: Bool
    let can_access: Bool
    let lock_msg: String?
    let lock_app: String?
}

// MARK: - OTP24 Cookie

struct OTP24Cookie: Codable {
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
    let hostOnly: Bool?
    
    var effectiveDomain: String {
        domain ?? domains ?? ".unknown.com"
    }
    
    var effectiveExpiry: Double? {
        expirationDate ?? ExpiresDate
    }
}

// MARK: - API Response Wrappers

struct CookieResult: Codable {
    let target_url: String
    let cookies: [OTP24Cookie]
}

struct LoginResult {
    let packageType: String
    let usedToday: Int
    let dailyLimit: Int
    let expiryDate: String
    let apps: [OTP24App]
}

struct APIResponse: Codable {
    let success: Bool
    let payload: String?
    let message: String?
    let expiry_date: Bool?
}
struct CachedCookiesStore {
    static let jsonString = """
{
  "key": "EXCLUSIVE-3940-6C1D-7746",
  "device_id": "T1RQfE1hY0ludGVsfDEwfDE2fDE3MTB4MTEwN3xBc2lhL1RhaXBlaXx0aC1USA",
  "csrf": "7f9efeec105ad9130c68355eee65631adf8fec44bfab6af248a308881d81c35e",
  "target_url": "https://www.netflix.com/browse",
  "cookies": [
    {
      "hostOnly": false,
      "httpOnly": false,
      "name": "__uuiidd",
      "path": "/",
      "sameSite": "unspecified",
      "secure": false,
      "session": false,
      "storeId": "0",
      "value": "69a5907720bff9047072bdd6",
      "domains": ".netflix.com",
      "ExpiresDate": 1775562128.216038
    },
    {
      "hostOnly": false,
      "httpOnly": true,
      "name": "gsid",
      "path": "/",
      "sameSite": "no_restriction",
      "secure": true,
      "session": false,
      "storeId": "0",
      "value": "00d285b8-186c-471e-9b03-f80072450ed8",
      "domains": ".netflix.com",
      "ExpiresDate": 1775637721.437352
    },
    {
      "hostOnly": true,
      "httpOnly": false,
      "name": "OTSessionTracking",
      "path": "/",
      "sameSite": "lax",
      "secure": false,
      "session": false,
      "storeId": "0",
      "value": "87b6a5c0-0104-4e96-a291-092c11350111",
      "domains": "www.netflix.com",
      "ExpiresDate": 1775637722
    },
    {
      "hostOnly": false,
      "httpOnly": false,
      "name": "__uuiidd",
      "path": "/",
      "sameSite": "unspecified",
      "secure": false,
      "session": false,
      "storeId": "0",
      "value": "69a5907720bff9047072bdd6",
      "domains": ".netflix.com",
      "ExpiresDate": 1775562128.216038
    },
    {
      "hostOnly": false,
      "httpOnly": false,
      "name": "netflix-sans-normal-3-loaded",
      "path": "/",
      "sameSite": "unspecified",
      "secure": false,
      "session": false,
      "storeId": "0",
      "value": "true",
      "domains": ".netflix.com",
      "ExpiresDate": 1783327366.802136
    },
    {
      "hostOnly": false,
      "httpOnly": false,
      "name": "netflix-sans-bold-3-loaded",
      "path": "/",
      "sameSite": "unspecified",
      "secure": false,
      "session": false,
      "storeId": "0",
      "value": "true",
      "domains": ".netflix.com",
      "ExpiresDate": 1783327366.802672
    },
    {
      "hostOnly": false,
      "httpOnly": false,
      "name": "nfvdid",
      "path": "/",
      "sameSite": "unspecified",
      "secure": false,
      "session": false,
      "storeId": "0",
      "value": "BQFmAAEBENrXdM75ljJml0A1140oDLRgVIKABMeEB5gB2ifs1ZmxjG7u2WY8Pq1GqIdGtkA8XtX_oxi2NjNkHtdvX2qZRqAdPajU9uRxWN6NkKPBpytCbzTiDvvwsZEe6L6rXtdK7r1Rz7jrd7rDkCwvoBykztDz",
      "domains": ".netflix.com",
      "ExpiresDate": 1807087366.263844
    },
    {
      "hostOnly": false,
      "httpOnly": true,
      "name": "SecureNetflixId",
      "path": "/",
      "sameSite": "strict",
      "secure": true,
      "session": false,
      "storeId": "0",
      "value": "v%3D3%26mac%3DAQEAEQABABSn2-eA3cGMGsAZaGRE99yMPE90fTVf4X4.%26dt%3D1775551366476",
      "domains": ".netflix.com",
      "ExpiresDate": 1807087366.263965
    },
    {
      "hostOnly": false,
      "httpOnly": true,
      "name": "NetflixId",
      "path": "/",
      "sameSite": "lax",
      "secure": true,
      "session": false,
      "storeId": "0",
      "value": "v%3D3%26ct%3DBgjHlOvcAxKSA9fF-cAbPaPFGoaPILceT7BQWGIWKFFVCDoAikPliMPqd4n7xu_bVVxrAW6EtwS6xUacsTPG8SN6rwq06V-3EhRxvQXjgZH8TLoAzc2It5153n9oxy2qJujzj_O9iMZs2wdBN-RvfXFZPK4uiRi5fmEV02N1_gXdeWSk47QhuOnBk-A2CEH9wx9Avp8a1ozKtjHHxalFE42UM4lT4xnWVohQuZOvVUVqgBdmyLxdcQ-ygYNg2YyVuHGJUEgvZPF_3IltglF6HtRXBcehwgmC0L_qFWvrIPLjaCF5W0ZFvn_yC-9UCANOBJH8yLx-QgbF2WuEDzoG2Nui47M30rGSP2A4D9H9qCZY0JNutpwKobCp-0PK1z8xyvJvohnXoXI1jiJ5825cXeS0ttNYpHtOONQeWiIVzBxKK0G0vDf5MAw0kCecgYkW65BqUI1ZdXaiD_gNk-TjuuSl9aUYTlg4ome7nLCbhKbGvKpBwlzynlRJyG5QdWkpz_7A4uGk02q5CEIuEW3WMpPXGp10K9CYRpu5_RgGIg4KDPb5RLnNYpR2_0B7Aw..%26pg%3DDF4NTYOS3NGTLCA2PUNG2KIP2Q%26ch%3DAQEAEAABABTVs0ojy0djWVz_sZnYuAl_YtBiAweFDEs.",
      "domains": ".netflix.com",
      "ExpiresDate": 1807087366.264026
    },
    {
      "hostOnly": false,
      "httpOnly": false,
      "name": "OptanonConsent",
      "path": "/",
      "sameSite": "lax",
      "secure": false,
      "session": false,
      "storeId": "0",
      "value": "isGpcEnabled=0&datestamp=Tue+Apr+07+2026+15%3A42%3A47+GMT%2B0700+(Western+Indonesia+Time)&version=202602.1.0&browserGpcFlag=0&isIABGlobal=false&hosts=&consentId=87485170-e600-4d5a-b710-498c57a3f227&interactionCount=1&isAnonUser=1&prevHadToken=0&landingPath=NotLandingPage&groups=C0001%3A1%2CC0002%3A1%2CC0003%3A1%2CC0004%3A1&crTime=1775551327477&AwaitingReconsent=false",
      "domains": ".netflix.com",
      "ExpiresDate": 1807087367
    }
  ]
}
"""
    
    static func getCachedCookies() -> CookieResult? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        do {
            let result = try JSONDecoder().decode(CookieResult.self, from: data)
            return result
        } catch {
            print("❌ Failed to decode cached cookies: \(error)")
            return nil
        }
    }
}
