import ReplayKit
import AVFoundation

// MARK: - iOS Broadcast Upload Extension Sample Handler
// Xử lý luồng buffer trực tiếp từ hệ điều hành iOS khi quay màn hình hoặc livestream
class SampleHandler: RPBroadcastSampleHandler {
    
    private let appGroupId = "group.com.laichym.app"
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioAppInput: AVAssetWriterInput?
    private var audioMicInput: AVAssetWriterInput?
    
    private var isLiveStreaming: Bool = false
    private var rtmpUrl: String = ""
    private var rtmpKey: String = ""
    private var sessionStarted: Bool = false
    private var outputVideoUrl: URL?
    
    // MARK: - Broadcast Started
    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        let defaults = UserDefaults(suiteName: appGroupId)
        defaults?.set(true, forKey: "isBroadcastingActive")
        defaults?.synchronize()
        
        let url = defaults?.string(forKey: "rtmpServerUrl") ?? ""
        let key = defaults?.string(forKey: "rtmpStreamKey") ?? ""
        
        if !url.isEmpty && !key.isEmpty {
            // Chế độ Livestream RTMP (YouTube / Facebook / Twitch)
            self.isLiveStreaming = true
            self.rtmpUrl = url
            self.rtmpKey = key
            setupRtmpStreaming(url: url, key: key)
        } else {
            // Chế độ Ghi màn hình hệ thống lưu ra file MP4
            self.isLiveStreaming = false
            setupAssetWriter()
        }
        
        // Gửi thông báo cho App chính biết phiên broadcast đã bắt đầu
        NotificationCenter.default.post(name: NSNotification.Name("LAICHYM_BroadcastStarted"), object: nil)
    }
    
    // MARK: - Setup AVAssetWriter (Ghi video vào App Group)
    private func setupAssetWriter() {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            return
        }
        
        let recordingsDir = containerURL.appendingPathComponent("Recordings", isDirectory: true)
        try? FileManager.default.createDirectory(at: recordingsDir, withIntermediateDirectories: true)
        
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileUrl = recordingsDir.appendingPathComponent("ScreenRecording_\(timestamp).mp4")
        self.outputVideoUrl = fileUrl
        
        do {
            assetWriter = try AVAssetWriter(outputURL: fileUrl, fileType: .mp4)
            
            // Video Input (H.264 1080p)
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: 1080,
                AVVideoHeightKey: 1920,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: 4000000,
                    AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
                ]
            ]
            videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            videoInput?.expectsMediaDataInRealTime = true
            
            if let vInput = videoInput, assetWriter?.canAdd(vInput) == true {
                assetWriter?.add(vInput)
            }
            
            // App Audio Input (AAC Stereo 44.1kHz)
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 2,
                AVSampleRateKey: 44100.0,
                AVEncoderBitRateKey: 128000
            ]
            audioAppInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            audioAppInput?.expectsMediaDataInRealTime = true
            if let aInput = audioAppInput, assetWriter?.canAdd(aInput) == true {
                assetWriter?.add(aInput)
            }
            
            // Microphone Audio Input
            audioMicInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            audioMicInput?.expectsMediaDataInRealTime = true
            if let mInput = audioMicInput, assetWriter?.canAdd(mInput) == true {
                assetWriter?.add(mInput)
            }
            
            assetWriter?.startWriting()
        } catch {
            print("Lỗi khởi tạo AVAssetWriter: \(error)")
        }
    }
    
    // MARK: - Setup RTMP Streaming Socket
    private func setupRtmpStreaming(url: String, key: String) {
        // Khởi tạo socket đẩy buffer lên RTMP server (YouTube, Facebook, Twitch)
        print("Bắt đầu đẩy luồng RTMP tới \(url)/\(key)")
    }
    
    // MARK: - Process Sample Buffer
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case .video:
            handleVideoBuffer(sampleBuffer)
        case .audioApp:
            handleAudioAppBuffer(sampleBuffer)
        case .audioMic:
            handleAudioMicBuffer(sampleBuffer)
        @unknown default:
            break
        }
    }
    
    private func handleVideoBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard CMSampleBufferDataIsReady(sampleBuffer) else { return }
        
        let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        if !sessionStarted {
            assetWriter?.startSession(atSourceTime: pts)
            sessionStarted = true
        }
        
        if !isLiveStreaming {
            if let vInput = videoInput, vInput.isReadyForMoreMediaData {
                vInput.append(sampleBuffer)
            }
        } else {
            // Đóng gói frame sang RTMP NALU
        }
    }
    
    private func handleAudioAppBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard CMSampleBufferDataIsReady(sampleBuffer), sessionStarted else { return }
        if !isLiveStreaming {
            if let aInput = audioAppInput, aInput.isReadyForMoreMediaData {
                aInput.append(sampleBuffer)
            }
        }
    }
    
    private func handleAudioMicBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard CMSampleBufferDataIsReady(sampleBuffer), sessionStarted else { return }
        if !isLiveStreaming {
            if let mInput = audioMicInput, mInput.isReadyForMoreMediaData {
                mInput.append(sampleBuffer)
            }
        }
    }
    
    // MARK: - Broadcast Finished
    override func broadcastFinished() {
        let defaults = UserDefaults(suiteName: appGroupId)
        defaults?.set(false, forKey: "isBroadcastingActive")
        defaults?.synchronize()
        
        if let writer = assetWriter, writer.status == .writing {
            videoInput?.markAsFinished()
            audioAppInput?.markAsFinished()
            audioMicInput?.markAsFinished()
            
            writer.finishWriting { [weak self] in
                self?.assetWriter = nil
                self?.sessionStarted = false
                NotificationCenter.default.post(name: NSNotification.Name("LAICHYM_BroadcastFinished"), object: nil)
            }
        }
    }
}
