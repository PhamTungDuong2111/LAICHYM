import Foundation
import UIKit
import AVFoundation
import Photos

// MARK: - Video & Storage Manager
public class StorageManager: ObservableObject {
    public static let shared = StorageManager()
    
    @Published public var recordings: [RecordingItem] = []
    
    public var storageDirectoryURL: URL {
        if let sharedContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: UserSettings.appGroupId) {
            let dir = sharedContainer.appendingPathComponent("Recordings", isDirectory: true)
            if !FileManager.default.fileExists(atPath: dir.path) {
                try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            }
            return dir
        } else {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let dir = docs.appendingPathComponent("Recordings", isDirectory: true)
            if !FileManager.default.fileExists(atPath: dir.path) {
                try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            }
            return dir
        }
    }
    
    public init() {
        loadRecordings()
    }
    
    public func loadRecordings() {
        let dir = storageDirectoryURL
        guard let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey], options: .skipsHiddenFiles) else {
            self.recordings = []
            return
        }
        
        let videoFiles = files.filter { $0.pathExtension.lowercased() == "mp4" || $0.pathExtension.lowercased() == "mov" }
        
        var items: [RecordingItem] = []
        for file in videoFiles {
            let asset = AVURLAsset(url: file)
            let durationSeconds = CMTimeGetSeconds(asset.duration)
            let fileSize = (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            let modDate = (try? file.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date()
            
            var resolutionStr = "1080p"
            var fpsVal = 60
            if let track = asset.tracks(withMediaType: .video).first {
                let size = track.naturalSize
                resolutionStr = "\(Int(size.width))x\(Int(size.height))"
                fpsVal = Int(round(track.nominalFrameRate))
            }
            
            let nameWithoutExt = file.deletingPathExtension().lastPathComponent
            let item = RecordingItem(
                title: nameWithoutExt,
                fileName: file.lastPathComponent,
                creationDate: modDate,
                duration: durationSeconds.isNaN ? 0 : durationSeconds,
                fileSize: Int64(fileSize),
                resolution: resolutionStr,
                fps: fpsVal > 0 ? fpsVal : 60
            )
            items.append(item)
        }
        
        self.recordings = items.sorted(by: { $0.creationDate > $1.creationDate })
    }
    
    public func fileUrl(for item: RecordingItem) -> URL {
        return storageDirectoryURL.appendingPathComponent(item.fileName)
    }
    
    public func generateThumbnail(for item: RecordingItem, completion: @escaping (UIImage?) -> Void) {
        let url = fileUrl(for: item)
        DispatchQueue.global(qos: .userInitiated).async {
            let asset = AVURLAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 400, height: 400)
            
            let time = CMTime(seconds: min(1.0, item.duration / 2.0), preferredTimescale: 600)
            do {
                let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
                let image = UIImage(cgImage: cgImage)
                DispatchQueue.main.async { completion(image) }
            } catch {
                DispatchQueue.main.async { completion(nil) }
            }
        }
    }
    
    public func deleteRecording(_ item: RecordingItem) {
        let url = fileUrl(for: item)
        try? FileManager.default.removeItem(at: url)
        loadRecordings()
    }
    
    public func renameRecording(_ item: RecordingItem, newTitle: String) {
        let oldUrl = fileUrl(for: item)
        let ext = oldUrl.pathExtension
        let safeTitle = newTitle.replacingOccurrences(of: "/", with: "-")
        let newUrl = storageDirectoryURL.appendingPathComponent("\(safeTitle).\(ext)")
        
        do {
            try FileManager.default.moveItem(at: oldUrl, to: newUrl)
            loadRecordings()
        } catch {
            print("Lỗi đổi tên: \(error)")
        }
    }
    
    public func saveToCameraRoll(item: RecordingItem, completion: @escaping (Bool, Error?) -> Void) {
        let url = fileUrl(for: item)
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    completion(false, NSError(domain: "LAICHYM", code: 401, userInfo: [NSLocalizedDescriptionKey: "Quyền truy cập Ảnh chưa được cấp"]))
                }
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }) { success, error in
                DispatchQueue.main.async {
                    completion(success, error)
                }
            }
        }
    }
}
