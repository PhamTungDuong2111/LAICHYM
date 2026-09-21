import SwiftUI

// MARK: - Livestream Setup & Broadcast View
public struct LivestreamView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var userSettings = UserSettings.shared
    @ObservedObject var replayKit = ReplayKitManager.shared
    @ObservedObject var rtmpStreamer = RTMPStreamer.shared
    
    @State private var selectedPlatform: LivePlatform = .youtube
    @State private var serverUrl: String = ""
    @State private var streamKey: String = ""
    @State private var isTestingConnection: Bool = false
    @State private var testResult: (success: Bool, message: String)? = nil
    @State private var isSecureKeyVisible: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.06, green: 0.08, blue: 0.12).ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Platform Selector
                        platformPicker
                        
                        // Setup Instructions
                        platformHelpCard
                        
                        // RTMP Credentials Form
                        credentialsCard
                        
                        // Quality & Stream Parameters
                        qualitySettingsCard
                        
                        // Start Broadcast CTA
                        broadcastActionSection
                        
                        Spacer(minLength: 30)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("Phát trực tiếp")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .onAppear {
                self.selectedPlatform = userSettings.lastStreamDestination.platform
                self.serverUrl = userSettings.lastStreamDestination.serverUrl.isEmpty ? selectedPlatform.defaultRtmpUrl : userSettings.lastStreamDestination.serverUrl
                self.streamKey = userSettings.lastStreamDestination.streamKey
            }
        }
    }
    
    // MARK: - Platform Picker
    private var platformPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(LivePlatform.allCases) { platform in
                    let isSelected = selectedPlatform == platform
                    Button(action: {
                        selectedPlatform = platform
                        serverUrl = platform.defaultRtmpUrl
                        testResult = nil
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: platform.iconName)
                                .font(.system(size: 14, weight: .bold))
                            Text(platform.rawValue)
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule().fill(
                                isSelected ?
                                LinearGradient(colors: [Color.red, Color.orange], startPoint: .leading, endPoint: .trailing) :
                                LinearGradient(colors: [Color.white.opacity(0.08), Color.white.opacity(0.08)], startPoint: .leading, endPoint: .trailing)
                            )
                        )
                        .overlay(
                            Capsule().stroke(isSelected ? Color.red.opacity(0.8) : Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Platform Help Card
    private var platformHelpCard: some View {
        GlassCard(cornerRadius: 16, padding: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 18))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hướng dẫn lấy Khóa luồng")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                    Text(selectedPlatform.instructions)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                        .lineSpacing(2)
                }
            }
        }
    }
    
    // MARK: - Credentials Card
    private var credentialsCard: some View {
        GlassCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Thông tin máy chủ RTMP")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                
                // Server URL
                VStack(alignment: .leading, spacing: 6) {
                    Text("URL máy chủ (Server URL)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    HStack {
                        TextField("rtmp://...", text: $serverUrl)
                            .foregroundColor(.white)
                            .font(.system(size: 13))
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        if !serverUrl.isEmpty {
                            Button(action: { serverUrl = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(10)
                }
                
                // Stream Key
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Khóa luồng (Stream Key)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        Spacer()
                        Button(action: {
                            if let paste = UIPasteboard.general.string {
                                streamKey = paste
                            }
                        }) {
                            Text("Dán từ bộ nhớ tạm")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.red)
                        }
                    }
                    
                    HStack {
                        if isSecureKeyVisible {
                            TextField("Nhập Stream Key", text: $streamKey)
                                .foregroundColor(.white)
                                .font(.system(size: 13))
                                .autocapitalization(.none)
                        } else {
                            SecureField("Nhập Stream Key", text: $streamKey)
                                .foregroundColor(.white)
                                .font(.system(size: 13))
                        }
                        
                        Button(action: { isSecureKeyVisible.toggle() }) {
                            Image(systemName: isSecureKeyVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .padding(12)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(10)
                }
                
                // Test Connection Button
                Button(action: runConnectionTest) {
                    HStack {
                        if isTestingConnection {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Đang kiểm tra kết nối...")
                        } else {
                            Image(systemName: "bolt.horizontal.fill")
                            Text("Kiểm tra kết nối RTMP")
                        }
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                }
                
                if let result = testResult {
                    HStack(spacing: 8) {
                        Image(systemName: result.success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(result.success ? .green : .red)
                        Text(result.message)
                            .font(.system(size: 12))
                            .foregroundColor(result.success ? .green : .red)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background((result.success ? Color.green : Color.red).opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - Quality Settings
    private var qualitySettingsCard: some View {
        GlassCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Cấu hình chất lượng phát")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                
                // Resolution Selector
                HStack {
                    Text("Độ phân giải")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Picker("Độ phân giải", selection: $userSettings.streamSettings.resolution) {
                        ForEach(VideoResolution.allCases) { res in
                            Text(res.rawValue).tag(res)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .accentColor(.red)
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                // Frame Rate (FPS)
                HStack {
                    Text("Tốc độ khung hình (FPS)")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Picker("FPS", selection: $userSettings.streamSettings.fps) {
                        ForEach(VideoFPS.allCases) { fps in
                            Text(fps.title).tag(fps)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .accentColor(.red)
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                // Bitrate
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Bitrate truyền tải")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                        Text("\(userSettings.streamSettings.bitrateKbps) kbps")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Slider(
                        value: Binding(
                            get: { Double(userSettings.streamSettings.bitrateKbps) },
                            set: { userSettings.streamSettings.bitrateKbps = Int($0) }
                        ),
                        in: 1000...6000,
                        step: 250
                    )
                    .accentColor(.red)
                }
            }
        }
    }
    
    // MARK: - Broadcast Action Section
    private var broadcastActionSection: some View {
        VStack(spacing: 12) {
            ZStack {
                // Background Styled Button
                LinearGradient(
                    colors: [Color.red, Color.orange],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 56)
                .cornerRadius(16)
                .shadow(color: .red.opacity(0.4), radius: 10, x: 0, y: 5)
                
                HStack(spacing: 8) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 18, weight: .bold))
                    Text(replayKit.isBroadcastingSystem ? "DỪNG PHÁT TRỰC TIẾP" : "BẮT ĐẦU PHÁT TRỰC TIẾP")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(.white)
                
                // Native ReplayKit Broadcast Picker
                BroadcastPickerRepresentable()
                    .frame(height: 56)
                    .opacity(0.015)
            }
            .simultaneousGesture(TapGesture().onEnded {
                saveCurrentConfig()
            })
            
            Text("Chạm để chọn 'LAICHYM' trong bảng chọn phát của hệ thống iOS")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
    }
    
    private func saveCurrentConfig() {
        let dest = StreamDestination(
            platform: selectedPlatform,
            serverUrl: serverUrl,
            streamKey: streamKey
        )
        userSettings.lastStreamDestination = dest
        rtmpStreamer.configureStream(destination: dest, settings: userSettings.streamSettings)
    }
    
    private func runConnectionTest() {
        guard !serverUrl.isEmpty else {
            testResult = (false, "Vui lòng nhập URL máy chủ")
            return
        }
        isTestingConnection = true
        testResult = nil
        
        rtmpStreamer.testConnection(url: serverUrl, streamKey: streamKey) { success, error in
            isTestingConnection = false
            if success {
                testResult = (true, "Kết nối tới máy chủ RTMP thành công!")
            } else {
                testResult = (false, error ?? "Không thể kết nối máy chủ RTMP")
            }
        }
    }
}
