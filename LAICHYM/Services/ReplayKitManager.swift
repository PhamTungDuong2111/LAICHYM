import Foundation
import ReplayKit
import AVFoundation
import Combine

// MARK: - ReplayKit & Screen Recorder Manager
public class ReplayKitManager: NSObject, ObservableObject {
    public static let shared = ReplayKitManager()
    
    private let recorder = RPScreenRecorder.shared()
    
    @Published public var isRecording: Bool = false
    @Published public var isBroadcastingSystem: Bool = false
    @Published public var isMicEnabled: Bool = true
    @Published public var recordingDuration: TimeInterval = 0
    @Published public var lastError: String? = nil
    @Published public var lastRecordedUrl: URL? = nil
    
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioMicInput: AVAssetWriterInput?
    private var audioAppInput: AVAssetWriterInput?
    private var sessionStarted: Bool = false
    
    private var timer: Timer?
    private var startTime: Date?
    
    public override init() {
        super.init()
        checkBroadcastStatus()
        setupNotificationObservers()
    }
    
    // MARK: - Direct In-App Screen Recording (Ghi màn hình trực tiếp không cần Extension)
    public func startDirectRecording(withMic: Bool = true, completion: @escaping (Bool, String?) -> Void) {
        #if targetEnvironment(simulator)
        // Thông báo nếu chạy trên Simulator
        self.lastError = "Apple không hỗ trợ ghi màn hình trên iOS Simulator. Hãy chạy trên iPhone thật để ghi hình thực tế."
        completion(false, self.lastError)
        return
        #endif
        
        guard recorder.isAvailable else {
            self.lastError = "Quay màn hình hiện không khả dụng trên thiết bị này."
            completion(false, self.lastError)
            return
        }
        
        let storage = StorageManager.shared
        let timestamp = Int(Date().timeIntervalSince1970)
        let outputUrl = storage.storageDirectoryURL.appendingPathComponent("ScreenRecording_\(timestamp).mp4")
        self.lastRecordedUrl = outputUrl
        
        do {
            try? FileManager.default.removeItem(at: outputUrl)
            assetWriter = try AVAssetWriter(outputURL: outputUrl, fileType: .mp4)
            
            // Video Settings (H.264 1080x1920)
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: 1080,
                AVVideoHeightKey: 1920,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: 5000000,
                    AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
                ]
            ]
            videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            videoInput?.expectsMediaDataInRealTime = true
            if let vInput = videoInput, assetWriter?.canAdd(vInput) == true {
                assetWriter?.add(vInput)
            }
            
            // Audio Settings (AAC Stereo 44.1kHz)
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 2,
                AVSampleRateKey: 44100.0,
                AVEncoderBitRateKey: 128000
            ]
            
            if withMic {
                audioMicInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
                audioMicInput?.expectsMediaDataInRealTime = true
                if let mInput = audioMicInput, assetWriter?.canAdd(mInput) == true {
                    assetWriter?.add(mInput)
                }
            }
            
            audioAppInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            audioAppInput?.expectsMediaDataInRealTime = true
            if let aInput = audioAppInput, assetWriter?.canAdd(aInput) == true {
                assetWriter?.add(aInput)
            }
            
            assetWriter?.startWriting()
            sessionStarted = false
        } catch {
            self.lastError = "Lỗi khởi tạo file: \(error.localizedDescription)"
            completion(false, self.lastError)
            return
        }
        
        recorder.isMicrophoneEnabled = withMic
        
        recorder.startCapture(handler: { [weak self] sampleBuffer, sampleBufferType, error in
            guard let self = self, error == nil else { return }
            self.processSampleBuffer(sampleBuffer, type: sampleBufferType)
        }) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.lastError = error.localizedDescription
                    self?.isRecording = false
                    completion(false, error.localizedDescription)
                } else {
                    self?.isRecording = true
                    self?.startTimer()
                    completion(true, nil)
                }
            }
        }
    }
    
    private func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, type: RPSampleBufferType) {
        guard CMSampleBufferDataIsReady(sampleBuffer) else { return }
        
        let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        if !sessionStarted && type == .video {
            assetWriter?.startSession(atSourceTime: pts)
            sessionStarted = true
        }
        
        guard sessionStarted else { return }
        
        switch type {
        case .video:
            if let vInput = videoInput, vInput.isReadyForMoreMediaData {
                vInput.append(sampleBuffer)
            }
        case .audioMic:
            if let mInput = audioMicInput, mInput.isReadyForMoreMediaData {
                mInput.append(sampleBuffer)
            }
        case .audioApp:
            if let aInput = audioAppInput, aInput.isReadyForMoreMediaData {
                aInput.append(sampleBuffer)
            }
        @unknown default:
            break
        }
    }
    
    public func stopDirectRecording(completion: @escaping (URL?) -> Void) {
        guard isRecording else {
            completion(nil)
            return
        }
        
        stopTimer()
        recorder.stopCapture { [weak self] error in
            guard let self = self else { return }
            if self.sessionStarted && self.assetWriter?.status == .writing {
                self.videoInput?.markAsFinished()
                self.audioMicInput?.markAsFinished()
                self.audioAppInput?.markAsFinished()
                
                self.assetWriter?.finishWriting { [weak self] in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        self.isRecording = false
                        self.sessionStarted = false
                        self.assetWriter = nil
                        StorageManager.shared.loadRecordings()
                        completion(self.lastRecordedUrl)
                    }
                }
            } else {
                self.assetWriter?.cancelWriting()
                DispatchQueue.main.async {
                    self.isRecording = false
                    self.sessionStarted = false
                    self.assetWriter = nil
                    completion(nil)
                }
            }
        }
    }
    
    // MARK: - Notification Observers
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBroadcastStarted),
            name: NSNotification.Name("LAICHYM_BroadcastStarted"),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBroadcastFinished),
            name: NSNotification.Name("LAICHYM_BroadcastFinished"),
            object: nil
        )
    }
    
    @objc private func handleBroadcastStarted() {
        DispatchQueue.main.async {
            self.isBroadcastingSystem = true
            self.startTimer()
        }
    }
    
    @objc private func handleBroadcastFinished() {
        DispatchQueue.main.async {
            self.isBroadcastingSystem = false
            self.stopTimer()
            StorageManager.shared.loadRecordings()
        }
    }
    
    public func checkBroadcastStatus() {
        let defaults = UserDefaults(suiteName: UserSettings.appGroupId)
        let isBroadcasting = defaults?.bool(forKey: "isBroadcastingActive") ?? false
        DispatchQueue.main.async {
            self.isBroadcastingSystem = isBroadcasting
        }
    }
    
    // MARK: - Timer
    private func startTimer() {
        startTime = Date()
        recordingDuration = 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.startTime else { return }
            self.recordingDuration = Date().timeIntervalSince(start)
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        recordingDuration = 0
    }
}
