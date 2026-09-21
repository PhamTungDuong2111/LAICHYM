import Foundation
import ReplayKit
import Combine

// MARK: - ReplayKit & Broadcast Manager
public class ReplayKitManager: NSObject, ObservableObject {
    public static let shared = ReplayKitManager()
    
    private let recorder = RPScreenRecorder.shared()
    
    @Published public var isRecordingInApp: Bool = false
    @Published public var isBroadcastingSystem: Bool = false
    @Published public var isMicEnabled: Bool = true
    @Published public var isCameraEnabled: Bool = false
    @Published public var recordingDuration: TimeInterval = 0
    @Published public var lastError: String? = nil
    
    private var timer: Timer?
    private var startTime: Date?
    
    public override init() {
        super.init()
        checkBroadcastStatus()
        setupNotificationObservers()
    }
    
    // MARK: - In-App Screen Recording
    public func startInAppRecording(withMicrophone: Bool = true, completion: @escaping (Bool) -> Void) {
        guard recorder.isAvailable else {
            self.lastError = "Quay màn hình hiện không khả dụng"
            completion(false)
            return
        }
        
        recorder.isMicrophoneEnabled = withMicrophone
        recorder.isCameraEnabled = isCameraEnabled
        
        recorder.startRecording { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.lastError = error.localizedDescription
                    self?.isRecordingInApp = false
                    completion(false)
                } else {
                    self?.isRecordingInApp = true
                    self?.startTimer()
                    completion(true)
                }
            }
        }
    }
    
    public func stopInAppRecording(completion: @escaping (RPPreviewViewController?, URL?) -> Void) {
        guard isRecordingInApp else { return }
        
        stopTimer()
        recorder.stopRecording { [weak self] previewViewController, error in
            DispatchQueue.main.async {
                self?.isRecordingInApp = false
                if let error = error {
                    self?.lastError = error.localizedDescription
                    completion(nil, nil)
                } else {
                    completion(previewViewController, nil)
                }
            }
        }
    }
    
    // MARK: - System-Wide Broadcast Status Check
    private func setupNotificationObservers() {
        // Lắng nghe thông báo từ Broadcast Upload Extension
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
            if isBroadcasting && self.timer == nil {
                self.startTimer()
            } else if !isBroadcasting && self.isBroadcastingSystem {
                self.stopTimer()
            }
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
