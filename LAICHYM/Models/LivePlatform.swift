import Foundation
import SwiftUI

// MARK: - Supported Livestream Platforms
public enum LivePlatform: String, CaseIterable, Identifiable, Codable {
    case youtube = "YouTube Live"
    case facebook = "Facebook Live"
    case twitch = "Twitch"
    case custom = "Custom RTMP"
    
    public var id: String { rawValue }
    
    public var defaultRtmpUrl: String {
        switch self {
        case .youtube:
            return "rtmp://a.rtmp.youtube.com/live2"
        case .facebook:
            return "rtmps://live-api-s.facebook.com:443/rtmp"
        case .twitch:
            return "rtmp://live.twitch.tv/app"
        case .custom:
            return ""
        }
    }
    
    public var iconName: String {
        switch self {
        case .youtube: return "play.rectangle.fill"
        case .facebook: return "f.circle.fill"
        case .twitch: return "gamecontroller.fill"
        case .custom: return "network"
        }
    }
    
    public var brandColorHex: String {
        switch self {
        case .youtube: return "#FF0000"
        case .facebook: return "#1877F2"
        case .twitch: return "#9146FF"
        case .custom: return "#00D26A"
        }
    }
    
    public var instructions: String {
        switch self {
        case .youtube:
            return "Vào YouTube Studio > Tạo > Phát trực tiếp. Sao chép Khóa luồng (Stream Key) và dán vào bên dưới."
        case .facebook:
            return "Vào Facebook Live Producer. Chọn 'Dùng khoá luồng', sao chép Khóa luồng và dán vào ô bên dưới."
        case .twitch:
            return "Vào Bảng điều khiển tác giả Twitch > Cài đặt > Luồng > Khóa luồng chính."
        case .custom:
            return "Nhập URL máy chủ RTMP/RTMPS (ví dụ RTMP server cá nhân, TikTok Live, Shopee Live) và Stream Key."
        }
    }
}

// MARK: - Livestream Configuration Destination
public struct StreamDestination: Codable, Equatable {
    public var platform: LivePlatform
    public var serverUrl: String
    public var streamKey: String
    public var streamTitle: String
    public var streamDescription: String
    
    public init(
        platform: LivePlatform = .youtube,
        serverUrl: String = LivePlatform.youtube.defaultRtmpUrl,
        streamKey: String = "",
        streamTitle: String = "LAICHYM Screen Stream",
        streamDescription: String = "Live streamed from iPhone via LAICHYM"
    ) {
        self.platform = platform
        self.serverUrl = serverUrl
        self.streamKey = streamKey
        self.streamTitle = streamTitle
        self.streamDescription = streamDescription
    }
    
    public var fullStreamUrl: String {
        guard !serverUrl.isEmpty else { return "" }
        let cleanBase = serverUrl.hasSuffix("/") ? String(serverUrl.dropLast()) : serverUrl
        return "\(cleanBase)/\(streamKey)"
    }
}
