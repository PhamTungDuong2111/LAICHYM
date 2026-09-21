import SwiftUI

// MARK: - Home Dashboard View (100% Free Forever)
public struct HomeView: View {
    @ObservedObject var replayKit = ReplayKitManager.shared
    @ObservedObject var storage = StorageManager.shared
    @ObservedObject var userSettings = UserSettings.shared
    @ObservedObject var faceCam = FaceCamService.shared
    
    @State private var showLivestreamSheet = false
    @State private var showReactionSheet = false
    @State private var showEditorSheet = false
    @State private var showAboutSheet = false
    @State private var showSettings = false
    @State private var selectedVideoForDetail: RecordingItem? = nil
    @State private var recordModeSheet = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.06, green: 0.08, blue: 0.12).ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header Bar
                        headerView
                        
                        // 100% Free Feature Highlight Banner
                        freePromoBanner
                        
                        // Hero 1-Tap Record Card
                        recordHeroCard
                        
                        // Quick Action Tools Grid
                        featureToolsGrid
                        
                        // Recent Recordings Section
                        recentRecordingsSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                
                // Floating FaceCam if active
                FloatingFaceCamView()
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showLivestreamSheet) {
                LivestreamView()
            }
            .sheet(isPresented: $showReactionSheet) {
                ReactionStudioView()
            }
            .sheet(isPresented: $showEditorSheet) {
                VideoEditorView()
            }
            .sheet(isPresented: $showAboutSheet) {
                PaywallView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(item: $selectedVideoForDetail) { item in
                VideoDetailSheet(item: item)
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Thông báo"), message: Text(alertMessage), dismissButton: .default(Text("Đã hiểu")))
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            HStack(spacing: 10) {
                ZStack {
                    LinearGradient(
                        colors: [Color.red, Color.orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: 40, height: 40)
                    .cornerRadius(12)
                    
                    Image(systemName: "record.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .bold))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("LAICHYM")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Screen Recorder & Live")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: { showAboutSheet = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 13))
                        Text("MIỄN PHÍ")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.green.opacity(0.2)))
                    .overlay(Capsule().stroke(Color.green.opacity(0.5), lineWidth: 1))
                }
                
                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.system(size: 18))
                        .padding(8)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }
            }
        }
    }
    
    // MARK: - 100% Free Promo Banner
    private var freePromoBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                    Text("Ứng dụng mở khóa toàn bộ tính năng Miễn phí")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                Text("Quay 1080p 60fps, xóa logo, livestream không giới hạn hoàn toàn miễn phí")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "heart.fill")
                .foregroundColor(.red)
                .font(.system(size: 16))
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.3, blue: 0.2), Color(red: 0.05, green: 0.15, blue: 0.1)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.4), lineWidth: 1)
        )
    }
    
    // MARK: - Hero 1-Tap Record Card
    private var recordHeroCard: some View {
        GlassCard {
            VStack(spacing: 20) {
                // Status Header
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(replayKit.isRecording || replayKit.isBroadcastingSystem ? Color.red : Color.green)
                            .frame(width: 8, height: 8)
                        Text(replayKit.isRecording || replayKit.isBroadcastingSystem ? "ĐANG GHI HÌNH" : "SẴN SÀNG")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(replayKit.isRecording || replayKit.isBroadcastingSystem ? .red : .green)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.black.opacity(0.3)))
                    
                    Spacer()
                    
                    if replayKit.isRecording || replayKit.isBroadcastingSystem {
                        Text(String(format: "%02d:%02d", Int(replayKit.recordingDuration) / 60, Int(replayKit.recordingDuration) % 60))
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundColor(.red)
                    } else {
                        Text(userSettings.streamSettings.resolution.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                // Big Round Center Button
                ZStack {
                    // Pulsing Rings
                    Circle()
                        .stroke(Color.red.opacity(0.15), lineWidth: 20)
                        .frame(width: 140, height: 140)
                    
                    Circle()
                        .stroke(Color.red.opacity(0.3), lineWidth: 10)
                        .frame(width: 110, height: 110)
                    
                    // Main Record Trigger
                    Button(action: handleMainRecordButton) {
                        ZStack {
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.25, blue: 0.25), Color(red: 0.8, green: 0.0, blue: 0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .frame(width: 84, height: 84)
                            .clipShape(Circle())
                            .shadow(color: .red.opacity(0.5), radius: 15, x: 0, y: 5)
                            
                            VStack(spacing: 4) {
                                Image(systemName: replayKit.isRecording ? "stop.fill" : "record.circle")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                Text(replayKit.isRecording ? "DỪNG" : "GHI HÌNH")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
                
                // System Broadcast Overlay Option
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.inset.filled.and.person.filled")
                        .foregroundColor(.orange)
                        .font(.system(size: 14))
                    Text("Quay toàn hệ thống (Game/App khác):")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                    
                    // Native Broadcast Picker View button
                    BroadcastPickerRepresentable()
                        .frame(width: 32, height: 32)
                }
                .padding(8)
                .background(Color.white.opacity(0.06))
                .cornerRadius(10)
                
                Divider().background(Color.white.opacity(0.1))
                
                // Audio & FaceCam Quick Toggles
                HStack(spacing: 20) {
                    toggleButton(
                        icon: userSettings.streamSettings.enableMicrophone ? "mic.fill" : "mic.slash.fill",
                        title: "Microphone",
                        isActive: userSettings.streamSettings.enableMicrophone
                    ) {
                        userSettings.streamSettings.enableMicrophone.toggle()
                    }
                    
                    toggleButton(
                        icon: userSettings.streamSettings.enableSystemAudio ? "speaker.wave.2.fill" : "speaker.slash.fill",
                        title: "Âm thanh máy",
                        isActive: userSettings.streamSettings.enableSystemAudio
                    ) {
                        userSettings.streamSettings.enableSystemAudio.toggle()
                    }
                    
                    toggleButton(
                        icon: faceCam.isRunning ? "person.crop.circle.fill" : "person.crop.circle",
                        title: "Face-Cam",
                        isActive: faceCam.isRunning
                    ) {
                        if faceCam.isRunning {
                            faceCam.stopFaceCam()
                        } else {
                            faceCam.startFaceCam()
                        }
                    }
                }
            }
        }
    }
    
    private func handleMainRecordButton() {
        if replayKit.isRecording {
            // Dừng quay trực tiếp
            replayKit.stopDirectRecording { url in
                if url != nil {
                    alertMessage = "Ghi màn hình hoàn tất! Video đã được lưu vào Thư viện LAICHYM."
                    showAlert = true
                }
            }
        } else {
            // Bắt đầu quay màn hình trực tiếp
            replayKit.startDirectRecording(withMic: userSettings.streamSettings.enableMicrophone) { success, error in
                if !success, let error = error {
                    alertMessage = error
                    showAlert = true
                }
            }
        }
    }
    
    private func toggleButton(icon: String, title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isActive ? .white : .white.opacity(0.4))
                    .frame(width: 42, height: 42)
                    .background(
                        Circle().fill(isActive ? Color.red.opacity(0.8) : Color.white.opacity(0.08))
                    )
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isActive ? .white : .white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Feature Tools Grid
    private var featureToolsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            toolCard(
                title: "Phát trực tiếp",
                subtitle: "YouTube, Facebook, Twitch",
                icon: "antenna.radiowaves.left.and.right",
                gradient: [Color(red: 0.1, green: 0.4, blue: 0.9), Color(red: 0.05, green: 0.2, blue: 0.6)]
            ) {
                showLivestreamSheet = true
            }
            
            toolCard(
                title: "Reaction Studio",
                subtitle: "Lồng webcam & bình luận",
                icon: "face.smiling.fill",
                gradient: [Color(red: 0.9, green: 0.2, blue: 0.5), Color(red: 0.6, green: 0.1, blue: 0.3)]
            ) {
                showReactionSheet = true
            }
            
            toolCard(
                title: "Chỉnh sửa Video",
                subtitle: "Cắt, crop, lồng tiếng",
                icon: "scissors",
                gradient: [Color(red: 0.2, green: 0.7, blue: 0.4), Color(red: 0.1, green: 0.4, blue: 0.2)]
            ) {
                showEditorSheet = true
            }
            
            toolCard(
                title: "Hướng dẫn cài đặt",
                subtitle: "Bật Trung tâm điều khiển",
                icon: "questionmark.circle.fill",
                gradient: [Color(red: 0.4, green: 0.2, blue: 0.8), Color(red: 0.2, green: 0.1, blue: 0.5)]
            ) {
                showSettings = true
            }
        }
    }
    
    private func toolCard(title: String, subtitle: String, icon: String, gradient: [Color], action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: icon)
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .bold))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.3))
                        .font(.system(size: 12))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }
            }
            .padding(14)
            .background(.ultraThinMaterial)
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Recent Recordings
    private var recentRecordingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Video gần đây")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(storage.recordings.count) video")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            if storage.recordings.isEmpty {
                GlassCard {
                    VStack(spacing: 12) {
                        Image(systemName: "video.slash")
                            .font(.system(size: 36))
                            .foregroundColor(.white.opacity(0.3))
                        Text("Chưa có video quay màn hình nào")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        Text("Nhấn nút Ghi hình ở trên để bắt đầu quay clip đầu tiên của bạn")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(storage.recordings.prefix(6)) { item in
                            Button(action: { selectedVideoForDetail = item }) {
                                RecordingThumbnailCard(item: item)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Recording Thumbnail Card Component
struct RecordingThumbnailCard: View {
    let item: RecordingItem
    @State private var thumbnail: UIImage? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                if let thumb = thumbnail {
                    Image(uiImage: thumb)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 140, height: 90)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 140, height: 90)
                        .overlay(
                            Image(systemName: "film")
                                .foregroundColor(.white.opacity(0.3))
                                .font(.system(size: 24))
                        )
                }
                
                Text(item.formattedDuration)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(4)
                    .padding(6)
            }
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack {
                    Text(item.resolution)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                    Spacer()
                    Text(item.formattedFileSize)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .frame(width: 140)
        }
        .onAppear {
            StorageManager.shared.generateThumbnail(for: item) { img in
                self.thumbnail = img
            }
        }
    }
}
