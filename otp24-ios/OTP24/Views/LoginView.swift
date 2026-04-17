import SwiftUI

struct LoginView: View {
    @EnvironmentObject var api: APIService
    @State private var licenseKey = ""
    @State private var isAnimating = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Logo Area
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(OTPColors.accent.opacity(0.1))
                        .frame(width: 100, height: 100)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                    
                    Image(systemName: "key.viewfinder")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(OTPGradients.accent)
                }
                
                Text("OTP24HR")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(OTPColors.textPrimary)
                
                Text("PREMIUM ACCESS")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(4)
                    .foregroundColor(OTPColors.accent)
            }
            .padding(.bottom, 50)
            
            // Input Card
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("LICENSE KEY")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(2)
                        .foregroundColor(OTPColors.textDim)
                    
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundColor(OTPColors.accent.opacity(0.6))
                            .font(.system(size: 14))
                        
                        TextField("XXXX-XXXX-XXXX-XXXX", text: $licenseKey)
                            .font(.system(size: 15, weight: .medium, design: .monospaced))
                            .foregroundColor(OTPColors.textPrimary)
                            .autocapitalization(.allCharacters)
                            .disableAutocorrection(true)
                            .focused($isFocused)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(OTPColors.bgPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                isFocused ? OTPColors.accent.opacity(0.5) : OTPColors.glassBorder,
                                lineWidth: isFocused ? 1.5 : 0.5
                            )
                    )
                }
                
                // Login Button
                Button(action: {
                    Task { try? await api.login(key: licenseKey) }
                }) {
                    HStack(spacing: 10) {
                        if api.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.right.circle.fill")
                        }
                        Text(api.isLoading ? "CHECKING..." : "ACTIVATE")
                            .font(.system(size: 14, weight: .bold))
                            .tracking(2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(OTPGradients.accent)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: OTPColors.accent.opacity(0.3), radius: 12, y: 6)
                }
                .disabled(licenseKey.isEmpty || api.isLoading)
                .opacity(licenseKey.isEmpty ? 0.5 : 1)
                
                // Error
                if let error = api.errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                        Text(error)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(OTPColors.danger)
                    .padding(.top, 4)
                }
            }
            .padding(24)
            .glassCard(radius: 20)
            .padding(.horizontal, 24)
            
            // Skip Button
            Button(action: {
                Task { await api.skipLogin() }
            }) {
                HStack(spacing: 6) {
                    if api.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: OTPColors.textDim))
                            .scaleEffect(0.7)
                    }
                    Text(api.isLoading ? "CONNECTING..." : "SKIP")
                        .font(.system(size: 13, weight: .semibold))
                        .tracking(2)
                        .foregroundColor(OTPColors.textDim)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 30)
            }
            .disabled(api.isLoading)
            .padding(.top, 20)
            
            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
            // Auto-fill saved key
            if let saved = UserDefaults.standard.string(forKey: "license_key") {
                licenseKey = saved
            }
        }
    }
}
