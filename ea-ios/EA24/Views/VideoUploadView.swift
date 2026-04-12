import SwiftUI

// MARK: - Video Upload Status
enum VideoUploadStatus: Equatable {
    case idle
    case started
    case downloading(progress: Int)
    case uploading(progress: Int)
    case done(fileName: String, driveLink: String, fileId: String)
    case error(String)
}

// MARK: - Upload History Record
struct VideoUploadRecord: Identifiable, Codable {
    var id: String { job_id }
    let job_id: String
    let file_name: String
    let file_id: String
    let drive_link: String
    let size_bytes: Int
    let source_url: String
    let uploaded_at: String
}

// MARK: - VideoUploadView
struct VideoUploadView: View {
    @EnvironmentObject var state: TradingState
    @State private var videoURL: String = ""
    @State private var showDriveSetup = false
    @State private var copiedLink = false
    @FocusState private var urlFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    // ─── Upload Card ───
                    uploadInputSection

                    // ─── Status Card ───
                    if state.videoUploadStatus != .idle {
                        uploadStatusSection
                    }

                    // ─── Drive Config Banner ───
                    if !state.driveConfigured {
                        driveSetupBanner
                    }

                    // ─── History ───
                    if !state.uploadHistory.isEmpty {
                        uploadHistorySection
                    }

                    Spacer(minLength: 30)
                }
                .padding()
            }
            .teofinBackground()
            .navigationTitle("Video Upload")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showDriveSetup = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(ThemeFont.custom(size: 16, weight: .medium))
                            .foregroundStyle(TeofinColors.accentEnd)
                    }
                }
            }
            .sheet(isPresented: $showDriveSetup) {
                DriveSetupSheet()
                    .environmentObject(state)
            }
            .onAppear {
                state.requestDriveConfig()
            }
        }
    }

    // MARK: - Upload Input
    var uploadInputSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("Video URL")

            VStack(spacing: 14) {
                // URL Input
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(TeofinColors.accentEnd.opacity(0.1))
                            .frame(width: 38, height: 38)
                        Image(systemName: "link")
                            .font(ThemeFont.custom(size: 15, weight: .medium))
                            .foregroundStyle(TeofinColors.accentEnd)
                    }

                    TextField("https://example.com/video.mp4", text: $videoURL)
                        .font(ThemeFont.custom(size: 14, weight: .regular))
                        .foregroundStyle(TeofinColors.title)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .focused($urlFieldFocused)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(TeofinColors.inputBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    if !videoURL.isEmpty {
                        Button {
                            videoURL = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(TeofinColors.caption)
                                .font(.system(size: 18))
                        }
                    }
                }

                // Paste from clipboard
                Button {
                    if let str = UIPasteboard.general.string {
                        videoURL = str
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.clipboard")
                            .font(ThemeFont.custom(size: 13, weight: .medium))
                        Text("Paste from Clipboard")
                            .font(ThemeFont.custom(size: 13, weight: .medium))
                    }
                    .foregroundStyle(TeofinColors.accentEnd)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(TeofinColors.accentEnd.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                // Upload Button
                TeofinButton(
                    title: isUploading ? "Uploading..." : "Upload to Google Drive",
                    icon: isUploading ? "arrow.up.circle" : "arrow.up.to.line.circle"
                ) {
                    guard !videoURL.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    urlFieldFocused = false
                    state.uploadVideoFromURL(videoURL.trimmingCharacters(in: .whitespaces))
                }
                .disabled(isUploading || videoURL.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity((isUploading || videoURL.isEmpty) ? 0.6 : 1.0)

                Text("Supported: direct .mp4 / .mov / .avi / .mkv links")
                    .font(ThemeFont.custom(size: 11, weight: .regular))
                    .foregroundStyle(TeofinColors.caption)
            }
            .teofinCard()
        }
    }

    // MARK: - Status Section
    var uploadStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Upload Status")

            VStack(spacing: 16) {
                switch state.videoUploadStatus {
                case .idle:
                    EmptyView()

                case .started:
                    statusRow(
                        icon: "arrow.down.circle",
                        iconColor: TeofinColors.accentEnd,
                        title: "Starting...",
                        subtitle: "Server acknowledged request",
                        customView: nil
                    )

                case .downloading(let progress):
                    statusRow(
                        icon: "arrow.down.circle.fill",
                        iconColor: TeofinColors.actionBlue,
                        title: "Downloading",
                        subtitle: "\(progress)% — Fetching video from URL",
                        customView: AnyView(progressBar(progress: Double(progress) / 100.0, color: TeofinColors.actionBlue))
                    )

                case .uploading(let progress):
                    statusRow(
                        icon: "arrow.up.circle.fill",
                        iconColor: TeofinColors.actionGreen,
                        title: "Uploading to Drive",
                        subtitle: "\(progress)% — Sending to Google Drive",
                        customView: AnyView(progressBar(progress: Double(progress) / 100.0, color: TeofinColors.actionGreen))
                    )

                case .done(let fileName, let driveLink, _):
                    VStack(spacing: 14) {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(TeofinColors.online.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(TeofinColors.online)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Upload Complete")
                                    .font(ThemeFont.custom(size: 15, weight: .semibold))
                                    .foregroundStyle(TeofinColors.title)
                                Text(fileName)
                                    .font(ThemeFont.custom(size: 12, weight: .regular))
                                    .foregroundStyle(TeofinColors.caption)
                                    .lineLimit(1)
                            }
                            Spacer()
                        }

                        // Drive Link Buttons
                        HStack(spacing: 10) {
                            Button {
                                UIPasteboard.general.string = driveLink
                                copiedLink = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    copiedLink = false
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: copiedLink ? "checkmark" : "doc.on.doc")
                                        .font(ThemeFont.custom(size: 13, weight: .medium))
                                    Text(copiedLink ? "Copied!" : "Copy Link")
                                        .font(ThemeFont.custom(size: 13, weight: .medium))
                                }
                                .foregroundStyle(TeofinColors.accentEnd)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(TeofinColors.accentEnd.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }

                            Button {
                                if let url = URL(string: driveLink) {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.up.right.square")
                                        .font(ThemeFont.custom(size: 13, weight: .medium))
                                    Text("Open Drive")
                                        .font(ThemeFont.custom(size: 13, weight: .medium))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(TeofinGradients.accentButton)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                    }

                case .error(let message):
                    HStack(alignment: .top, spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(TeofinColors.offline.opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(TeofinColors.offline)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Upload Failed")
                                .font(ThemeFont.custom(size: 15, weight: .semibold))
                                .foregroundStyle(TeofinColors.title)
                            Text(message)
                                .font(ThemeFont.custom(size: 12, weight: .regular))
                                .foregroundStyle(TeofinColors.offline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                    }
                }

                // Reset button (when done or error)
                if case .done = state.videoUploadStatus {
                    Button {
                        videoURL = ""
                        state.videoUploadStatus = .idle
                    } label: {
                        Text("Upload Another")
                            .font(ThemeFont.custom(size: 14, weight: .medium))
                            .foregroundStyle(TeofinColors.accentEnd)
                    }
                } else if case .error = state.videoUploadStatus {
                    Button {
                        state.videoUploadStatus = .idle
                    } label: {
                        Text("Dismiss")
                            .font(ThemeFont.custom(size: 14, weight: .medium))
                            .foregroundStyle(TeofinColors.caption)
                    }
                }
            }
            .teofinCard()
        }
    }

    // MARK: - Drive Setup Banner
    var driveSetupBanner: some View {
        Button {
            showDriveSetup = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(TeofinColors.actionGold.opacity(0.15))
                        .frame(width: 42, height: 42)
                    Image(systemName: "key.horizontal")
                        .font(ThemeFont.custom(size: 18, weight: .medium))
                        .foregroundStyle(TeofinColors.actionGold)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Setup Google Drive")
                        .font(ThemeFont.custom(size: 15, weight: .semibold))
                        .foregroundStyle(TeofinColors.title)
                    Text("Paste your Service Account JSON to enable uploads")
                        .font(ThemeFont.custom(size: 12, weight: .regular))
                        .foregroundStyle(TeofinColors.caption)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(ThemeFont.custom(size: 13, weight: .medium))
                    .foregroundStyle(TeofinColors.caption)
            }
            .padding(16)
            .background(TeofinColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(TeofinColors.actionGold.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Upload History
    var uploadHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Recent Uploads")

            VStack(spacing: 0) {
                ForEach(Array(state.uploadHistory.prefix(10).enumerated()), id: \.element.id) { idx, record in
                    historyRow(record: record)

                    if idx < min(state.uploadHistory.count - 1, 9) {
                        TeofinColors.divider.frame(height: 1).padding(.leading, 60)
                    }
                }
            }
            .teofinCard(padding: 0)
        }
    }

    func historyRow(record: VideoUploadRecord) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(TeofinColors.online.opacity(0.1))
                    .frame(width: 38, height: 38)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(TeofinColors.online)
            }
            .padding(.leading, 16)

            VStack(alignment: .leading, spacing: 3) {
                Text(record.file_name)
                    .font(ThemeFont.custom(size: 14, weight: .semibold))
                    .foregroundStyle(TeofinColors.title)
                    .lineLimit(1)
                Text(formatBytes(record.size_bytes))
                    .font(ThemeFont.custom(size: 11, weight: .regular))
                    .foregroundStyle(TeofinColors.caption)
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    UIPasteboard.general.string = record.drive_link
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 14))
                        .foregroundStyle(TeofinColors.accentEnd)
                }

                Button {
                    if let url = URL(string: record.drive_link) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 14))
                        .foregroundStyle(TeofinColors.accentEnd)
                }
            }
            .padding(.trailing, 16)
        }
        .padding(.vertical, 14)
    }

    // MARK: - Helpers
    private var isUploading: Bool {
        switch state.videoUploadStatus {
        case .started, .downloading, .uploading: return true
        default: return false
        }
    }

    func statusRow(icon: String, iconColor: Color, title: String, subtitle: String, customView: AnyView?) -> some View {
        VStack(spacing: 10) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(iconColor)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(ThemeFont.custom(size: 15, weight: .semibold))
                        .foregroundStyle(TeofinColors.title)
                    Text(subtitle)
                        .font(ThemeFont.custom(size: 12, weight: .regular))
                        .foregroundStyle(TeofinColors.caption)
                }
                Spacer()
            }
            if let custom = customView {
                custom
            }
        }
    }

    func progressBar(progress: Double, color: Color) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(height: 8)
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(color)
                    .frame(width: geo.size.width * max(0.02, min(1.0, progress)), height: 8)
                    .animation(.spring(response: 0.4), value: progress)
            }
        }
        .frame(height: 8)
    }

    func formatBytes(_ bytes: Int) -> String {
        let mb = Double(bytes) / 1_048_576
        if mb >= 1000 {
            return String(format: "%.1f GB", mb / 1024)
        }
        return String(format: "%.1f MB", mb)
    }

    func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(ThemeFont.custom(size: 12, weight: .semibold))
            .foregroundStyle(TeofinColors.caption)
            .tracking(0.8)
            .padding(.horizontal, 4)
    }
}

// MARK: - Drive Setup Sheet
struct DriveSetupSheet: View {
    @EnvironmentObject var state: TradingState
    @Environment(\.dismiss) var dismiss
    @State private var serviceAccountJSON: String = ""
    @State private var folderID: String = ""
    @State private var showJSONInfo = false
    @State private var isSaving = false
    @State private var saveSuccess = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    // Status banner
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(state.driveConfigured ? TeofinColors.online.opacity(0.12) : TeofinColors.actionGold.opacity(0.12))
                                .frame(width: 44, height: 44)
                            Image(systemName: state.driveConfigured ? "checkmark.shield.fill" : "shield.slash")
                                .font(.system(size: 20))
                                .foregroundStyle(state.driveConfigured ? TeofinColors.online : TeofinColors.actionGold)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(state.driveConfigured ? "Drive Connected" : "Drive Not Configured")
                                .font(ThemeFont.custom(size: 15, weight: .semibold))
                                .foregroundStyle(TeofinColors.title)
                            Text(state.driveConfigured ? "Service Account is set on server" : "Paste Service Account JSON below")
                                .font(ThemeFont.custom(size: 12, weight: .regular))
                                .foregroundStyle(TeofinColors.caption)
                        }
                        Spacer()
                    }
                    .teofinCard()

                    // Service Account JSON
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            sectionLabel("Service Account JSON")
                            Spacer()
                            Button {
                                showJSONInfo = true
                            } label: {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 16))
                                    .foregroundStyle(TeofinColors.accentEnd)
                            }
                        }

                        TextEditor(text: $serviceAccountJSON)
                            .font(ThemeFont.custom(size: 12, weight: .regular))
                            .foregroundStyle(TeofinColors.title)
                            .frame(height: 140)
                            .padding(12)
                            .background(TeofinColors.inputBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                Group {
                                    if serviceAccountJSON.isEmpty {
                                        VStack {
                                            HStack {
                                                Text("{ \"type\": \"service_account\", ... }")
                                                    .font(ThemeFont.custom(size: 12, weight: .regular))
                                                    .foregroundStyle(TeofinColors.caption)
                                                    .padding(.horizontal, 16)
                                                    .padding(.top, 16)
                                                Spacer()
                                            }
                                            Spacer()
                                        }
                                    }
                                }
                            )

                        Button {
                            if let str = UIPasteboard.general.string {
                                serviceAccountJSON = str
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.on.clipboard")
                                    .font(ThemeFont.custom(size: 13, weight: .medium))
                                Text("Paste JSON from Clipboard")
                                    .font(ThemeFont.custom(size: 13, weight: .medium))
                            }
                            .foregroundStyle(TeofinColors.accentEnd)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(TeofinColors.accentEnd.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                    .teofinCard()

                    // Folder ID (optional)
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("Drive Folder ID (Optional)")

                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(TeofinColors.accentEnd.opacity(0.1))
                                    .frame(width: 38, height: 38)
                                Image(systemName: "folder")
                                    .font(ThemeFont.custom(size: 15, weight: .medium))
                                    .foregroundStyle(TeofinColors.accentEnd)
                            }
                            TextField("Leave empty to auto-create 'EA24-Videos'", text: $folderID)
                                .font(ThemeFont.custom(size: 13, weight: .regular))
                                .foregroundStyle(TeofinColors.title)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                                .background(TeofinColors.inputBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        if !state.driveFolderID.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "folder.fill.badge.checkmark")
                                    .font(.system(size: 12))
                                    .foregroundStyle(TeofinColors.online)
                                Text("Current folder: \(state.driveFolderID)")
                                    .font(ThemeFont.custom(size: 11, weight: .regular))
                                    .foregroundStyle(TeofinColors.caption)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .teofinCard()

                    // Save Button
                    TeofinButton(
                        title: saveSuccess ? "Saved!" : (isSaving ? "Saving..." : "Save Configuration"),
                        icon: saveSuccess ? "checkmark.circle" : "square.and.arrow.down"
                    ) {
                        saveConfig()
                    }
                    .disabled(serviceAccountJSON.isEmpty && folderID.isEmpty)
                    .opacity((serviceAccountJSON.isEmpty && folderID.isEmpty) ? 0.6 : 1.0)

                    Spacer(minLength: 20)
                }
                .padding()
            }
            .teofinBackground()
            .navigationTitle("Drive Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(ThemeFont.custom(size: 15, weight: .semibold))
                        .foregroundStyle(TeofinColors.accentEnd)
                }
            }
            .alert("How to get Service Account JSON", isPresented: $showJSONInfo) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("1. Go to Google Cloud Console\n2. Create/select a project\n3. Enable Google Drive API\n4. Go to IAM > Service Accounts\n5. Create service account\n6. Download JSON key\n7. Share your Drive folder with the service account email")
            }
            .onAppear {
                folderID = state.driveFolderID
            }
        }
    }

    func saveConfig() {
        isSaving = true
        var saJSON: String? = nil
        var folderIDOpt: String? = nil

        if !serviceAccountJSON.trimmingCharacters(in: .whitespaces).isEmpty {
            saJSON = serviceAccountJSON
        }
        if !folderID.trimmingCharacters(in: .whitespaces).isEmpty {
            folderIDOpt = folderID
        }

        state.saveDriveConfig(serviceAccountJSON: saJSON, folderID: folderIDOpt)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isSaving = false
            saveSuccess = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                saveSuccess = false
                dismiss()
            }
        }
    }

    func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(ThemeFont.custom(size: 12, weight: .semibold))
            .foregroundStyle(TeofinColors.caption)
            .tracking(0.8)
            .padding(.horizontal, 4)
    }
}

#Preview {
    VideoUploadView()
        .environmentObject(TradingState())
}
