import SwiftUI
import AVFoundation

// MARK: - Video Editor View (Trim, Crop, Voiceover, Watermark)
public struct VideoEditorView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var storage = StorageManager.shared
    @ObservedObject var editor = VideoEditorService.shared
    @ObservedObject var userSettings = UserSettings.shared
    
    @State private var selectedItem: RecordingItem? = nil
    @State private var editConfig = VideoEditConfig()
    @State private var player: AVPlayer? = nil
    @State private var showExportSuccessAlert = false
    @State private var exportedVideoUrl: URL? = nil
    @State private var isRecordingVoiceover = false
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.06, green: 0.08, blue: 0.12).ignoresSafeArea()
                
                if let item = selectedItem {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Video Player Preview
                            videoPreviewSection
                            
                            // Trimming Timeline Section
                            trimmerSection
                            
                            // Aspect Ratio Cropping Presets
                            cropAspectSection
                            
                            // Audio & Voiceover Mixer
                            audioMixerSection
                            
                            // Watermark Setting
                            watermarkSection
                            
                            // Export Action Button
                            exportButtonSection
                            
                            Spacer(minLength: 40)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                    }
                } else {
                    videoSelectionPrompt
                }
                
                // Export Progress Overlay
                if editor.isExporting {
                    exportProgressOverlay
                }
            }
            .navigationTitle("Chỉnh sửa Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") {
                        player?.pause()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .alert(isPresented: $showExportSuccessAlert) {
                Alert(
                    title: Text("Xuất video thành công!"),
                    message: Text("Video đã chỉnh sửa được lưu vào Thư viện video LAICHYM của bạn."),
                    dismissButton: .default(Text("Tuyệt vời"), action: {
                        presentationMode.wrappedValue.dismiss()
                    })
                )
            }
        }
    }
    
    // MARK: - Video Selection Prompt
    private var videoSelectionPrompt: some View {
        VStack(spacing: 20) {
            Image(systemName: "scissors.badge.ellipsis")
                .font(.system(size: 48))
                .foregroundColor(.green)
                .padding(.top, 40)
            
            Text("Chọn video cần chỉnh sửa")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            if storage.recordings.isEmpty {
                Text("Chưa có video nào để chỉnh sửa.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(storage.recordings) { item in
                            Button(action: { setupEditor(for: item) }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.green)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.title)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text("\(item.formattedDuration) • \(item.resolution)")
                                            .font(.system(size: 11))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white.opacity(0.3))
                                }
                                .padding(12)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .frame(maxHeight: 360)
            }
        }
    }
    
    // MARK: - Video Preview Section
    private var videoPreviewSection: some View {
        VStack {
            if let player = player {
                VideoPlayerRepresentable(player: player)
                    .frame(height: 220)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
        }
    }
    
    // MARK: - Trimming Section
    private var trimmerSection: some View {
        GlassCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "timeline.selection")
                        .foregroundColor(.green)
                    Text("Cắt thời lượng (Trim)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(String(format: "%.1f", editConfig.startTime))s - \(String(format: "%.1f", editConfig.endTime))s")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.green)
                }
                
                VStack(spacing: 8) {
                    HStack {
                        Text("Bắt đầu:")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                        Slider(value: $editConfig.startTime, in: 0...max(0.1, editConfig.endTime - 0.5))
                            .accentColor(.green)
                    }
                    
                    HStack {
                        Text("Kết thúc:")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                        Slider(value: $editConfig.endTime, in: min(editConfig.totalDuration, editConfig.startTime + 0.5)...editConfig.totalDuration)
                            .accentColor(.green)
                    }
                }
            }
        }
    }
    
    // MARK: - Crop Aspect Ratio Section
    private var cropAspectSection: some View {
        GlassCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "crop")
                        .foregroundColor(.green)
                    Text("Tỉ lệ khung hình (Crop)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(CropAspectRatio.allCases) { aspect in
                            let isSelected = editConfig.cropRatio == aspect
                            Button(action: { editConfig.cropRatio = aspect }) {
                                Text(aspect.rawValue)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule().fill(isSelected ? Color.green : Color.white.opacity(0.08))
                                    )
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Audio & Voiceover Mixer Section
    private var audioMixerSection: some View {
        GlassCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "slider.vertical.3")
                        .foregroundColor(.green)
                    Text("Bộ trộn âm thanh (Audio Mixer)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Original Track Volume
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Âm thanh gốc:")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                        Spacer()
                        Text("\(Int(editConfig.originalAudioVolume * 100))%")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Slider(value: $editConfig.originalAudioVolume, in: 0.0...1.0)
                        .accentColor(.green)
                }
                
                // Voiceover Commentary Volume
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Âm thanh lồng tiếng:")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                        Spacer()
                        Text("\(Int(editConfig.voiceoverAudioVolume * 100))%")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Slider(value: $editConfig.voiceoverAudioVolume, in: 0.0...1.0)
                        .accentColor(.green)
                }
            }
        }
    }
    
    // MARK: - Watermark Section
    private var watermarkSection: some View {
        GlassCard(cornerRadius: 18, padding: 14) {
            Toggle(isOn: $editConfig.showWatermark) {
                HStack {
                    Image(systemName: "tag.fill")
                        .foregroundColor(.yellow)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Logo bản quyền LAICHYM")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        if !userSettings.isVIP {
                            Text("Nâng cấp VIP để xóa logo vĩnh viễn")
                                .font(.system(size: 11))
                                .foregroundColor(.yellow.opacity(0.8))
                        }
                    }
                }
            }
            .disabled(!userSettings.isVIP)
        }
    }
    
    // MARK: - Export Button Section
    private var exportButtonSection: some View {
        Button(action: executeExport) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.down.doc.fill")
                Text("XUẤT VIDEO (MP4)")
            }
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                LinearGradient(colors: [Color.green, Color(red: 0.1, green: 0.6, blue: 0.3)], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(16)
            .shadow(color: Color.green.opacity(0.4), radius: 10, x: 0, y: 5)
        }
    }
    
    // MARK: - Export Progress Overlay
    private var exportProgressOverlay: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView(value: editor.exportProgress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    .frame(width: 200)
                
                Text("Đang xuất video: \(Int(editor.exportProgress * 100))%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
        }
    }
    
    private func setupEditor(for item: RecordingItem) {
        self.selectedItem = item
        self.editConfig = VideoEditConfig(
            startTime: 0.0,
            endTime: item.duration,
            totalDuration: item.duration,
            showWatermark: !userSettings.isVIP
        )
        let url = StorageManager.shared.fileUrl(for: item)
        self.player = AVPlayer(url: url)
    }
    
    private func executeExport() {
        guard let item = selectedItem else { return }
        let inputUrl = StorageManager.shared.fileUrl(for: item)
        let outputFileName = "\(item.title)_edited_\(Int(Date().timeIntervalSince1970)).mp4"
        let outputUrl = StorageManager.shared.storageDirectoryURL.appendingPathComponent(outputFileName)
        
        editor.processVideo(inputUrl: inputUrl, outputUrl: outputUrl, config: editConfig) { result in
            switch result {
            case .success(let finalUrl):
                self.exportedVideoUrl = finalUrl
                StorageManager.shared.loadRecordings()
                self.showExportSuccessAlert = true
            case .failure(let error):
                print("Lỗi xuất video: \(error)")
            }
        }
    }
}
