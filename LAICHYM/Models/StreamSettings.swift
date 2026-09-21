import Foundation
import CoreGraphics

// MARK: - Quality & Stream Settings (All 100% Free)
public enum VideoResolution: String, CaseIterable, Identifiable, Codable {
    case fullHD1080 = "1080p (Full HD)"
    case hd720 = "720p (HD)"
    case sd480 = "480p (SD)"
    case sd360 = "360p (Tiết kiệm)"
    
    public var id: String { rawValue }
    
    public var dimensions: CGSize {
        switch self {
        case .fullHD1080: return CGSize(width: 1920, height: 1080)
        case .hd720: return CGSize(width: 1280, height: 720)
        case .sd480: return CGSize(width: 854, height: 480)
        case .sd360: return CGSize(width: 640, height: 360)
        }
    }
    
    public var defaultBitrate: Int {
        switch self {
        case .fullHD1080: return 5000 // kbps
        case .hd720: return 3000
        case .sd480: return 1800
        case .sd360: return 1000
        }
    }
    
    // Miễn phí 100% không yêu cầu trả phí
    public var requiresVIP: Bool {
        return false
    }
}

public enum VideoFPS: Int, CaseIterable, Identifiable, Codable {
    case fps60 = 60
    case fps30 = 30
    case fps24 = 24
    
    public var id: Int { rawValue }
    
    public var title: String {
        return "\(rawValue) FPS"
    }
    
    // Miễn phí 100%
    public var requiresVIP: Bool {
        return false
    }
}

public enum CountdownTimer: Int, CaseIterable, Identifiable, Codable {
    case none = 0
    case sec3 = 3
    case sec5 = 5
    case sec10 = 10
    
    public var id: Int { rawValue }
    
    public var title: String {
        if rawValue == 0 { return "Tắt" }
        return "\(rawValue) giây"
    }
}

public struct StreamSettings: Codable, Equatable {
    public var resolution: VideoResolution
    public var fps: VideoFPS
    public var bitrateKbps: Int
    public var enableMicrophone: Bool
    public var enableSystemAudio: Bool
    public var countdown: CountdownTimer
    public var saveStreamToGallery: Bool
    
    public init(
        resolution: VideoResolution = .fullHD1080,
        fps: VideoFPS = .fps60,
        bitrateKbps: Int = 4500,
        enableMicrophone: Bool = true,
        enableSystemAudio: Bool = true,
        countdown: CountdownTimer = .sec3,
        saveStreamToGallery: Bool = true
    ) {
        self.resolution = resolution
        self.fps = fps
        self.bitrateKbps = bitrateKbps
        self.enableMicrophone = enableMicrophone
        self.enableSystemAudio = enableSystemAudio
        self.countdown = countdown
        self.saveStreamToGallery = saveStreamToGallery
    }
}
