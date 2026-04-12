import SwiftUI

struct VideoUploadRecord: Codable, Identifiable {
    var id: String { job_id }
    let job_id: String
    let file_name: String
    let status: String
    let error: String?
    let cloud_link: String?
    let timestamp: Date?
}

enum VideoUploadStatus: Equatable {
    case idle
    case started
    case downloading(progress: Int)
    case uploading(progress: Int)
    case done(fileName: String, cloudLink: String, fileId: String)
    case error(String)
}

struct VideoUploadView: View {
    @EnvironmentObject var state: TradingState
    
    @State private var urlInput = ""
    @State private var showSettings = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        ZStack {
            // Background
            AuraGradients.mainBackground.ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Header
                HStack {
                    Spacer()
                    Button(action: { showSettings = true }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 22, weight: .regular))
                            .foregroundColor(AuraColors.textSecondary)
                    }
                    .padding(24)
                }
                
                Spacer()
                
                // Main Content
                VStack(spacing: 32) {
                    
                    // App Branding / Title
                    VStack(spacing: 8) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(AuraGradients.accentGlow)
                        
                        Text("AURA DROP")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .tracking(8)
                            .foregroundColor(AuraColors.textPrimary)
                    }
                    .padding(.bottom, 20)
                    
                    // Input Area
                    VStack(spacing: 24) {
                        TextField("Paste video URL...", text: $urlInput)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 20)
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .strokeBorder(isInputFocused ? AuraColors.accent : Color.clear, lineWidth: 1)
                            )
                            .foregroundColor(.white)
                            .tint(AuraColors.accent)
                            .focused($isInputFocused)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .animation(.easeOut(duration: 0.2), value: isInputFocused)
                        
                        // Action Button
                        if case .idle = state.videoUploadStatus {
                            Button(action: startUpload) {
                                Text("INITIALIZE TRANSFER")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .tracking(2)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                    .background(AuraGradients.accentGlow)
                                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                    .shadow(color: AuraColors.accent.opacity(0.3), radius: 15, x: 0, y: 5)
                            }
                            .disabled(urlInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .opacity(urlInput.isEmpty ? 0.5 : 1.0)
                        } else {
                            progressView
                        }
                    }
                    .padding(.horizontal, 32)
                }
                
                Spacer()
                
                // History Hint (only if exists)
                if !state.uploadHistory.isEmpty {
                    VStack(spacing: 16) {
                        Text("RECENT TRANSFERS")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(4)
                            .foregroundColor(AuraColors.textSecondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(state.uploadHistory.prefix(5)) { record in
                                    historyCard(record)
                                }
                            }
                            .padding(.horizontal, 32)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            state.requestGcsConfig()
        }
        .sheet(isPresented: $showSettings) {
            GcsSetupSheet()
                .environmentObject(state)
                .presentationDetents([.fraction(0.8)])
                .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Progress View
    
    @ViewBuilder
    private var progressView: some View {
        VStack(spacing: 16) {
            switch state.videoUploadStatus {
            case .started:
                activeIndicator(text: "CONNECTING...", progress: 0)
            case .downloading(let p):
                activeIndicator(text: "DOWNLOADING TO SERVER", progress: CGFloat(p))
            case .uploading(let p):
                activeIndicator(text: "UPLOADING TO CLOUD", progress: CGFloat(p))
            case .done(let name, let link, _):
                successIndicator(name: name, link: link)
            case .error(let error):
                errorIndicator(error: error)
            default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .glass(cornerRadius: 24)
    }
    
    private func activeIndicator(text: String, progress: CGFloat) -> some View {
        VStack(spacing: 16) {
            Text(text)
                .font(.system(size: 12, weight: .bold))
                .tracking(2)
                .foregroundColor(AuraColors.accent)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 4)
                    
                    Capsule()
                        .fill(AuraGradients.accentGlow)
                        .frame(width: max(0, min(geo.size.width * (progress / 100.0), geo.size.width)), height: 4)
                        .shadow(color: AuraColors.accent.opacity(0.5), radius: 5, x: 0, y: 0)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 24)
            
            Text("\(Int(progress))%")
                .font(.system(size: 32, weight: .thin, design: .rounded))
                .foregroundColor(.white)
        }
    }
    
    private func successIndicator(name: String, link: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(AuraColors.success)
            
            Text("TRANSFER COMPLETE")
                .font(.system(size: 12, weight: .bold))
                .tracking(2)
                .foregroundColor(AuraColors.success)
            
            Button("OPEN IN CLOUD") {
                if let url = URL(string: link) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(Color.white.opacity(0.1))
            .clipShape(Capsule())
            
            Button("NEW DROP") {
                state.videoUploadStatus = .idle
                urlInput = ""
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(AuraColors.textSecondary)
            .padding(.top, 8)
        }
    }
    
    private func errorIndicator(error: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundColor(AuraColors.error)
            
            Text("TRANSFER FAILED")
                .font(.system(size: 12, weight: .bold))
                .tracking(2)
                .foregroundColor(AuraColors.error)
            
            Text(error)
                .font(.system(size: 12))
                .foregroundColor(AuraColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("RETRY") {
                state.videoUploadStatus = .idle
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(AuraColors.error)
            .padding(.top, 8)
        }
    }
    
    // MARK: - History Card
    
    private func historyCard(_ record: VideoUploadRecord) -> some View {
        Button(action: {
            if record.status == "done", let link = record.cloud_link, let url = URL(string: link) {
                UIApplication.shared.open(url)
            }
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(record.status == "done" ? AuraColors.success : (record.status == "error" ? AuraColors.error : AuraColors.accent))
                        .frame(width: 6, height: 6)
                    
                    Text(record.file_name.prefix(15) + (record.file_name.count > 15 ? "..." : ""))
                        .font(.line(13, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                
                if let ts = record.timestamp {
                    Text(ts.formatted(.dateTime.month().day().hour().minute()))
                        .font(.system(size: 10))
                        .foregroundColor(AuraColors.textSecondary)
                }
            }
            .padding(16)
            .frame(width: 160, alignment: .leading)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
    }
    
    private func startUpload() {
        guard !urlInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isInputFocused = false
        state.uploadVideoFromURL(urlInput)
    }
}

// MARK: - GCS Settings Sheet
struct GcsSetupSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var state: TradingState
    
    @State private var saJson: String = ""
    @State private var bucketNameText: String = ""
    
    var body: some View {
        ZStack {
            AuraColors.backgroundStart.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Text("GOOGLE CLOUD STORAGE")
                        .font(.system(size: 14, weight: .bold))
                        .tracking(2)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AuraColors.textSecondary)
                    }
                }
                .padding(24)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("SERVICE ACCOUNT JSON")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.5)
                                .foregroundColor(AuraColors.textSecondary)
                            
                            TextEditor(text: $saJson)
                                .font(.system(size: 12, design: .monospaced))
                                .frame(height: 180)
                                .padding(12)
                                .scrollContentBackground(.hidden)
                                .background(Color.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .foregroundColor(AuraColors.accent)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("TARGET BUCKET NAME (OPTIONAL)")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.5)
                                .foregroundColor(AuraColors.textSecondary)
                            
                            TextField("", text: $bucketNameText)
                                .padding(16)
                                .background(Color.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .foregroundColor(.white)
                        }
                        
                        Spacer().frame(height: 20)
                        
                        Button(action: save) {
                            Text("COMMIT CONFIGURATION")
                                .font(.system(size: 12, weight: .bold))
                                .tracking(2)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(AuraGradients.accentGlow)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .onAppear {
            if state.gcsConfigured {
                saJson = "/// Server already configured ///\n/// Paste new JSON to override ///"
            }
            bucketNameText = state.bucketName
        }
    }
    
    private func save() {
        let jsonToSave = saJson.contains("/// Server already configured") ? nil : saJson
        state.saveGcsConfig(serviceAccountJSON: jsonToSave, bucketName: bucketNameText.isEmpty ? nil : bucketNameText)
        dismiss()
    }
}

// Helper font modifier for convenience
extension Font {
    static func line(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
