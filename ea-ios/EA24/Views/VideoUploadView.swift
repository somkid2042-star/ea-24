import SwiftUI
import AVKit

struct VideoItem: Identifiable {
    let id = UUID()
    let url: URL
}


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
    case downloadingTelegram(progress: Int)
    case uploading(progress: Int)
    case done(fileName: String, cloudLink: String, fileId: String)
    case error(String)
}

struct VideoUploadView: View {
    @EnvironmentObject var state: TradingState
    
    @State private var urlInput = ""
    @State private var selectedVideo: VideoItem?
    @FocusState private var isInputFocused: Bool
    @State private var showUploadSheet = false
    
    var body: some View {
        ZStack {
            // Background
            AuraGradients.mainBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AURA DROP")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .tracking(6)
                            .foregroundColor(AuraColors.textPrimary)
                        
                        let doneCount = state.uploadHistory.filter { $0.status == "done" }.count
                        Text("\(doneCount) videos")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AuraColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 24, weight: .light))
                        .foregroundStyle(AuraGradients.accentGlow)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 20)
                
                // Upload Progress (inline when active)
                if case .idle = state.videoUploadStatus {
                    // nothing
                } else {
                    progressView
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                }
                
                // Video Gallery
                if state.uploadHistory.isEmpty {
                    // Empty State
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "film.stack")
                            .font(.system(size: 56, weight: .ultraLight))
                            .foregroundColor(AuraColors.textSecondary.opacity(0.4))
                        
                        Text("NO VIDEOS YET")
                            .font(.system(size: 13, weight: .bold))
                            .tracking(3)
                            .foregroundColor(AuraColors.textSecondary.opacity(0.5))
                        
                        Text("Tap + to download from Telegram")
                            .font(.system(size: 13))
                            .foregroundColor(AuraColors.textSecondary.opacity(0.3))
                    }
                    Spacer()
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(state.uploadHistory) { record in
                                videoCard(record)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 100) // space for floating button
                    }
                }
            }
            
            // Floating Add Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showUploadSheet = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(width: 60, height: 60)
                            .background(AuraGradients.accentGlow)
                            .clipShape(Circle())
                            .shadow(color: AuraColors.accent.opacity(0.4), radius: 15, x: 0, y: 5)
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 32)
                }
            }
        }
        .onAppear {
            state.requestGcsConfig()
        }
        .sheet(isPresented: $showUploadSheet) {
            uploadSheet
        }
        .fullScreenCover(item: $selectedVideo) { item in
            ZStack(alignment: .topTrailing) {
                Color.black.ignoresSafeArea()
                
                VideoPlayer(player: AVPlayer(url: item.url))
                    .ignoresSafeArea()
                
                Button(action: { selectedVideo = nil }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(24)
                }
            }
        }
    }
    
    // MARK: - Upload Sheet
    
    private var uploadSheet: some View {
        ZStack {
            AuraGradients.mainBackground.ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Handle
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)
                
                // Title
                VStack(spacing: 8) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(AuraGradients.accentGlow)
                    
                    Text("NEW DROP")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .tracking(4)
                        .foregroundColor(AuraColors.textPrimary)
                }
                
                // Input
                VStack(spacing: 20) {
                    TextField("Paste Telegram URL...", text: $urlInput)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 18)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(isInputFocused ? AuraColors.accent : Color.clear, lineWidth: 1)
                        )
                        .foregroundColor(.white)
                        .tint(AuraColors.accent)
                        .focused($isInputFocused)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Button(action: {
                        startUpload()
                        showUploadSheet = false
                    }) {
                        Text("INITIALIZE TRANSFER")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .tracking(2)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(AuraGradients.accentGlow)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .shadow(color: AuraColors.accent.opacity(0.3), radius: 15, x: 0, y: 5)
                    }
                    .disabled(urlInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(urlInput.isEmpty ? 0.5 : 1.0)
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
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
            case .downloadingTelegram(let p):
                activeIndicator(text: "DOWNLOADING FROM TELEGRAM", progress: CGFloat(p))
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
                
            Button("CANCEL") {
                state.videoUploadStatus = .idle
                urlInput = ""
            }
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white.opacity(0.3))
            .padding(.top, 8)
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
            
            Button("PLAY VIDEO") {
                if let url = URL(string: link) {
                    selectedVideo = VideoItem(url: url)
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
    
    // MARK: - Video Card (Full Width)
    
    private func videoCard(_ record: VideoUploadRecord) -> some View {
        Button(action: {
            if record.status == "done", let link = record.cloud_link, let url = URL(string: link) {
                selectedVideo = VideoItem(url: url)
            }
        }) {
            HStack(spacing: 16) {
                // Thumbnail icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            record.status == "done"
                            ? AuraColors.accent.opacity(0.15)
                            : (record.status == "error" ? AuraColors.error.opacity(0.15) : Color.white.opacity(0.05))
                        )
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: record.status == "done" ? "play.circle.fill" : (record.status == "error" ? "xmark.circle" : "arrow.down.circle"))
                        .font(.system(size: 24))
                        .foregroundColor(record.status == "done" ? AuraColors.accent : (record.status == "error" ? AuraColors.error : AuraColors.textSecondary))
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.file_name)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        if record.status == "done" {
                            Text("READY")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(1)
                                .foregroundColor(AuraColors.success)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(AuraColors.success.opacity(0.15))
                                .clipShape(Capsule())
                        } else if record.status == "error" {
                            Text("FAILED")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(1)
                                .foregroundColor(AuraColors.error)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(AuraColors.error.opacity(0.15))
                                .clipShape(Capsule())
                        }
                        
                        if let ts = record.timestamp {
                            Text(ts.formatted(.dateTime.month().day().hour().minute()))
                                .font(.system(size: 10))
                                .foregroundColor(AuraColors.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                // Arrow if playable
                if record.status == "done" {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AuraColors.textSecondary)
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
    }
    
    private func startUpload() {
        guard !urlInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isInputFocused = false
        state.uploadVideoFromURL(urlInput)
    }
}

// MARK: - Helper font modifier for convenience
extension Font {
    static func line(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
