//
//  ContentView.swift
//  demo
//
//  Created by Harshit Mishra on 19/06/25.
//

import SwiftUI
import AVKit
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var isPickerPresented = false
    @State private var videoURLs: [URL] = []
    @State private var currentVideoIndex = 0
    @State private var showMenu = false
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            // Full-screen video player
            if !videoURLs.isEmpty {
                FullScreenVideoPlayer(
                    videoURLs: videoURLs,
                    currentIndex: $currentVideoIndex,
                    player: $player
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
                                if !videoURLs.isEmpty {
                                    Text("\(currentVideoIndex + 1)/\(videoURLs.count)")
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
            if !videoURLs.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Text(videoURLs[currentVideoIndex].lastPathComponent)
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
            FolderPicker(videoURLs: $videoURLs, currentIndex: $currentVideoIndex)
        }
        .onChange(of: videoURLs) { _, newVideos in
            if !newVideos.isEmpty {
                currentVideoIndex = 0
                playCurrentVideo()
            }
        }
        .onChange(of: currentVideoIndex) { _, _ in
            playCurrentVideo()
        }
    }
    
    private func nextVideo() {
        if currentVideoIndex < videoURLs.count - 1 {
            currentVideoIndex += 1
        }
    }
    
    private func previousVideo() {
        if currentVideoIndex > 0 {
            currentVideoIndex -= 1
        }
    }
    
    private func playCurrentVideo() {
        guard !videoURLs.isEmpty else { return }
        let currentURL = videoURLs[currentVideoIndex]
        player = AVPlayer(url: currentURL)
        player?.play()
    }
}

struct FullScreenVideoPlayer: View {
    let videoURLs: [URL]
    @Binding var currentIndex: Int
    @Binding var player: AVPlayer?
    
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
    @Binding var videoURLs: [URL]
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
            
            // Start accessing the security-scoped resource
            guard folderURL.startAccessingSecurityScopedResource() else {
                print("Failed to access security-scoped resource")
                return
            }
            
            defer {
                folderURL.stopAccessingSecurityScopedResource()
            }
            
            // Get video files from the selected folder
            let videoExtensions = ["mp4", "mov", "avi", "mkv", "m4v", "wmv", "flv", "webm"]
            var videos: [URL] = []
            
            do {
                let contents = try FileManager.default.contentsOfDirectory(
                    at: folderURL,
                    includingPropertiesForKeys: [.isRegularFileKey],
                    options: [.skipsHiddenFiles]
                )
                
                for url in contents {
                    let resourceValues = try url.resourceValues(forKeys: [.isRegularFileKey])
                    if resourceValues.isRegularFile == true {
                        let fileExtension = url.pathExtension.lowercased()
                        if videoExtensions.contains(fileExtension) {
                            videos.append(url)
                        }
                    }
                }
                
                // Sort videos by name
                videos.sort { $0.lastPathComponent < $1.lastPathComponent }
                
                DispatchQueue.main.async {
                    self.parent.videoURLs = videos
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
