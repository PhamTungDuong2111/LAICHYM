import Foundation
import CoreGraphics

// MARK: - Aspect Ratio Crop Options
public enum CropAspectRatio: String, CaseIterable, Identifiable, Codable {
    case original = "Gốc"
    case tiktok = "9:16 (TikTok/Shorts)"
    case youtube = "16:9 (YouTube)"
    case square = "1:1 (Instagram)"
    case portrait = "4:5 (Post)"
    
    public var id: String { rawValue }
    
    public var ratio: CGFloat? {
        switch self {
        case .original: return nil
        case .tiktok: return 9.0 / 16.0
        case .youtube: return 16.0 / 9.0
        case .square: return 1.0
        case .portrait: return 4.0 / 5.0
        }
    }
}

// MARK: - Facecam Shape Options
public enum FaceCamShape: String, CaseIterable, Identifiable, Codable {
    case circle = "Hình tròn"
    case roundedRect = "Bo góc"
    case square = "Hình vuông"
    case oval = "Bầu dục"
    
    public var id: String { rawValue }
}

// MARK: - Video Editing Configuration
public struct VideoEditConfig: Equatable {
    public var startTime: Double = 0.0
    public var endTime: Double = 0.0
    public var totalDuration: Double = 0.0
    public var cropRatio: CropAspectRatio = .original
    public var originalAudioVolume: Float = 1.0
    public var voiceoverAudioVolume: Float = 1.0
    public var voiceoverAudioUrl: URL? = nil
    public var showWatermark: Bool = true
    
    public init(
        startTime: Double = 0.0,
        endTime: Double = 0.0,
        totalDuration: Double = 0.0,
        cropRatio: CropAspectRatio = .original,
        originalAudioVolume: Float = 1.0,
        voiceoverAudioVolume: Float = 1.0,
        voiceoverAudioUrl: URL? = nil,
        showWatermark: Bool = true
    ) {
        self.startTime = startTime
        self.endTime = endTime
        self.totalDuration = totalDuration
        self.cropRatio = cropRatio
        self.originalAudioVolume = originalAudioVolume
        self.voiceoverAudioVolume = voiceoverAudioVolume
        self.voiceoverAudioUrl = voiceoverAudioUrl
        self.showWatermark = showWatermark
    }
}
