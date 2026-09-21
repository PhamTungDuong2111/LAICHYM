import SwiftUI

// MARK: - Settings & Control Center Guide View
public struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var userSettings = UserSettings.shared
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.06, green: 0.08, blue: 0.12).ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Control Center Guide Card
                        controlCenterTutorialCard
                        
                        // Video Recording Settings
                        videoSettingsCard
                        
                        // Audio Settings
                        audioSettingsCard
                        
                        // App Branding & Legal
                        appInfoCard
                        
                        Spacer(minLength: 30)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("Cài đặt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Xong") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    // MARK: - Control Center Tutorial Card
    private var controlCenterTutorialCard: some View {
        GlassCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "hand.tap.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 20))
                    Text("Cách bật Ghi màn hình trên iOS")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    tutorialStep(number: "1", text: "Mở Cài đặt (Settings) trên iPhone > chọn Trung tâm điều khiển (Control Center).")
                    tutorialStep(number: "2", text: "Tìm mục 'Ghi màn hình' (Screen Recording) và bấm dấu (+) màu xanh để thêm vào.")
                    tutorialStep(number: "3", text: "Vuốt từ góc trên bên phải màn hình xuống để mở Trung tâm điều khiển.")
                    tutorialStep(number: "4", text: "Nhấn giữ (Long press) vào nút Ghi màn hình > chọn 'LAICHYM' > Bắt đầu truyền phát.")
                }
            }
        }
    }
    
    private func tutorialStep(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.red.opacity(0.8)))
            
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.75))
                .lineSpacing(2)
        }
    }
    
    // MARK: - Video Settings Card
    private var videoSettingsCard: some View {
        GlassCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Thông số video mặc định")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                
                // Resolution
                HStack {
                    Text("Độ phân giải")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Picker("", selection: $userSettings.streamSettings.resolution) {
                        ForEach(VideoResolution.allCases) { res in
                            Text(res.rawValue).tag(res)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .accentColor(.red)
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                // FPS
                HStack {
                    Text("Số khung hình (FPS)")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Picker("", selection: $userSettings.streamSettings.fps) {
                        ForEach(VideoFPS.allCases) { fps in
                            Text(fps.title).tag(fps)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .accentColor(.red)
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                // Countdown
                HStack {
                    Text("Đếm ngược trước khi quay")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Picker("", selection: $userSettings.streamSettings.countdown) {
                        ForEach(CountdownTimer.allCases) { count in
                            Text(count.title).tag(count)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .accentColor(.red)
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                // Watermark
                Toggle(isOn: $userSettings.showWatermark) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Chèn Watermark logo LAICHYM")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                        Text("Mặc định Tắt (hoàn toàn miễn phí)")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .accentColor(.red)
            }
        }
    }
    
    // MARK: - Audio Settings Card
    private var audioSettingsCard: some View {
        GlassCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Cấu hình âm thanh")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                
                Toggle(isOn: $userSettings.streamSettings.enableMicrophone) {
                    Text("Bật micro ghi âm bình luận")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                }
                .accentColor(.red)
                
                Divider().background(Color.white.opacity(0.1))
                
                Toggle(isOn: $userSettings.streamSettings.enableSystemAudio) {
                    Text("Ghi âm thanh hệ thống (Game/App)")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                }
                .accentColor(.red)
            }
        }
    }
    
    // MARK: - App Info Card
    private var appInfoCard: some View {
        GlassCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Thông tin ứng dụng")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                
                HStack {
                    Text("Phiên bản")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text("1.0.0 (Build 1)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                HStack {
                    Text("Chính sách bảo mật")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                HStack {
                    Text("Điều khoản dịch vụ")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
    }
}
