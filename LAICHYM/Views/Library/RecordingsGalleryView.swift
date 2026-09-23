import SwiftUI
import AVKit

// MARK: - Recordings Gallery View with Bilingual Support
public struct RecordingsGalleryView: View {
    @ObservedObject var storage = StorageManager.shared
    @ObservedObject var lang = LanguageManager.shared
    @State private var selectedItem: RecordingItem? = nil
    @State private var searchText: String = ""
    @State private var isGridView: Bool = true
    
    public init() {}
    
    private var filteredRecordings: [RecordingItem] {
        if searchText.isEmpty {
            return storage.recordings
        } else {
            return storage.recordings.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.06, green: 0.08, blue: 0.12).ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Search & View Mode Switcher
                    searchAndControlBar
                    
                    if filteredRecordings.isEmpty {
                        emptyStateView
                    } else {
                        if isGridView {
                            gridView
                        } else {
                            listView
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .navigationTitle(lang.s("lib_title"))
            .sheet(item: $selectedItem) { item in
                VideoDetailSheet(item: item)
            }
            .onAppear {
                storage.loadRecordings()
            }
        }
    }
    
    // MARK: - Search & Control Bar
    private var searchAndControlBar: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.4))
                TextField(lang.s("lib_search_placeholder"), text: $searchText)
                    .foregroundColor(.white)
                    .font(.system(size: 14))
            }
            .padding(10)
            .background(Color.white.opacity(0.08))
            .cornerRadius(12)
            
            Button(action: { isGridView.toggle() }) {
                Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "film")
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.2))
            Text(lang.s("lib_empty_title"))
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white.opacity(0.7))
            Text(lang.s("lib_empty_desc"))
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
    
    // MARK: - Grid View
    private var gridView: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                ForEach(filteredRecordings) { item in
                    Button(action: { selectedItem = item }) {
                        RecordingThumbnailCard(item: item)
                    }
                }
            }
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - List View
    private var listView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(filteredRecordings) { item in
                    Button(action: { selectedItem = item }) {
                        HStack(spacing: 14) {
                            RecordingThumbnailCard(item: item)
                                .frame(width: 100)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                Text("\(item.resolution) • \(item.fps) FPS")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.6))
                                
                                Text("\(item.formattedDate) • \(item.formattedFileSize)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white.opacity(0.3))
                                .font(.system(size: 12))
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(14)
                    }
                }
            }
            .padding(.bottom, 30)
        }
    }
}

// MARK: - Video Detail & Actions Sheet with Bilingual Support
public struct VideoDetailSheet: View {
    let item: RecordingItem
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var storage = StorageManager.shared
    @ObservedObject var lang = LanguageManager.shared
    
    @State private var player: AVPlayer? = nil
    @State private var showRenameDialog = false
    @State private var newTitleText = ""
    @State private var showSaveSuccessAlert = false
    @State private var isSharing = false
    
    public var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.06, green: 0.08, blue: 0.12).ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Video Player
                    if let player = player {
                        VideoPlayerRepresentable(player: player)
                            .frame(height: 280)
                            .cornerRadius(16)
                    }
                    
                    // Metadata Info
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 12) {
                            Label(item.formattedDuration, systemImage: "clock")
                            Label(item.resolution, systemImage: "aspectratio")
                            Label(item.formattedFileSize, systemImage: "internaldrive")
                        }
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    
                    // Action Buttons Grid
                    VStack(spacing: 12) {
                        // Save to Photos (Camera Roll)
                        Button(action: saveToPhotos) {
                            HStack {
                                Image(systemName: "square.and.arrow.down.fill")
                                Text(lang.s("lib_save_photos"))
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.blue)
                            .cornerRadius(14)
                        }
                        
                        HStack(spacing: 12) {
                            // Share
                            Button(action: { isSharing = true }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text(lang.s("share"))
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                            }
                            
                            // Rename
                            Button(action: {
                                newTitleText = item.title
                                showRenameDialog = true
                            }) {
                                HStack {
                                    Image(systemName: "pencil")
                                    Text(lang.s("rename"))
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                            }
                            
                            // Delete
                            Button(action: deleteVideo) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                    Text(lang.s("delete"))
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.red.opacity(0.15))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    Spacer()
                }
                .padding(.top, 10)
            }
            .navigationTitle(lang.s("lib_detail_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(lang.s("close")) {
                        player?.pause()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .onAppear {
                let url = storage.fileUrl(for: item)
                self.player = AVPlayer(url: url)
            }
            .alert(isPresented: $showSaveSuccessAlert) {
                Alert(
                    title: Text(lang.s("success")),
                    message: Text(lang.s("lib_save_success")),
                    dismissButton: .default(Text(lang.s("ok")))
                )
            }
            .sheet(isPresented: $isSharing) {
                let url = storage.fileUrl(for: item)
                ShareSheet(activityItems: [url])
            }
        }
    }
    
    private func saveToPhotos() {
        storage.saveToCameraRoll(item: item) { success, _ in
            if success {
                showSaveSuccessAlert = true
            }
        }
    }
    
    private func deleteVideo() {
        player?.pause()
        storage.deleteRecording(item)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Native iOS UIActivityViewController Share Sheet
public struct ShareSheet: UIViewControllerRepresentable {
    public let activityItems: [Any]
    
    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
