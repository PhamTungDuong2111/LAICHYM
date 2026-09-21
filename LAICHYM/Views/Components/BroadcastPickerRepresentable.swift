import SwiftUI
import ReplayKit

// MARK: - RPSystemBroadcastPickerView Representable for SwiftUI
public struct BroadcastPickerRepresentable: UIViewRepresentable {
    public var preferredExtension: String = "com.laichym.app.broadcast"
    public var showsMicrophoneButton: Bool = true
    
    public init(preferredExtension: String = "com.laichym.app.broadcast", showsMicrophoneButton: Bool = true) {
        self.preferredExtension = preferredExtension
        self.showsMicrophoneButton = showsMicrophoneButton
    }
    
    public func makeUIView(context: Context) -> RPSystemBroadcastPickerView {
        let picker = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 64, height: 64))
        picker.preferredExtension = preferredExtension
        picker.showsMicrophoneButton = showsMicrophoneButton
        
        // Tùy biến nút bấm của picker
        for subview in picker.subviews {
            if let button = subview as? UIButton {
                button.setImage(nil, for: .normal)
                button.backgroundColor = .clear
            }
        }
        
        return picker
    }
    
    public func updateUIView(_ uiView: RPSystemBroadcastPickerView, context: Context) {
        uiView.preferredExtension = preferredExtension
        uiView.showsMicrophoneButton = showsMicrophoneButton
    }
}
