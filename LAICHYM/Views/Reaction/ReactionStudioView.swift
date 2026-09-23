import SwiftUI
import AVFoundation

// MARK: - Reaction Studio View with Bilingual Support
public struct ReactionStudioView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var storage = StorageManager.shared
    @ObservedObject var faceCam = FaceCamService.shared
    @ObservedObject var lang = LanguageManager.shared
    
    @State private var selectedVideo: RecordingItem? = nil
    @State private var isReactionRecording = false
    @State private var reactionDuration: TimeInterval = 0
    @State private var timer: Timer? = nil
    @State private var player: AVPlayer? = nil
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.06, green: 0.08, blue: 0.12).ignoresSafeArea()
                
                VStack(spacing: 16) {
                    if let video = selectedVideo {
                        // Reaction Playground with Video & FaceCam PiP
                        reactionStageView(video: video)
                    } else {
                        // Select Base Video View
                        videoSelectorPrompt
                    }
                    
                    Spacer()
                    
                    // Controls & Tools
                    bottomControls
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
            }
            .navigationTitle(lang.s("reaction_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(lang.s("done")) {
                        stopReaction()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .onAppear {
                faceCam.startFaceCam()
            }
            .onDisappear {
                stopReaction()
                faceCam.stopFaceCam()
            }
        }
    }
    
    // MARK: - Video Selector Prompt
    private var videoSelectorPrompt: some View {
        VStack(spacing: 20) {
            Image(systemName: "film.stack")
                .font(.system(size: 48))
                .foregroundColor(.pink)
                .padding(.top, 40)
            
            Text(lang.s("reaction_select_prompt"))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text(lang.s("reaction_select_hint"))
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            if storage.recordings.isEmpty {
                Text(lang.s("reaction_empty_library"))
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(storage.recordings) { item in
                            Button(action: { setupPlayer(for: item) }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.pink)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.title)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text("\(item.formattedDuration) • \(item.formattedFileSize)")
                                            .font(.system(size: 11))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white.opacity(0.3))
                                }
                                .padding(12)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
        }
    }
    
    // MARK: - Reaction Stage View
    private func reactionStageView(video: RecordingItem) -> some View {
        ZStack(alignment: .topTrailing) {
            // Main Base Video Player
            if let player = player {
                VideoPlayerRepresentable(player: player)
                    .frame(height: 280)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            }
            
            // FaceCam PiP Overlay
            FloatingFaceCamView()
                .frame(width: 120, height: 120)
                .padding(12)
        }
    }
    
    // MARK: - Bottom Controls
    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Shape Selector for FaceCam
            HStack(spacing: 12) {
                ForEach(FaceCamShape.allCases) { shape in
                    Button(action: { faceCam.currentShape = shape }) {
                        Text(shape.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(faceCam.currentShape == shape ? .white : .white.opacity(0.6))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(faceCam.currentShape == shape ? Color.pink : Color.white.opacity(0.08))
                            )
                    }
                }
            }
            
            // Record Reaction Button
            Button(action: toggleReactionRecording) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(isReactionRecording ? Color.red : Color.pink)
                        .frame(width: 14, height: 14)
                    
                    Text(isReactionRecording ? "\(lang.s("reaction_stop")) (\(Int(reactionDuration))s)" : lang.s("reaction_start"))
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: isReactionRecording ? [Color.red, Color.orange] : [Color.pink, Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color.pink.opacity(0.4), radius: 10, x: 0, y: 5)
            }
        }
        .padding(.bottom, 20)
    }
    
    private func setupPlayer(for item: RecordingItem) {
        self.selectedVideo = item
        let url = StorageManager.shared.fileUrl(for: item)
        self.player = AVPlayer(url: url)
    }
    
    private func toggleReactionRecording() {
        if isReactionRecording {
            stopReaction()
        } else {
            startReaction()
        }
    }
    
    private func startReaction() {
        isReactionRecording = true
        reactionDuration = 0
        player?.seek(to: .zero)
        player?.play()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            reactionDuration += 1
        }
    }
    
    private func stopReaction() {
        isReactionRecording = false
        timer?.invalidate()
        timer = nil
        player?.pause()
    }
}
