import Foundation
import Combine

// MARK: - App & User Preferences
public class UserSettings: ObservableObject {
    public static let shared = UserSettings()
    
    public static let appGroupId = "group.com.laichym.app"
    private let defaults: UserDefaults
    
    @Published public var isVIP: Bool {
        didSet { defaults.set(isVIP, forKey: "isVIP") }
    }
    
    @Published public var showWatermark: Bool {
        didSet { defaults.set(showWatermark, forKey: "showWatermark") }
    }
    
    @Published public var streamSettings: StreamSettings {
        didSet {
            if let data = try? JSONEncoder().encode(streamSettings) {
                defaults.set(data, forKey: "streamSettings")
            }
        }
    }
    
    @Published public var lastStreamDestination: StreamDestination {
        didSet {
            if let data = try? JSONEncoder().encode(lastStreamDestination) {
                defaults.set(data, forKey: "lastStreamDestination")
            }
        }
    }
    
    @Published public var defaultFaceCamShape: FaceCamShape {
        didSet { defaults.set(defaultFaceCamShape.rawValue, forKey: "defaultFaceCamShape") }
    }
    
    public init() {
        self.defaults = UserDefaults(suiteName: UserSettings.appGroupId) ?? UserDefaults.standard
        
        self.isVIP = defaults.bool(forKey: "isVIP")
        self.showWatermark = defaults.object(forKey: "showWatermark") != nil ? defaults.bool(forKey: "showWatermark") : true
        
        if let data = defaults.data(forKey: "streamSettings"),
           let decoded = try? JSONDecoder().decode(StreamSettings.self, from: data) {
            self.streamSettings = decoded
        } else {
            self.streamSettings = StreamSettings()
        }
        
        if let data = defaults.data(forKey: "lastStreamDestination"),
           let decoded = try? JSONDecoder().decode(StreamDestination.self, from: data) {
            self.lastStreamDestination = decoded
        } else {
            self.lastStreamDestination = StreamDestination()
        }
        
        if let shapeRaw = defaults.string(forKey: "defaultFaceCamShape"),
           let shape = FaceCamShape(rawValue: shapeRaw) {
            self.defaultFaceCamShape = shape
        } else {
            self.defaultFaceCamShape = .circle
        }
    }
}
