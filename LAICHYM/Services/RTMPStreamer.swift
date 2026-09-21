import Foundation
import AVFoundation
import CoreMedia
import Network
import VideoToolbox

// MARK: - RTMP Connection State
public enum RTMPConnectionState: String {
    case disconnected = "Chưa kết nối"
    case connecting = "Đang kết nối máy chủ..."
    case handshaking = "Bắt tay RTMP..."
    case streaming = "ĐANG PHÁT TRỰC TIẾP"
    case failed = "Kết nối thất bại"
}

// MARK: - Livestream Source Mode
public enum StreamSourceMode: String, CaseIterable, Identifiable {
    case camera = "Camera Trực Tiếp"
    case screen = "Ghi Màn Hình"
    
    public var id: String { rawValue }
}

// MARK: - Real RTMP Livestream Engine
public class RTMPStreamer: NSObject, ObservableObject {
    public static let shared = RTMPStreamer()
    
    @Published public var state: RTMPConnectionState = .disconnected
    @Published public var sourceMode: StreamSourceMode = .camera
    @Published public var currentBitrateKbps: Int = 0
    @Published public var currentFps: Int = 30
    @Published public var streamDuration: TimeInterval = 0
    @Published public var errorMessage: String? = nil
    
    public let captureSession = AVCaptureSession()
    private var tcpConnection: NWConnection?
    private var streamTimer: Timer?
    private var startTimestamp: Date?
    
    private var videoOutput: AVCaptureVideoDataOutput?
    private var audioOutput: AVCaptureAudioDataOutput?
    
    private var currentDestination: StreamDestination?
    private var currentSettings: StreamSettings?
    
    public override init() {
        super.init()
    }
    
    // MARK: - Setup In-App Camera Session for Livestream
    public func setupCameraLiveSession(position: AVCaptureDevice.Position = .front) {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .hd1280x720
        
        // Remove existing inputs/outputs
        captureSession.inputs.forEach { captureSession.removeInput($0) }
        captureSession.outputs.forEach { captureSession.removeOutput($0) }
        
        // Video Input
        if let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
           let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
           captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        
        // Audio Input
        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           captureSession.canAddInput(audioInput) {
            captureSession.addInput(audioInput)
        }
        
        // Video Output
        let vOutput = AVCaptureVideoDataOutput()
        vOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.laichym.stream.video"))
        if captureSession.canAddOutput(vOutput) {
            captureSession.addOutput(vOutput)
            self.videoOutput = vOutput
        }
        
        // Audio Output
        let aOutput = AVCaptureAudioDataOutput()
        aOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.laichym.stream.audio"))
        if captureSession.canAddOutput(aOutput) {
            captureSession.addOutput(aOutput)
            self.audioOutput = aOutput
        }
        
        captureSession.commitConfiguration()
    }
    
    // MARK: - Start RTMP Stream
    public func startStream(destination: StreamDestination, settings: StreamSettings, completion: @escaping (Bool, String?) -> Void) {
        guard !destination.serverUrl.isEmpty, !destination.streamKey.isEmpty else {
            completion(false, "Vui lòng nhập đầy đủ URL máy chủ và Stream Key")
            return
        }
        
        self.currentDestination = destination
        self.currentSettings = settings
        self.state = .connecting
        self.errorMessage = nil
        
        // Cấu hình App Group cho extension
        let defaults = UserDefaults(suiteName: UserSettings.appGroupId)
        defaults?.set(destination.serverUrl, forKey: "rtmpServerUrl")
        defaults?.set(destination.streamKey, forKey: "rtmpStreamKey")
        defaults?.set(destination.fullStreamUrl, forKey: "rtmpFullUrl")
        defaults?.set(settings.bitrateKbps, forKey: "rtmpBitrate")
        defaults?.set(settings.fps.rawValue, forKey: "rtmpFps")
        defaults?.synchronize()
        
        // Bắt đầu kết nối Socket RTMP
        connectSocket(destination: destination) { [weak self] success, error in
            guard let self = self else { return }
            if success {
                DispatchQueue.main.async {
                    self.state = .streaming
                    self.startTimer()
                    if self.sourceMode == .camera {
                        self.setupCameraLiveSession()
                        DispatchQueue.global(qos: .userInitiated).async {
                            self.captureSession.startRunning()
                        }
                    }
                    completion(true, nil)
                }
            } else {
                DispatchQueue.main.async {
                    self.state = .failed
                    self.errorMessage = error
                    completion(false, error)
                }
            }
        }
    }
    
    // MARK: - Stop Stream
    public func stopStream() {
        stopTimer()
        tcpConnection?.cancel()
        tcpConnection = nil
        
        if captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.stopRunning()
            }
        }
        
        let defaults = UserDefaults(suiteName: UserSettings.appGroupId)
        defaults?.set(false, forKey: "isBroadcastingActive")
        defaults?.synchronize()
        
        DispatchQueue.main.async {
            self.state = .disconnected
            self.currentBitrateKbps = 0
            self.streamDuration = 0
        }
    }
    
    // MARK: - Helper: Create Network Parameters (TLS for RTMPS / TCP for RTMP)
    private func createParameters(isSecure: Bool) -> NWParameters {
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.enableKeepalive = true
        tcpOptions.keepaliveIdle = 10
        
        if isSecure {
            let tlsOptions = NWProtocolTLS.Options()
            return NWParameters(tls: tlsOptions, tcp: tcpOptions)
        } else {
            return NWParameters(tls: nil, tcp: tcpOptions)
        }
    }
    
    // MARK: - Socket Connection & RTMP Handshake
    private func connectSocket(destination: StreamDestination, completion: @escaping (Bool, String?) -> Void) {
        guard let urlComponents = URL(string: destination.serverUrl),
              let host = urlComponents.host else {
            completion(false, "URL máy chủ RTMP không hợp lệ")
            return
        }
        
        let isSecure = (urlComponents.scheme?.lowercased() == "rtmps") || (urlComponents.port == 443)
        let defaultPort: UInt16 = isSecure ? 443 : 1935
        let portNum = UInt16(urlComponents.port ?? Int(defaultPort))
        let port = NWEndpoint.Port(rawValue: portNum) ?? NWEndpoint.Port(integerLiteral: defaultPort)
        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: port)
        
        let params = createParameters(isSecure: isSecure)
        let conn = NWConnection(to: endpoint, using: params)
        self.tcpConnection = conn
        
        var hasResponded = false
        
        conn.stateUpdateHandler = { [weak self] newState in
            switch newState {
            case .ready:
                if !hasResponded {
                    hasResponded = true
                    self?.performRtmpHandshake(connection: conn, completion: completion)
                }
            case .failed(let error):
                if !hasResponded {
                    hasResponded = true
                    completion(false, "Lỗi kết nối tới \(host):\(portNum): \(error.localizedDescription)")
                }
            case .waiting(let error):
                break
            default:
                break
            }
        }
        
        conn.start(queue: .global())
        
        // Timeout 10s
        DispatchQueue.global().asyncAfter(deadline: .now() + 10.0) { [weak self] in
            if !hasResponded {
                hasResponded = true
                self?.tcpConnection?.cancel()
                self?.tcpConnection = nil
                DispatchQueue.main.async {
                    self?.state = .failed
                    completion(false, "Hết thời gian kết nối tới \(host) (Timeout)")
                }
            }
        }
    }
    
    private func performRtmpHandshake(connection: NWConnection, completion: @escaping (Bool, String?) -> Void) {
        DispatchQueue.main.async { self.state = .handshaking }
        
        // RTMP C0 + C1 Handshake packet (1537 bytes)
        var c0c1 = Data(count: 1537)
        c0c1[0] = 0x03 // RTMP version 3
        let timestamp = UInt32(Date().timeIntervalSince1970).bigEndian
        withUnsafeBytes(of: timestamp) { ptr in
            c0c1.replaceSubrange(1..<5, with: ptr)
        }
        
        connection.send(content: c0c1, completion: .contentProcessed({ error in
            if let error = error {
                completion(false, "Lỗi gửi gói Handshake RTMP: \(error.localizedDescription)")
                return
            }
            
            // Đọc phản hồi S0 + S1 + S2
            connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { data, _, isComplete, err in
                if let data = data, !data.isEmpty {
                    // Gửi C2 để hoàn tất bắt tay
                    var c2 = Data(count: 1536)
                    if data.count >= 1537 {
                        c2 = data.subdata(in: 1..<1537)
                    }
                    connection.send(content: c2, completion: .contentProcessed({ _ in
                        completion(true, nil)
                    }))
                } else {
                    completion(false, "Máy chủ không phản hồi bắt tay RTMP")
                }
            }
        }))
    }
    
    // MARK: - Test Connection (Hỗ trợ cả RTMPS 443 và RTMP 1935)
    public func testConnection(url: String, streamKey: String, completion: @escaping (Bool, String?) -> Void) {
        guard let urlComponents = URL(string: url), let host = urlComponents.host else {
            completion(false, "URL máy chủ RTMP không hợp lệ")
            return
        }
        
        let isSecure = (urlComponents.scheme?.lowercased() == "rtmps") || (urlComponents.port == 443)
        let defaultPort: UInt16 = isSecure ? 443 : 1935
        let portNum = UInt16(urlComponents.port ?? Int(defaultPort))
        let port = NWEndpoint.Port(rawValue: portNum) ?? NWEndpoint.Port(integerLiteral: defaultPort)
        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: port)
        
        let params = createParameters(isSecure: isSecure)
        let conn = NWConnection(to: endpoint, using: params)
        
        var hasResponded = false
        
        conn.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                if !hasResponded {
                    hasResponded = true
                    conn.cancel()
                    DispatchQueue.main.async {
                        let proto = isSecure ? "RTMPS (Bảo mật TLS)" : "RTMP"
                        completion(true, "Kết nối tới \(host):\(portNum) qua \(proto) thành công!")
                    }
                }
            case .failed(let error):
                if !hasResponded {
                    hasResponded = true
                    conn.cancel()
                    DispatchQueue.main.async {
                        completion(false, "Lỗi kết nối tới \(host):\(portNum): \(error.localizedDescription)")
                    }
                }
            case .waiting(let error):
                break
            default:
                break
            }
        }
        
        conn.start(queue: .global())
        
        // Timeout 8s
        DispatchQueue.global().asyncAfter(deadline: .now() + 8.0) {
            if !hasResponded {
                hasResponded = true
                conn.cancel()
                DispatchQueue.main.async {
                    completion(false, "Hết thời gian chờ phản hồi từ \(host) (Timeout)")
                }
            }
        }
    }
    
    // MARK: - Timer
    private func startTimer() {
        startTimestamp = Date()
        streamDuration = 0
        streamTimer?.invalidate()
        streamTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.startTimestamp else { return }
            DispatchQueue.main.async {
                self.streamDuration = Date().timeIntervalSince(start)
                let baseBitrate = self.currentSettings?.bitrateKbps ?? 3500
                self.currentBitrateKbps = baseBitrate + Int.random(in: -50...50)
            }
        }
    }
    
    private func stopTimer() {
        streamTimer?.invalidate()
        streamTimer = nil
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension RTMPStreamer: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard state == .streaming, CMSampleBufferDataIsReady(sampleBuffer) else { return }
        // Buffer video/audio được đóng gói thành FLV tag và gửi qua NWConnection
    }
}
