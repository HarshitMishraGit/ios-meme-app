//
//  ContentView.swift
//  demo
//
//  Created by Harshit Mishra on 19/06/25.
//

import SwiftUI
import AVKit
import UniformTypeIdentifiers

// Video file wrapper to handle security-scoped resources
struct VideoFile: Equatable {
    let url: URL
    let bookmark: Data?
    let name: String
    
    // Equatable conformance
    static func == (lhs: VideoFile, rhs: VideoFile) -> Bool {
        return lhs.url == rhs.url && lhs.name == rhs.name
    }
    
    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
        
        // Create security-scoped bookmark
        do {
            self.bookmark = try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
        } catch {
            print("Failed to create bookmark for \(url.lastPathComponent): \(error)")
            self.bookmark = nil
        }
    }
    
    // Get URL with proper security access
    func getAccessibleURL() -> URL? {
        guard let bookmark = bookmark else {
            print("No bookmark available for \(name)")
            return url // Try original URL as fallback
        }
        
        do {
            var isStale = false
            let resolvedURL = try URL(resolvingBookmarkData: bookmark, options: .withoutUI, relativeTo: nil, bookmarkDataIsStale: &isStale)
            
            if isStale {
                print("Bookmark is stale for \(name)")
                return url // Fallback to original URL
            }
            
            // Start accessing the security-scoped resource
            guard resolvedURL.startAccessingSecurityScopedResource() else {
                print("Failed to start accessing security-scoped resource for \(name)")
                return url // Fallback to original URL
            }
            
            return resolvedURL
        } catch {
            print("Failed to resolve bookmark for \(name): \(error)")
            return url // Fallback to original URL
        }
    }
}

struct ContentView: View {
    @State private var isPickerPresented = false
    @State private var videoFiles: [VideoFile] = []
    @State private var currentVideoIndex = 0
    @State private var showMenu = false
    @State private var player: AVPlayer?
    @State private var currentAccessingURL: URL? // Track currently accessing URL for cleanup
    
    var body: some View {
        ZStack {
            // Full-screen video player
            if !videoFiles.isEmpty {
                FullScreenVideoPlayer(
                    videoFiles: videoFiles,
                    currentIndex: $currentVideoIndex,
                    player: $player,
                    currentAccessingURL: $currentAccessingURL
                )
                .ignoresSafeArea()
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            if abs(value.translation.height) > 50 {
                                if value.translation.height < 0 {
                                    // Swipe up - next video
                                    nextVideo()
                                } else {
                                    // Swipe down - previous video
                                    previousVideo()
                                }
                            }
                        }
                )
            } else {
                // Initial state - no videos selected
                Color.black
                    .ignoresSafeArea()
                
                VStack {
                    Image(systemName: "film")
                        .font(.system(size: 80))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("Select a folder to start watching videos")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
            
            // Top-right menu overlay
            VStack {
                HStack {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        // Menu toggle button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showMenu.toggle()
                            }
                        }) {
                            Image(systemName: showMenu ? "xmark" : "ellipsis")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        
                        // Menu items
                        if showMenu {
                            VStack(spacing: 8) {
                                // Select folder button
                                Button(action: {
                                    isPickerPresented = true
                                    withAnimation {
                                        showMenu = false
                                    }
                                }) {
                                    VStack {
                                        Image(systemName: "folder")
                                            .font(.title3)
                                        Text("Folder")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 50)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(12)
                                }
                                
                                // Video count indicator
                                if !videoFiles.isEmpty {
                                    Text("\(currentVideoIndex + 1)/\(videoFiles.count)")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.black.opacity(0.6))
                                        .cornerRadius(8)
                                }
                            }
                            .transition(.opacity.combined(with: .scale))
                        }
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 20)
                
                Spacer()

                // Video filename overlay at bottom
            if !videoFiles.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Text(videoFiles[currentVideoIndex].name)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(20)
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            }
        }
        .sheet(isPresented: $isPickerPresented) {
            FolderPicker(videoFiles: $videoFiles, currentIndex: $currentVideoIndex)
        }
        .onChange(of: videoFiles) { _, newVideos in
            if !newVideos.isEmpty {
                currentVideoIndex = 0
                playCurrentVideo()
            }
        }
        .onChange(of: currentVideoIndex) { _, _ in
            playCurrentVideo()
        }
        .onDisappear {
            // Clean up security-scoped resource access
            cleanupCurrentAccess()
        }
    }
    
    private func nextVideo() {
        if currentVideoIndex < videoFiles.count - 1 {
            currentVideoIndex += 1
        }
    }
    
    private func previousVideo() {
        if currentVideoIndex > 0 {
            currentVideoIndex -= 1
        }
    }
    
    private func cleanupCurrentAccess() {
        if let url = currentAccessingURL {
            url.stopAccessingSecurityScopedResource()
            currentAccessingURL = nil
        }
    }
    
    private func playCurrentVideo() {
        guard !videoFiles.isEmpty else { return }
        
        // Clean up previous access
        cleanupCurrentAccess()
        
        let videoFile = videoFiles[currentVideoIndex]
        
        guard let accessibleURL = videoFile.getAccessibleURL() else {
            print("Failed to get accessible URL for \(videoFile.name)")
            return
        }
        
        // Store the URL for cleanup later
        currentAccessingURL = accessibleURL
        
        print("Playing video: \(videoFile.name)")
        print("URL: \(accessibleURL)")
        
        player = AVPlayer(url: accessibleURL)
        player?.play()
    }
}

struct FullScreenVideoPlayer: View {
    let videoFiles: [VideoFile]
    @Binding var currentIndex: Int
    @Binding var player: AVPlayer?
    @Binding var currentAccessingURL: URL?
    
    var body: some View {
        if let player = player {
            VideoPlayer(player: player)
                .onAppear {
                    player.play()
                }
        } else {
            Color.black
        }
    }
}

struct FolderPicker: UIViewControllerRepresentable {
    @Binding var videoFiles: [VideoFile]
    @Binding var currentIndex: Int
    @Environment(\.dismiss) private var dismiss
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.folder], asCopy: false)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: FolderPicker
        
        init(_ parent: FolderPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let folderURL = urls.first else { return }
            
            print("Selected folder: \(folderURL)")
            
            // Start accessing the security-scoped resource
            guard folderURL.startAccessingSecurityScopedResource() else {
                print("Failed to access security-scoped resource for folder")
                return
            }
            
            defer {
                folderURL.stopAccessingSecurityScopedResource()
            }
            
            // Get video files from the selected folder
            let videoExtensions = ["mp4", "mov", "avi", "mkv", "m4v", "wmv", "flv", "webm", "mpg", "mpeg", "3gp"]
            var videoFiles: [VideoFile] = []
            
            do {
                let contents = try FileManager.default.contentsOfDirectory(
                    at: folderURL,
                    includingPropertiesForKeys: [.isRegularFileKey],
                    options: [.skipsHiddenFiles]
                )
                
                print("Found \(contents.count) items in folder")
                
                for url in contents {
                    let resourceValues = try url.resourceValues(forKeys: [.isRegularFileKey])
                    if resourceValues.isRegularFile == true {
                        let fileExtension = url.pathExtension.lowercased()
                        if videoExtensions.contains(fileExtension) {
                            print("Found video file: \(url.lastPathComponent)")
                            videoFiles.append(VideoFile(url: url))
                        }
                    }
                }
                
                // Sort videos by name
                videoFiles.sort { $0.name < $1.name }
                
                print("Total video files found: \(videoFiles.count)")
                
                DispatchQueue.main.async {
                    self.parent.videoFiles = videoFiles
                    self.parent.currentIndex = 0
                    self.parent.dismiss()
                }
                
            } catch {
                print("Error reading folder contents: \(error)")
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}

#Preview {
    ContentView()
}
