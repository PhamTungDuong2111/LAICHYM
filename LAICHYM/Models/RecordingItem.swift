import Foundation
import SwiftUI

// MARK: - Recording Item Model
public struct RecordingItem: Identifiable, Codable, Equatable {
    public let id: UUID
    public var title: String
    public let fileName: String
    public let creationDate: Date
    public var duration: TimeInterval
    public var fileSize: Int64
    public var resolution: String
    public var fps: Int
    public var isFavorite: Bool
    public var customThumbnailPath: String?
    
    public init(
        id: UUID = UUID(),
        title: String,
        fileName: String,
        creationDate: Date = Date(),
        duration: TimeInterval = 0,
        fileSize: Int64 = 0,
        resolution: String = "1080p",
        fps: Int = 60,
        isFavorite: Bool = false,
        customThumbnailPath: String? = nil
    ) {
        self.id = id
        self.title = title
        self.fileName = fileName
        self.creationDate = creationDate
        self.duration = duration
        self.fileSize = fileSize
        self.resolution = resolution
        self.fps = fps
        self.isFavorite = isFavorite
        self.customThumbnailPath = customThumbnailPath
    }
    
    public var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    public var formattedFileSize: String {
        let mb = Double(fileSize) / (1024.0 * 1024.0)
        if mb >= 1000 {
            return String(format: "%.1f GB", mb / 1024.0)
        }
        return String(format: "%.1f MB", mb)
    }
    
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: creationDate)
    }
}
