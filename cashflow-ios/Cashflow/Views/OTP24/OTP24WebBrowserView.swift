import SwiftUI
import WebKit

// MARK: - OTP24 Web Browser (YouTube-style fullscreen)

struct OTP24WebBrowserView: View {
    let url: String
    let cookies: [OTP24Cookie]
    
    @Environment(\.dismiss) private var dismiss
    @State private var pageTitle = ""
    @State private var currentURL = ""
    @State private var progress: Double = 0
    @State private var isLoading = true
    @State private var injectedCount = 0
    @State private var webViewRef: WKWebView?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // ── WebView (เต็มจอ) ──
            WebViewContainer(
                url: url,
                cookies: cookies,
                pageTitle: $pageTitle,
                currentURL: $currentURL,
                progress: $progress,
                isLoading: $isLoading,
                webViewRef: $webViewRef,
                injectedCount: $injectedCount
            )
            .ignoresSafeArea(edges: .bottom)
            
            // ── Floating close button (มุมซ้ายบน) ──
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 30, height: 30)
                            .background(.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Cookie count badge
                    if injectedCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 10))
                            Text("\(injectedCount)")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.green.opacity(0.7))
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 4)
                
                // Progress bar
                if isLoading {
                    GeometryReader { geo in
                        Rectangle()
                            .fill(.green)
                            .frame(width: geo.size.width * progress, height: 2)
                    }
                    .frame(height: 2)
                }
                
                Spacer()
            }
        }
        .statusBarHidden(false)
    }
}

// MARK: - WKWebView Container

struct WebViewContainer: UIViewRepresentable {
    let url: String
    let cookies: [OTP24Cookie]
    
    @Binding var pageTitle: String
    @Binding var currentURL: String
    @Binding var progress: Double
    @Binding var isLoading: Bool
    @Binding var webViewRef: WKWebView?
    @Binding var injectedCount: Int
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        // --- 🚀 Inject Script เพื่อป้องกันการ Zoom และการคลุมดำข้อความ (ทำให้เหมือน Native App) ---
        let scriptSource = """
            var meta = document.createElement('meta');
            meta.name = 'viewport';
            meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
            document.getElementsByTagName('head')[0].appendChild(meta);
            
            var style = document.createElement('style');
            style.innerHTML = '* { -webkit-touch-callout: none; -webkit-user-select: none; user-select: none; }';
            document.head.appendChild(style);
        """
        let script = WKUserScript(source: scriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        config.userContentController.addUserScript(script)
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        webView.backgroundColor = .black
        
        // --- 🚀 ปิดเอฟเฟกต์เด้งและแถบเลื่อน เพื่อไม่ให้เหมือนการต่อผ่านหน้าเบราว์เซอร์ ---
        webView.scrollView.backgroundColor = .black
        webView.scrollView.bounces = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        
        // Custom User-Agent (เหมือน Chrome desktop เพื่อไม่ให้ redirect ไป mobile app)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
        
        // Observe progress & title
        webView.addObserver(context.coordinator, forKeyPath: "estimatedProgress", context: nil)
        webView.addObserver(context.coordinator, forKeyPath: "title", context: nil)
        webView.addObserver(context.coordinator, forKeyPath: "URL", context: nil)
        
        DispatchQueue.main.async {
            self.webViewRef = webView
        }
        
        // Inject cookies then load
        Task {
            let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
            
            // Clear existing
            if let targetURL = URL(string: url) {
                let baseDomain = targetURL.host?.replacingOccurrences(of: "www.", with: "") ?? ""
                await CookieManager.clearCookies(for: baseDomain, from: cookieStore)
            }
            
            // Inject all cookies (HttpOnly included!)
            await CookieManager.inject(cookies, into: cookieStore)
            
            DispatchQueue.main.async {
                self.injectedCount = cookies.count
            }
            
            // Load URL
            if let targetURL = URL(string: url) {
                DispatchQueue.main.async {
                    webView.load(URLRequest(url: targetURL))
                }
            }
        }
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: WebViewContainer
        
        init(_ parent: WebViewContainer) {
            self.parent = parent
        }
        
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
            guard let webView = object as? WKWebView else { return }
            
            DispatchQueue.main.async {
                if keyPath == "estimatedProgress" {
                    self.parent.progress = webView.estimatedProgress
                    self.parent.isLoading = webView.isLoading
                }
                if keyPath == "title" {
                    self.parent.pageTitle = webView.title ?? ""
                }
                if keyPath == "URL" {
                    self.parent.currentURL = webView.url?.absoluteString ?? ""
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.pageTitle = webView.title ?? ""
            }
        }
    }
}
