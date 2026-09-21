import Foundation
import CoreMedia
import Network

// MARK: - RTMP Connection State
public enum RTMPConnectionState: String {
    case disconnected = "Đã ngắt kết nối"
    case connecting = "Đang kết nối..."
    case handshaking = "Bắt tay RTMP..."
    case publishing = "Đang phát trực tiếp"
    case failed = "Kết nối thất bại"
}

// MARK: - RTMP Streamer Service
public class RTMPStreamer: ObservableObject {
    public static let shared = RTMPStreamer()
    
    @Published public var state: RTMPConnectionState = .disconnected
    @Published public var currentBitrateKbps: Int = 0
    @Published public var currentFps: Int = 0
    @Published public var droppedFrames: Int = 0
    @Published public var streamDuration: TimeInterval = 0
    
    private var tcpConnection: NWConnection?
    private var streamTimer: Timer?
    private var startTimestamp: Date?
    
    public init() {}
    
    // Lưu cấu hình vào App Group để Broadcast Extension đọc
    public func configureStream(destination: StreamDestination, settings: StreamSettings) {
        let defaults = UserDefaults(suiteName: UserSettings.appGroupId)
        defaults?.set(destination.serverUrl, forKey: "rtmpServerUrl")
        defaults?.set(destination.streamKey, forKey: "rtmpStreamKey")
        defaults?.set(destination.fullStreamUrl, forKey: "rtmpFullUrl")
        defaults?.set(settings.bitrateKbps, forKey: "rtmpBitrate")
        defaults?.set(settings.fps.rawValue, forKey: "rtmpFps")
        defaults?.synchronize()
    }
    
    // Kiểm tra kết nối RTMP Socket sơ bộ
    public func testConnection(url: String, streamKey: String, completion: @escaping (Bool, String?) -> Void) {
        guard let urlComponents = URL(string: url), let host = urlComponents.host else {
            completion(false, "URL máy chủ RTMP không hợp lệ")
            return
        }
        
        let port = NWEndpoint.Port(rawValue: UInt16(urlComponents.port ?? 1935)) ?? NWEndpoint.Port(integerLiteral: 1935)
        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: port)
        
        let params = NWParameters.tcp
        let conn = NWConnection(to: endpoint, using: params)
        
        conn.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                conn.cancel()
                DispatchQueue.main.async {
                    completion(true, nil)
                }
            case .failed(let error):
                conn.cancel()
                DispatchQueue.main.async {
                    completion(false, "Lỗi kết nối tới \(host): \(error.localizedDescription)")
                }
            case .waiting(let error):
                conn.cancel()
                DispatchQueue.main.async {
                    completion(false, "Không thể kết nối máy chủ: \(error.localizedDescription)")
                }
            default:
                break
            }
        }
        
        conn.start(queue: .global())
    }
}
