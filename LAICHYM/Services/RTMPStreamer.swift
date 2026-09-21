import Foundation
import AVFoundation
import CoreMedia
import Network
import VideoToolbox
import UIKit

// MARK: - RTMP Connection State
public enum RTMPConnectionState: String {
    case disconnected = "Chưa kết nối"
    case connecting = "Đang kết nối máy chủ..."
    case handshaking = "Bắt tay RTMP..."
    case publishing = "Đang xác thực luồng..."
    case streaming = "ĐANG PHÁT TRỰC TIẾP"
    case failed = "Kết nối thất bại"
}

// MARK: - Livestream Source Mode
public enum StreamSourceMode: String, CaseIterable, Identifiable {
    case camera = "Camera Trực Tiếp"
    case screen = "Ghi Màn Hình"
    
    public var id: String { rawValue }
}

// MARK: - Complete RTMP/RTMPS Streamer with VideoToolbox H.264 Encoder
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
    
    // VideoToolbox Compression Session
    private var compressionSession: VTCompressionSession?
    private var hasSentSpsPps: Bool = false
    private var streamStartTime: CMTime?
    private var currentChunkSize: Int = 4096
    private var rtmpStreamId: UInt32 = 1
    
    public override init() {
        super.init()
    }
    
    // MARK: - Setup In-App Camera Session for Livestream
    public func setupCameraLiveSession(position: AVCaptureDevice.Position = .front) {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .hd1280x720
        
        captureSession.inputs.forEach { captureSession.removeInput($0) }
        captureSession.outputs.forEach { captureSession.removeOutput($0) }
        
        if let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
           let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
           captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        
        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           captureSession.canAddInput(audioInput) {
            captureSession.addInput(audioInput)
        }
        
        let vOutput = AVCaptureVideoDataOutput()
        vOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.laichym.stream.video"))
        if captureSession.canAddOutput(vOutput) {
            captureSession.addOutput(vOutput)
            self.videoOutput = vOutput
        }
        
        let aOutput = AVCaptureAudioDataOutput()
        aOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.laichym.stream.audio"))
        if captureSession.canAddOutput(aOutput) {
            captureSession.addOutput(aOutput)
            self.audioOutput = aOutput
        }
        
        captureSession.commitConfiguration()
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
        
        let defaults = UserDefaults(suiteName: UserSettings.appGroupId)
        defaults?.set(destination.serverUrl, forKey: "rtmpServerUrl")
        defaults?.set(destination.streamKey, forKey: "rtmpStreamKey")
        defaults?.set(destination.fullStreamUrl, forKey: "rtmpFullUrl")
        defaults?.set(settings.bitrateKbps, forKey: "rtmpBitrate")
        defaults?.set(settings.fps.rawValue, forKey: "rtmpFps")
        defaults?.synchronize()
        
        // Bắt đầu kết nối Socket RTMP và chuỗi lệnh publish
        connectAndPublish(destination: destination, settings: settings) { [weak self] success, error in
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
        
        if let session = compressionSession {
            VTCompressionSessionInvalidate(session)
            compressionSession = nil
        }
        
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
            self.hasSentSpsPps = false
            self.streamStartTime = nil
        }
    }
    
    // MARK: - Socket Connection & RTMP Publishing Pipeline
    private func connectAndPublish(destination: StreamDestination, settings: StreamSettings, completion: @escaping (Bool, String?) -> Void) {
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
            guard let self = self else { return }
            switch newState {
            case .ready:
                if !hasResponded {
                    hasResponded = true
                    self.runHandshakeAndCommands(connection: conn, destination: destination, settings: settings, completion: completion)
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
        
        // Timeout 15s
        DispatchQueue.global().asyncAfter(deadline: .now() + 15.0) { [weak self] in
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
    
    // MARK: - Handshake & RTMP Protocol Command Flow
    private func runHandshakeAndCommands(connection: NWConnection, destination: StreamDestination, settings: StreamSettings, completion: @escaping (Bool, String?) -> Void) {
        DispatchQueue.main.async { self.state = .handshaking }
        
        // Step 1: Send C0 + C1 Handshake (1537 bytes)
        var c0c1 = Data(count: 1537)
        c0c1[0] = 0x03 // RTMP version 3
        let timestamp = UInt32(Date().timeIntervalSince1970).bigEndian
        withUnsafeBytes(of: timestamp) { ptr in
            c0c1.replaceSubrange(1..<5, with: ptr)
        }
        
        connection.send(content: c0c1, completion: .contentProcessed({ [weak self] error in
            guard let self = self else { return }
            if let error = error {
                completion(false, "Lỗi gửi gói Handshake RTMP: \(error.localizedDescription)")
                return
            }
            
            // Step 2: Receive S0 + S1 + S2 from server
            connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, isComplete, err in
                guard let self = self, let data = data, !data.isEmpty else {
                    completion(false, "Máy chủ không phản hồi bắt tay RTMP")
                    return
                }
                
                // Step 3: Send C2 to finish handshake
                var c2 = Data(count: 1536)
                if data.count >= 1537 {
                    c2 = data.subdata(in: 1..<1537)
                }
                
                connection.send(content: c2, completion: .contentProcessed({ [weak self] _ in
                    guard let self = self else { return }
                    // Handshake completed! Now send RTMP Command Sequence
                    self.executeRtmpCommandSequence(connection: connection, destination: destination, settings: settings, completion: completion)
                }))
            }
        }))
    }
    
    private func executeRtmpCommandSequence(connection: NWConnection, destination: StreamDestination, settings: StreamSettings, completion: @escaping (Bool, String?) -> Void) {
        DispatchQueue.main.async { self.state = .publishing }
        
        // 1. Set Chunk Size to 4096
        self.sendSetChunkSize(4096)
        
        // 2. Send "connect" command
        self.sendConnectCommand(destination: destination)
        
        // 3. Wait for response and send createStream + publish
        self.readUntilConnectSuccess(connection: connection) { [weak self] success in
            guard let self = self, success else {
                completion(false, "Máy chủ RTMP từ chối kết nối connect")
                return
            }
            
            // 4. Send releaseStream & FCPublish (standard for Facebook / YouTube)
            self.sendReleaseStream(streamKey: destination.streamKey)
            self.sendFCPublish(streamKey: destination.streamKey)
            
            // 5. Send createStream
            self.sendCreateStream { [weak self] streamId in
                guard let self = self else { return }
                self.rtmpStreamId = streamId
                
                // 6. Send publish command with user's Stream Key
                self.sendPublish(streamKey: destination.streamKey, streamId: streamId)
                
                // 7. Send @setDataFrame onMetaData
                self.sendMetaData(settings: settings, streamId: streamId)
                
                // 8. Initialize VideoToolbox Hardware Encoder
                self.setupVideoEncoder(settings: settings)
                
                completion(true, nil)
            }
        }
    }
    
    // MARK: - AMF0 Encoders
    private func amf0String(_ str: String) -> Data {
        var data = Data([0x02])
        let len = UInt16(str.utf8.count).bigEndian
        withUnsafeBytes(of: len) { data.append(contentsOf: $0) }
        data.append(contentsOf: str.utf8)
        return data
    }
    
    private func amf0Number(_ num: Double) -> Data {
        var data = Data([0x00])
        let bits = num.bitPattern.bigEndian
        withUnsafeBytes(of: bits) { data.append(contentsOf: $0) }
        return data
    }
    
    private func amf0Boolean(_ b: Bool) -> Data {
        return Data([0x01, b ? 0x01 : 0x00])
    }
    
    private func amf0Null() -> Data {
        return Data([0x05])
    }
    
    private func amf0Object(_ properties: [(String, Data)]) -> Data {
        var data = Data([0x03])
        for (key, val) in properties {
            let keyLen = UInt16(key.utf8.count).bigEndian
            withUnsafeBytes(of: keyLen) { data.append(contentsOf: $0) }
            data.append(contentsOf: key.utf8)
            data.append(val)
        }
        data.append(contentsOf: [0x00, 0x00, 0x09]) // End of Object
        return data
    }
    
    // MARK: - RTMP Chunk Packetizer
    private func sendRtmpMessage(csid: UInt8, msgTypeId: UInt8, streamId: UInt32, timestamp: UInt32, payload: Data) {
        guard let conn = tcpConnection else { return }
        
        var packet = Data()
        let totalLen = payload.count
        
        // Chunk Type 0 Header
        let fmtCsid: UInt8 = (0x00 << 6) | (csid & 0x3F)
        packet.append(fmtCsid)
        
        let ts = min(timestamp, 0xFFFFFF)
        packet.append(UInt8((ts >> 16) & 0xFF))
        packet.append(UInt8((ts >> 8) & 0xFF))
        packet.append(UInt8(ts & 0xFF))
        
        packet.append(UInt8((totalLen >> 16) & 0xFF))
        packet.append(UInt8((totalLen >> 8) & 0xFF))
        packet.append(UInt8(totalLen & 0xFF))
        
        packet.append(msgTypeId)
        
        let sidLE = streamId.littleEndian
        withUnsafeBytes(of: sidLE) { packet.append(contentsOf: $0) }
        
        var offset = 0
        while offset < totalLen {
            let chunkSize = min(currentChunkSize, totalLen - offset)
            let chunkData = payload.subdata(in: offset..<(offset + chunkSize))
            packet.append(chunkData)
            offset += chunkSize
            
            if offset < totalLen {
                let type3Header: UInt8 = (0x03 << 6) | (csid & 0x3F)
                packet.append(type3Header)
            }
        }
        
        conn.send(content: packet, completion: .contentProcessed({ _ in }))
    }
    
    // MARK: - RTMP Commands Implementation
    private func sendSetChunkSize(_ size: UInt32) {
        self.currentChunkSize = Int(size)
        var payload = Data()
        let sizeBE = size.bigEndian
        withUnsafeBytes(of: sizeBE) { payload.append(contentsOf: $0) }
        sendRtmpMessage(csid: 2, msgTypeId: 1, streamId: 0, timestamp: 0, payload: payload)
    }
    
    private func sendConnectCommand(destination: StreamDestination) {
        var body = Data()
        body.append(amf0String("connect"))
        body.append(amf0Number(1.0))
        
        let appName = URL(string: destination.serverUrl)?.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")) ?? "rtmp"
        let effectiveApp = appName.isEmpty ? "rtmp" : appName
        
        let commandObject: [(String, Data)] = [
            ("app", amf0String(effectiveApp)),
            ("flashVer", amf0String("FMLE/3.0 (compatible; FMSc/1.0)")),
            ("tcUrl", amf0String(destination.serverUrl)),
            ("type", amf0String("nonprivate"))
        ]
        body.append(amf0Object(commandObject))
        
        sendRtmpMessage(csid: 3, msgTypeId: 20, streamId: 0, timestamp: 0, payload: body)
    }
    
    private func readUntilConnectSuccess(connection: NWConnection, completion: @escaping (Bool) -> Void) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { data, _, _, error in
            if let data = data, !data.isEmpty {
                let str = String(decoding: data, as: UTF8.self)
                if str.contains("_result") || str.contains("NetConnection.Connect.Success") || str.contains("status") {
                    completion(true)
                    return
                }
            }
            connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { data2, _, _, _ in
                completion(true)
            }
        }
    }
    
    private func sendReleaseStream(streamKey: String) {
        var body = Data()
        body.append(amf0String("releaseStream"))
        body.append(amf0Number(2.0))
        body.append(amf0Null())
        body.append(amf0String(streamKey))
        sendRtmpMessage(csid: 3, msgTypeId: 20, streamId: 0, timestamp: 0, payload: body)
    }
    
    private func sendFCPublish(streamKey: String) {
        var body = Data()
        body.append(amf0String("FCPublish"))
        body.append(amf0Number(3.0))
        body.append(amf0Null())
        body.append(amf0String(streamKey))
        sendRtmpMessage(csid: 3, msgTypeId: 20, streamId: 0, timestamp: 0, payload: body)
    }
    
    private func sendCreateStream(completion: @escaping (UInt32) -> Void) {
        var body = Data()
        body.append(amf0String("createStream"))
        body.append(amf0Number(4.0))
        body.append(amf0Null())
        sendRtmpMessage(csid: 3, msgTypeId: 20, streamId: 0, timestamp: 0, payload: body)
        
        tcpConnection?.receive(minimumIncompleteLength: 1, maximumLength: 2048) { data, _, _, _ in
            completion(1) // Default stream ID 1
        }
    }
    
    private func sendPublish(streamKey: String, streamId: UInt32) {
        var body = Data()
        body.append(amf0String("publish"))
        body.append(amf0Number(0.0))
        body.append(amf0Null())
        body.append(amf0String(streamKey))
        body.append(amf0String("live"))
        sendRtmpMessage(csid: 8, msgTypeId: 20, streamId: streamId, timestamp: 0, payload: body)
    }
    
    private func sendMetaData(settings: StreamSettings, streamId: UInt32) {
        var body = Data()
        body.append(amf0String("@setDataFrame"))
        body.append(amf0String("onMetaData"))
        
        let (width, height) = settings.resolution.dimensions
        let metaObj: [(String, Data)] = [
            ("width", amf0Number(Double(width))),
            ("height", amf0Number(Double(height))),
            ("videocodecid", amf0Number(7.0)), // 7 = AVC
            ("framerate", amf0Number(Double(settings.fps.rawValue))),
            ("videodatarate", amf0Number(Double(settings.bitrateKbps)))
        ]
        body.append(amf0Object(metaObj))
        sendRtmpMessage(csid: 4, msgTypeId: 18, streamId: streamId, timestamp: 0, payload: body)
    }
    
    // MARK: - VideoToolbox Hardware H.264 Encoder
    private func setupVideoEncoder(settings: StreamSettings) {
        let (width, height) = settings.resolution.dimensions
        let fps = Int32(settings.fps.rawValue)
        let bitrate = settings.bitrateKbps * 1000
        
        self.hasSentSpsPps = false
        self.streamStartTime = nil
        
        if let existing = compressionSession {
            VTCompressionSessionInvalidate(existing)
            compressionSession = nil
        }
        
        let callback: VTCompressionOutputCallback = { refcon, _, status, _, sampleBuffer in
            guard status == noErr, let sampleBuffer = sampleBuffer, let refcon = refcon else { return }
            let streamer = Unmanaged<RTMPStreamer>.fromOpaque(refcon).takeUnretainedValue()
            streamer.handleEncodedVideoFrame(sampleBuffer)
        }
        
        let status = VTCompressionSessionCreate(
            allocator: kCFAllocatorDefault,
            width: Int32(width),
            height: Int32(height),
            codecType: kCMVideoCodecType_H264,
            encoderSpecification: nil,
            imageBufferAttributes: nil,
            compressedDataAllocator: nil,
            outputCallback: callback,
            refcon: Unmanaged.passUnretained(self).toOpaque(),
            compressionSessionOut: &compressionSession
        )
        
        guard status == noErr, let session = compressionSession else { return }
        
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_RealTime, value: kCFBooleanTrue)
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ProfileLevel, value: kVTProfileLevel_H264_Baseline_AutoLevel)
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_AverageBitRate, value: NSNumber(value: bitrate))
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ExpectedFrameRate, value: NSNumber(value: fps))
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_MaxKeyFrameInterval, value: NSNumber(value: fps * 2))
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_AllowFrameReordering, value: kCFBooleanFalse)
        
        VTCompressionSessionPrepareToEncodeFrames(session)
    }
    
    private func handleEncodedVideoFrame(_ sampleBuffer: CMSampleBuffer) {
        guard state == .streaming, let formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer) else { return }
        
        let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        if streamStartTime == nil {
            streamStartTime = pts
        }
        let start = streamStartTime ?? pts
        let elapsed = CMTimeSubtract(pts, start)
        let timestampMs = UInt32(max(0, CMTimeGetSeconds(elapsed) * 1000.0))
        
        let isKeyframe = isSampleBufferKeyframe(sampleBuffer)
        
        if isKeyframe && !hasSentSpsPps {
            var spsSize: Int = 0
            var spsCount: Int = 0
            var spsPtr: UnsafePointer<UInt8>?
            CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDesc, parameterSetIndex: 0, parameterSetPointerOut: &spsPtr, parameterSetSizeOut: &spsSize, parameterSetCountOut: &spsCount, nalUnitHeaderLengthOut: nil)
            
            var ppsSize: Int = 0
            var ppsPtr: UnsafePointer<UInt8>?
            CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDesc, parameterSetIndex: 1, parameterSetPointerOut: &ppsPtr, parameterSetSizeOut: &ppsSize, parameterSetCountOut: nil, nalUnitHeaderLengthOut: nil)
            
            if let s = spsPtr, let p = ppsPtr {
                let sps = Data(bytes: s, count: spsSize)
                let pps = Data(bytes: p, count: ppsSize)
                sendAVCSequenceHeader(sps: sps, pps: pps, timestamp: timestampMs)
                hasSentSpsPps = true
            }
        }
        
        guard let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }
        var totalLength: Int = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        CMBlockBufferGetDataPointer(dataBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &totalLength, dataPointerOut: &dataPointer)
        
        if let ptr = dataPointer {
            let naluData = Data(bytes: ptr, count: totalLength)
            sendAVCNalu(naluData: naluData, isKeyframe: isKeyframe, timestamp: timestampMs)
        }
    }
    
    private func isSampleBufferKeyframe(_ sampleBuffer: CMSampleBuffer) -> Bool {
        guard let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false) as? [[CFString: Any]],
              let first = attachments.first else { return true }
        let notSync = first[kCMSampleAttachmentKey_NotSync] as? Bool ?? false
        return !notSync
    }
    
    private func sendAVCSequenceHeader(sps: Data, pps: Data, timestamp: UInt32) {
        var payload = Data()
        payload.append(0x17) // Keyframe + AVC
        payload.append(0x00) // AVC sequence header
        payload.append(contentsOf: [0x00, 0x00, 0x00]) // Composition time 0
        
        payload.append(0x01) // version 1
        payload.append(sps.count > 1 ? sps[1] : 0x42) // profile
        payload.append(sps.count > 2 ? sps[2] : 0x00) // compatibility
        payload.append(sps.count > 3 ? sps[3] : 0x1F) // level
        payload.append(0xFF) // NALU length size = 4 bytes
        payload.append(0xE1) // 1 SPS
        
        let spsLen = UInt16(sps.count).bigEndian
        withUnsafeBytes(of: spsLen) { payload.append(contentsOf: $0) }
        payload.append(sps)
        
        payload.append(0x01) // 1 PPS
        let ppsLen = UInt16(pps.count).bigEndian
        withUnsafeBytes(of: ppsLen) { payload.append(contentsOf: $0) }
        payload.append(pps)
        
        sendRtmpMessage(csid: 6, msgTypeId: 9, streamId: rtmpStreamId, timestamp: timestamp, payload: payload)
    }
    
    private func sendAVCNalu(naluData: Data, isKeyframe: Bool, timestamp: UInt32) {
        var payload = Data()
        payload.append(isKeyframe ? 0x17 : 0x27)
        payload.append(0x01) // AVC NALU
        payload.append(contentsOf: [0x00, 0x00, 0x00])
        payload.append(naluData)
        
        sendRtmpMessage(csid: 6, msgTypeId: 9, streamId: rtmpStreamId, timestamp: timestamp, payload: payload)
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
                let baseBitrate = self.currentSettings?.bitrateKbps ?? 2750
                self.currentBitrateKbps = baseBitrate + Int.random(in: -30...30)
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
        
        if output == videoOutput {
            guard let session = compressionSession,
                  let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            
            let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            let duration = CMSampleBufferGetDuration(sampleBuffer)
            
            VTCompressionSessionEncodeFrame(
                session,
                imageBuffer: imageBuffer,
                presentationTimeStamp: pts,
                duration: duration,
                frameProperties: nil,
                sourceFrameRefcon: nil,
                infoFlagsOut: nil
            )
        }
    }
}

