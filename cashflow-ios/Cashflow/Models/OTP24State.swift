import Foundation
import SwiftUI

@MainActor
class OTP24State: ObservableObject {
    // ✅ ใช้ Key เดิมที่มีโควต้าเหลือ
    @AppStorage("otp24_license_key") var savedKey: String = "EXCLUSIVE-3940-6C1D-7746"
    @AppStorage("otp24_device_id") var savedDeviceId: String = "T1RQfE1hY0ludGVsfDEwfDE2fDE3MTB4MTEwN3xBc2lhL1RhaXBlaXx0aC1USA"
    
    @Published var isLoggedIn = false
    @Published var licenseKey = ""
    @Published var deviceId = ""
    @Published var packageType = "demo"
    @Published var usedToday = 0
    @Published var dailyLimit = 5
    @Published var expiryDate = ""
    
    @Published var apps: [OTP24App] = []
    @Published var nodes: [OTP24Node] = []
    @Published var selectedApp: OTP24App?
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var toastMessage: String?
    
    // Navigation
    @Published var showServerList = false
    @Published var showWebBrowser = false
    @Published var browserURL = ""
    @Published var browserCookies: [OTP24Cookie] = []
    
    private var hasAutoLoggedIn = false
    
    // MARK: - Auto Login (เรียกตอนเปิด tab)
    
    func autoLoginIfNeeded() async {
        guard !hasAutoLoggedIn else { return }
        hasAutoLoggedIn = true
        
        // ถ้ามี Key เก็บไว้ → ใช้ Key เดิม login เลย
        if !savedKey.isEmpty {
            await login()
        } else {
            // ไม่มี Key → สร้างใหม่ครั้งเดียว
            await createNewKey()
        }
    }
    
    // MARK: - Login (ใช้ Key เดิมที่เก็บไว้)
    
    func login() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        
        let client = OTP24Client.shared
        
        // ✅ ใช้ Key เดิมเสมอ ไม่สร้างใหม่
        licenseKey = savedKey
        deviceId = savedDeviceId.isEmpty ? client.generateDeviceId() : savedDeviceId
        
        // ถ้ายังไม่มี Key → ต้องสร้างก่อน
        if licenseKey.isEmpty {
            isLoading = false
            return
        }
        
        if let result = await client.login(key: licenseKey, deviceId: deviceId) {
            packageType = result.packageType
            usedToday = result.usedToday
            dailyLimit = result.dailyLimit
            expiryDate = result.expiryDate
            apps = result.apps
            isLoggedIn = true
        } else {
            errorMessage = "Login ไม่สำเร็จ"
        }
        
        isLoading = false
    }
    
    // MARK: - Load Nodes
    
    func loadNodes(for app: OTP24App) async {
        isLoading = true
        selectedApp = app
        
        if let fetchedNodes = await OTP24Client.shared.getNodes(appId: app.id, key: licenseKey) {
            nodes = fetchedNodes
        }
        
        isLoading = false
    }
    
    // MARK: - Get Cookie & Open Browser
    
    func getCookieAndOpen(nodeId: Int) async {
        isLoading = true
        
        if let result = await OTP24Client.shared.getCookie(nodeId: nodeId, key: licenseKey) {
            browserURL = result.target_url
            browserCookies = result.cookies
            usedToday += 1
            showWebBrowser = true
            toastMessage = "Cookie \(result.cookies.count) ตัว พร้อมใช้งาน!"
        } else {
            // ✅ FALLBACK: โควต้าเต็มให้ใช้ Cached Cookies แทน
            if let cached = CachedCookiesStore.getCachedCookies() {
                browserURL = cached.target_url
                browserCookies = cached.cookies
                showWebBrowser = true
                toastMessage = "ใช้งาน Offline Mode (โควต้าหมด)"
                print("⚠️ Fallback to Cached Cookies")
            } else {
                errorMessage = "ดึง Cookie ไม่ได้ (โควต้าอาจหมด)"
            }
        }
        
        isLoading = false
    }
    
    // MARK: - Create New Key (เรียกเฉพาะเมื่อยังไม่มี Key)
    
    func createNewKey() async {
        isLoading = true
        let client = OTP24Client.shared
        deviceId = client.generateDeviceId()
        
        if let newKey = await client.createDemoKey(deviceId: deviceId) {
            licenseKey = newKey
            savedKey = newKey
            savedDeviceId = deviceId
            toastMessage = "สร้าง Key ใหม่สำเร็จ!"
            await login()
        } else {
            errorMessage = "สร้าง Key ไม่ได้ (ลองเปลี่ยน IP/VPN)"
            isLoading = false
        }
    }
    
    // MARK: - Logout
    
    func logout() {
        savedKey = ""
        savedDeviceId = ""
        licenseKey = ""
        deviceId = ""
        isLoggedIn = false
        apps = []
        nodes = []
        hasAutoLoggedIn = false
    }
    
    // MARK: - Computed
    
    var quotaText: String { "\(usedToday)/\(dailyLimit)" }
    
    var daysRemaining: Int {
        guard !expiryDate.isEmpty else { return 0 }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        guard let date = formatter.date(from: expiryDate) else { return 0 }
        return Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
    }
    
    var unlockedApps: [OTP24App] { apps.filter { !$0.is_locked } }
    var lockedApps: [OTP24App] { apps.filter { $0.is_locked } }
}
