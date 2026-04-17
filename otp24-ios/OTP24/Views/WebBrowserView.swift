import SwiftUI
import WebKit

// MARK: - Web Browser View (ฉีด Cookie แล้วเปิด URL)

struct WebBrowserView: View {
    let cookies: [CookieData]
    let targetUrl: String
    @Environment(\.dismiss) var dismiss
    @State private var isInjecting = true
    @State private var pageTitle = "Loading..."
    
    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                        Text("CLOSE")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1)
                    }
                    .foregroundColor(OTPColors.textSecondary)
                }
                
                Spacer()
                
                Text(pageTitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(OTPColors.textDim)
                    .lineLimit(1)
                
                Spacer()
                
                // Placeholder for symmetry
                Color.clear.frame(width: 80, height: 1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(OTPColors.bgSecondary)
            
            // WebView
            if isInjecting {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: OTPColors.accent))
                        .scaleEffect(1.2)
                    Text("INJECTING COOKIES...")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(2)
                        .foregroundColor(OTPColors.textDim)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(OTPColors.bgPrimary)
            } else {
                CookieWebView(
                    cookies: cookies,
                    targetUrl: targetUrl,
                    pageTitle: $pageTitle
                )
            }
        }
        .background(OTPColors.bgPrimary)
        .task {
            // Small delay for animation
            try? await Task.sleep(nanoseconds: 500_000_000)
            isInjecting = false
        }
    }
}

// MARK: - WKWebView with Cookie Injection

struct CookieWebView: UIViewRepresentable {
    let cookies: [CookieData]
    let targetUrl: String
    @Binding var pageTitle: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        webView.backgroundColor = UIColor(OTPColors.bgPrimary)
        
        // Inject cookies then load URL
        Task { @MainActor in
            let store = webView.configuration.websiteDataStore.httpCookieStore
            
            for cookie in cookies {
                var props: [HTTPCookiePropertyKey: Any] = [
                    .name: cookie.name,
                    .value: cookie.value,
                    .path: cookie.path ?? "/",
                    .domain: cookie.effectiveDomain
                ]
                
                if let secure = cookie.secure, secure {
                    props[.secure] = "TRUE"
                }
                
                if let expiry = cookie.expirationDate ?? cookie.ExpiresDate {
                    props[.expires] = Date(timeIntervalSince1970: expiry)
                }
                
                if let httpCookie = HTTPCookie(properties: props) {
                    await store.setCookie(httpCookie)
                }
            }
            
            // Load target URL
            if let url = URL(string: targetUrl) {
                webView.load(URLRequest(url: url))
            }
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: CookieWebView
        
        init(_ parent: CookieWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.pageTitle = webView.title ?? webView.url?.host ?? "Loaded"
            }
        }
    }
}
