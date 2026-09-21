import SwiftUI
import AVFoundation

// MARK: - Camera Preview for FaceCam
public struct CameraPreviewRepresentable: UIViewRepresentable {
    public let session: AVCaptureSession
    
    public init(session: AVCaptureSession) {
        self.session = session
    }
    
    public func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        view.videoPreviewLayer.connection?.videoOrientation = .portrait
        return view
    }
    
    public func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.videoPreviewLayer.connection?.videoOrientation = .portrait
    }
}

public class CameraPreviewUIView: UIView {
    public override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    public var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}

// MARK: - Floating FaceCam Overlay View
public struct FloatingFaceCamView: View {
    @ObservedObject var faceCam = FaceCamService.shared
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    public init() {}
    
    public var body: some View {
        if faceCam.isRunning {
            ZStack {
                CameraPreviewRepresentable(session: faceCam.captureSession)
                    .clipShape(shapeView)
                    .overlay(
                        shapeView
                            .stroke(
                                LinearGradient(
                                    colors: [.red, .orange, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                    )
                    .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 5)
                    .frame(width: faceCam.size, height: faceCam.size)
                    .offset(x: offset.width, y: offset.height)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
            }
        }
    }
    
    @ViewBuilder
    private var shapeView: some Shape {
        switch faceCam.currentShape {
        case .circle:
            Circle()
        case .roundedRect:
            RoundedRectangle(cornerRadius: 24, style: .continuous)
        case .square:
            RoundedRectangle(cornerRadius: 8, style: .continuous)
        case .oval:
            Capsule()
        }
    }
}
