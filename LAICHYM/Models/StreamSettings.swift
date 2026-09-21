import Foundation
import CoreGraphics

// MARK: - Quality & Stream Settings
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
    
    public var requiresVIP: Bool {
        return self == .fullHD1080
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
    
    public var requiresVIP: Bool {
        return self == .fps60
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
        resolution: VideoResolution = .hd720,
        fps: VideoFPS = .fps30,
        bitrateKbps: Int = 3000,
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
