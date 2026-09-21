import Foundation
import AVFoundation
import UIKit
import CoreGraphics

// MARK: - Video Editor Service (Trimming, Cropping, Audio Mixing, Watermark)
public class VideoEditorService: ObservableObject {
    public static let shared = VideoEditorService()
    
    @Published public var isExporting: Bool = false
    @Published public var exportProgress: Float = 0.0
    
    // MARK: - Process Video (Trim + Crop + Audio Mix + Watermark)
    public func processVideo(
        inputUrl: URL,
        outputUrl: URL,
        config: VideoEditConfig,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        let asset = AVURLAsset(url: inputUrl)
        
        let composition = AVMutableComposition()
        guard let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let assetVideoTrack = asset.tracks(withMediaType: .video).first else {
            completion(.failure(NSError(domain: "LAICHYM", code: -1, userInfo: [NSLocalizedDescriptionKey: "Không tìm thấy track video"])))
            return
        }
        
        let startCMTime = CMTime(seconds: config.startTime, preferredTimescale: 600)
        let durationCMTime = CMTime(seconds: max(0.5, config.endTime - config.startTime), preferredTimescale: 600)
        let timeRange = CMTimeRange(start: startCMTime, duration: durationCMTime)
        
        do {
            try compositionVideoTrack.insertTimeRange(timeRange, of: assetVideoTrack, at: .zero)
            compositionVideoTrack.preferredTransform = assetVideoTrack.preferredTransform
        } catch {
            completion(.failure(error))
            return
        }
        
        // MARK: - Audio Mixing Track
        let audioMix = AVMutableAudioMix()
        var audioMixParams: [AVMutableAudioMixInputParameters] = []
        
        // 1. Original Audio
        if let assetAudioTrack = asset.tracks(withMediaType: .audio).first,
           let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            try? compositionAudioTrack.insertTimeRange(timeRange, of: assetAudioTrack, at: .zero)
            
            let originalParams = AVMutableAudioMixInputParameters(track: compositionAudioTrack)
            originalParams.setVolume(config.originalAudioVolume, at: .zero)
            audioMixParams.append(originalParams)
        }
        
        // 2. Voiceover Audio (nếu có lồng tiếng)
        if let voiceoverUrl = config.voiceoverAudioUrl {
            let voiceAsset = AVURLAsset(url: voiceoverUrl)
            if let voiceTrack = voiceAsset.tracks(withMediaType: .audio).first,
               let compositionVoiceTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                let voiceDuration = min(durationCMTime, voiceAsset.duration)
                let voiceRange = CMTimeRange(start: .zero, duration: voiceDuration)
                try? compositionVoiceTrack.insertTimeRange(voiceRange, of: voiceTrack, at: .zero)
                
                let voiceParams = AVMutableAudioMixInputParameters(track: compositionVoiceTrack)
                voiceParams.setVolume(config.voiceoverAudioVolume, at: .zero)
                audioMixParams.append(voiceParams)
            }
        }
        
        audioMix.inputParameters = audioMixParams
        
        // MARK: - Video Composition (Cropping & Watermark)
        let naturalSize = assetVideoTrack.naturalSize.applying(assetVideoTrack.preferredTransform)
        let renderWidth = abs(naturalSize.width)
        let renderHeight = abs(naturalSize.height)
        
        var targetSize = CGSize(width: renderWidth, height: renderHeight)
        if let ratio = config.cropRatio.ratio {
            if ratio < 1.0 { // Vertical 9:16 or 4:5
                let newWidth = renderHeight * ratio
                targetSize = CGSize(width: min(newWidth, renderWidth), height: renderHeight)
            } else { // Horizontal 16:9 or 1:1
                let newHeight = renderWidth / ratio
                targetSize = CGSize(width: renderWidth, height: min(newHeight, renderHeight))
            }
        }
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = targetSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: durationCMTime)
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
        
        // Center crop transform
        let tx = (targetSize.width - renderWidth) / 2.0
        let ty = (targetSize.height - renderHeight) / 2.0
        var transform = assetVideoTrack.preferredTransform
        transform = transform.concatenating(CGAffineTransform(translationX: tx, y: ty))
        layerInstruction.setTransform(transform, at: .zero)
        
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]
        
        // Watermark Overlay nếu không phải người dùng VIP hoặc được kích hoạt
        if config.showWatermark {
            addWatermarkOverlay(to: videoComposition, videoSize: targetSize)
        }
        
        // MARK: - Export Session
        try? FileManager.default.removeItem(at: outputUrl)
        
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            completion(.failure(NSError(domain: "LAICHYM", code: -2, userInfo: [NSLocalizedDescriptionKey: "Không thể khởi tạo Export Session"])))
            return
        }
        
        exportSession.outputURL = outputUrl
        exportSession.outputFileType = .mp4
        exportSession.videoComposition = videoComposition
        exportSession.audioMix = audioMix
        exportSession.shouldOptimizeForNetworkUse = true
        
        DispatchQueue.main.async {
            self.isExporting = true
            self.exportProgress = 0.0
        }
        
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.exportProgress = exportSession.progress
            }
        }
        
        exportSession.exportAsynchronously {
            timer.invalidate()
            DispatchQueue.main.async {
                self.isExporting = false
                if exportSession.status == .completed {
                    completion(.success(outputUrl))
                } else {
                    completion(.failure(exportSession.error ?? NSError(domain: "LAICHYM", code: -3, userInfo: [NSLocalizedDescriptionKey: "Lỗi xuất video"])))
                }
            }
        }
    }
    
    // MARK: - Watermark Layer
    private func addWatermarkOverlay(to videoComposition: AVMutableVideoComposition, videoSize: CGSize) {
        let parentLayer = CALayer()
        let videoLayer = CALayer()
        parentLayer.frame = CGRect(origin: .zero, size: videoSize)
        videoLayer.frame = CGRect(origin: .zero, size: videoSize)
        parentLayer.addSublayer(videoLayer)
        
        // Text Badge Watermark
        let watermarkLayer = CATextLayer()
        watermarkLayer.string = "  LAICHYM Screen Recorder  "
        watermarkLayer.font = UIFont.boldSystemFont(ofSize: 20)
        watermarkLayer.fontSize = 18
        watermarkLayer.foregroundColor = UIColor.white.cgColor
        watermarkLayer.backgroundColor = UIColor.black.withAlphaComponent(0.6).cgColor
        watermarkLayer.cornerRadius = 8
        watermarkLayer.masksToBounds = true
        watermarkLayer.alignmentMode = .center
        watermarkLayer.contentsScale = UIScreen.main.scale
        
        let badgeWidth: CGFloat = 260
        let badgeHeight: CGFloat = 36
        watermarkLayer.frame = CGRect(
            x: videoSize.width - badgeWidth - 20,
            y: 20,
            width: badgeWidth,
            height: badgeHeight
        )
        parentLayer.addSublayer(watermarkLayer)
        
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
            postProcessingAsVideoLayer: videoLayer,
            in: parentLayer
        )
    }
}
