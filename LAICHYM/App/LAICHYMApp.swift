import SwiftUI
import AVFoundation

@main
struct LAICHYMApp: App {
    @StateObject private var userSettings = UserSettings.shared
    @StateObject private var storage = StorageManager.shared
    @StateObject private var replayKit = ReplayKitManager.shared
    
    init() {
        configureAudioSession()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userSettings)
                .environmentObject(storage)
                .environmentObject(replayKit)
                .preferredColorScheme(.dark)
        }
    }
    
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .videoRecording, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            print("Lỗi cấu hình AVAudioSession: \(error)")
        }
    }
}
