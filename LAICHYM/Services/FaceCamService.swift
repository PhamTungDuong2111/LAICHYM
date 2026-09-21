import Foundation
import AVFoundation
import UIKit
import Combine

// MARK: - FaceCam & Reaction Service
public class FaceCamService: NSObject, ObservableObject {
    public static let shared = FaceCamService()
    
    @Published public var isRunning: Bool = false
    @Published public var currentShape: FaceCamShape = .circle
    @Published public var position: CGPoint = CGPoint(x: 100, y: 150)
    @Published public var size: CGFloat = 140
    @Published public var isMuted: Bool = false
    
    public let captureSession = AVCaptureSession()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var audioDeviceInput: AVCaptureDeviceInput?
    private var movieFileOutput: AVCaptureMovieFileOutput?
    
    public override init() {
        super.init()
    }
    
    public func setupSession(enableAudio: Bool = true) {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high
        
        // Cấu hình Camera trước (Front Camera)
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("Không tìm thấy camera trước")
            captureSession.commitConfiguration()
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: frontCamera)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
                self.videoDeviceInput = videoInput
            }
        } catch {
            print("Lỗi tạo input camera: \(error)")
        }
        
        // Cấu hình Microphone nếu cần ghi âm reaction
        if enableAudio, let mic = AVCaptureDevice.default(for: .audio) {
            do {
                let audioInput = try AVCaptureDeviceInput(device: mic)
                if captureSession.canAddInput(audioInput) {
                    captureSession.addInput(audioInput)
                    self.audioDeviceInput = audioInput
                }
            } catch {
                print("Lỗi tạo input microphone: \(error)")
            }
        }
        
        // Movie File Output để lưu phản ứng nếu người dùng quay Reaction
        let movieOutput = AVCaptureMovieFileOutput()
        if captureSession.canAddOutput(movieOutput) {
            captureSession.addOutput(movieOutput)
            self.movieFileOutput = movieOutput
        }
        
        captureSession.commitConfiguration()
    }
    
    public func startFaceCam() {
        if !captureSession.inputs.isEmpty {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
                DispatchQueue.main.async {
                    self?.isRunning = true
                }
            }
        } else {
            setupSession()
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
                DispatchQueue.main.async {
                    self?.isRunning = true
                }
            }
        }
    }
    
    public func stopFaceCam() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.stopRunning()
            DispatchQueue.main.async {
                self?.isRunning = false
            }
        }
    }
    
    public func startReactionRecording(outputUrl: URL, completion: @escaping (Bool) -> Void) {
        guard let movieOutput = movieFileOutput, isRunning else {
            completion(false)
            return
        }
        movieOutput.startRecording(to: outputUrl, recordingDelegate: self)
        completion(true)
    }
    
    public func stopReactionRecording() {
        movieFileOutput?.stopRecording()
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension FaceCamService: AVCaptureFileOutputRecordingDelegate {
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Ghi reaction kết thúc với lỗi: \(error)")
        } else {
            print("Ghi reaction thành công: \(outputFileURL)")
        }
    }
}
