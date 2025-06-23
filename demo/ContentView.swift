//  ContentView.swift
//  demo
//
//  Created by Harshit Mishra on 20/06/25.

// Define an enum to represent the media type
enum MediaType: String, Codable {
    case video
    case image
    case gif
    case unknown // For any unsupported types, good for error handling
}

struct MediaFile: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let name: String
    let type: MediaType
    let bookmark: Data?

    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
        self.type = MediaFile.determineMediaType(from: url.pathExtension)
        do {
            self.bookmark = try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
        } catch {
            print("Failed to create bookmark for \(url.lastPathComponent): \(error)")
            self.bookmark = nil
        }
    }

    // Helper to determine media type based on extension
    private static func determineMediaType(from extensionString: String) -> MediaType {
        let lowercasedExtension = extensionString.lowercased()
        let videoExtensions = ["mp4", "mov", "avi", "mkv", "m4v", "wmv", "flv", "webm", "mpg", "mpeg", "3gp"]
        let imageExtensions = ["png", "jpg", "jpeg", "heic"] // Added HEIC
        let gifExtensions = ["gif"]

        if videoExtensions.contains(lowercasedExtension) {
            return .video
        } else if imageExtensions.contains(lowercasedExtension) {
            return .image
        } else if gifExtensions.contains(lowercasedExtension) {
            return .gif
        } else {
            return .unknown
        }
    }

    func getAccessibleURL() -> URL? {
        guard let bookmark = bookmark else {
            return url
        }
        do {
            var isStale = false
            let resolvedURL = try URL(resolvingBookmarkData: bookmark, options: .withoutUI, relativeTo: nil, bookmarkDataIsStale: &isStale)
            guard resolvedURL.startAccessingSecurityScopedResource() else {
                return url
            }
            return resolvedURL
        } catch {
            return url
        }
    }
}

import SwiftUI
import AVKit
import UniformTypeIdentifiers // Import for UTType to help with file types

struct ContentView: View {
    @State private var isPickerPresented = false
    @State private var mediaFiles: [MediaFile] = [] // Changed from videoFiles
    @State private var currentMediaIndex = 0 // Changed from currentVideoIndex
    @State private var showMenu = false
    @State private var currentAccessingURL: URL?
    @State private var slideOffset: CGFloat = 0
    @State private var isAnimating = false
    @State private var activePlayerIndex = 0
    @State private var players: [AVPlayer?] = [nil, nil] // Still for videos
    @State private var shuffledMediaFiles: [MediaFile] = [] // Changed from shuffledVideoFiles

    @AppStorage("VideoAspectMode") private var isAspectFill: Bool = true // Keep for video aspect

    var body: some View {
        ZStack {
            if !mediaFiles.isEmpty {
                // Render the current media based on its type
                GeometryReader { geometry in
                    // Render the active media player/view
                    // This is the "top" player that responds to current interaction
                    MediaDisplayView(
                        mediaFile: mediaFiles[currentMediaIndex],
                        player: players[activePlayerIndex],
                        offsetY: slideOffset,
                        isTopPlayer: true,
                        aspectFill: isAspectFill
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .offset(y: slideOffset)

                    // Render the inactive/preloaded media player/view for smooth transitions
                    // This player is off-screen, ready to slide in
                    let preloadIndex = (currentMediaIndex + (slideOffset > 0 ? -1 : 1) + mediaFiles.count) % mediaFiles.count
                    if mediaFiles.indices.contains(preloadIndex) {
                        MediaDisplayView(
                            mediaFile: mediaFiles[preloadIndex],
                            player: players[(activePlayerIndex + 1) % 2], // The other player slot
                            offsetY: slideOffset > 0 ? -geometry.size.height : geometry.size.height,
                            isTopPlayer: false, // This is not the primary interactive player
                            aspectFill: isAspectFill
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .offset(y: slideOffset > 0 ? -geometry.size.height : geometry.size.height)
                    }
                }
                .ignoresSafeArea()
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if !isAnimating {
                                slideOffset = value.translation.height
                            }
                        }
                        .onEnded { value in
                            handleSwipe(value: value)
                        }
                )
            } else {
                Color.black
                    .ignoresSafeArea()
                VStack {
                    Image(systemName: "photo.on.rectangle.angled") // More general icon
                        .font(.system(size: 80))
                        .foregroundColor(.white.opacity(0.6))
                    Text("Select a folder to start viewing media")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }

            FloatingMenu(
                showMenu: $showMenu,
                isPickerPresented: $isPickerPresented,
                videoFiles: mediaFiles, // Pass mediaFiles
                currentVideoIndex: currentMediaIndex, // Pass currentMediaIndex
                playRandomVideo: playRandomMedia // Renamed for clarity
            )

            if !mediaFiles.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Text(mediaFiles[currentMediaIndex].name)
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
        .onAppear {
            loadSavedFolderIfAny()
        }
        .sheet(isPresented: $isPickerPresented) {
            FolderPicker(mediaFiles: $mediaFiles, currentIndex: $currentMediaIndex) // Update picker
        }
        .onChange(of: mediaFiles) { _, new in
            if !new.isEmpty {
                currentMediaIndex = 0
                shuffledMediaFiles = new.shuffled()
                preloadMedia() // Renamed for clarity
            }
        }
        .onDisappear {
            cleanupCurrentAccess()
        }
    }

    private func handleSwipe(value: DragGesture.Value) {
        if abs(value.translation.height) > 50 && !isAnimating {
            isAnimating = true
            let direction: Int = value.translation.height < 0 ? 1 : -1
            let nextIndex = currentMediaIndex + direction

            guard nextIndex >= 0, nextIndex < mediaFiles.count else {
                withAnimation { slideOffset = 0 }
                isAnimating = false
                return
            }

            // Clean up the current player if it's a video
            if mediaFiles[currentMediaIndex].type == .video {
                players[activePlayerIndex]?.pause()
                players[activePlayerIndex] = nil
            }

            // Prepare the next media item
            let nextMedia = mediaFiles[nextIndex]
            if nextMedia.type == .video {
                let inactiveIndex = (activePlayerIndex + 1) % 2
                if let url = nextMedia.getAccessibleURL() {
                    players[inactiveIndex] = AVPlayer(url: url)
                }
            }

            withAnimation(.easeInOut(duration: 0.3)) {
                slideOffset = CGFloat(direction) * -UIScreen.main.bounds.height
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                currentMediaIndex = nextIndex
                slideOffset = 0
                isAnimating = false

                // Start playing the new video if it's a video
                if mediaFiles[currentMediaIndex].type == .video {
                    let inactiveIndex = (activePlayerIndex + 1) % 2
                    activePlayerIndex = inactiveIndex // Switch to the preloaded player
                    players[activePlayerIndex]?.play()
                }
            }
        } else {
            withAnimation(.easeOut(duration: 0.2)) {
                slideOffset = 0
            }
        }
    }

    private func playRandomMedia() {
        guard !mediaFiles.isEmpty else { return }

        cleanupCurrentAccess()

        // Reset if exhausted
        if shuffledMediaFiles.isEmpty {
            shuffledMediaFiles = mediaFiles.shuffled()
        }

        // Pop one random item (from front)
        let nextMedia = shuffledMediaFiles.removeFirst()

        // Get the new index in main list (for UI display)
        if let newIndex = mediaFiles.firstIndex(of: nextMedia) {
            currentMediaIndex = newIndex
        }

        // Clean up current player if it's a video
        players[activePlayerIndex]?.pause()
        if mediaFiles[currentMediaIndex].type == .video {
            players[activePlayerIndex] = nil
        }
        


        // Load and play the new media
        if let url = nextMedia.getAccessibleURL() {
            currentAccessingURL = url
            if nextMedia.type == .video {
                let inactiveIndex = (activePlayerIndex + 1) % 2 // Use the inactive player slot
                players[inactiveIndex] = AVPlayer(url: url)
                activePlayerIndex = inactiveIndex // Make it the active player
                players[activePlayerIndex]?.play()
            }
            // For images/GIFs, simply setting currentMediaIndex will trigger the view update
        }
    }

    private func preloadMedia() {
        cleanupCurrentAccess()
        activePlayerIndex = 0 // Reset active player to the first one

        // Pause and clear the secondary player if it holds a video
        players[1]?.pause()
        players[1] = nil

        guard !mediaFiles.isEmpty else { return }

        let currentMedia = mediaFiles[currentMediaIndex]
        if let url = currentMedia.getAccessibleURL() {
            currentAccessingURL = url
            if currentMedia.type == .video {
                print("Playing video \(currentMedia.name)")
                players[0] = AVPlayer(url: url)
                players[0]?.play()
            }
            // Images and GIFs don't need AVPlayer preloading
        }
    }

    private func cleanupCurrentAccess() {
        if let url = currentAccessingURL {
            url.stopAccessingSecurityScopedResource()
            currentAccessingURL = nil
        }
    }

    private func loadSavedFolderIfAny() {
        guard let bookmark = UserDefaults.standard.data(forKey: "SavedFolderBookmark") else { return }

        var isStale = false
        do {
            let resolvedURL = try URL(
                resolvingBookmarkData: bookmark,
                options: [.withoutUI],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            guard resolvedURL.startAccessingSecurityScopedResource() else {
                print("Failed to access saved folder")
                return
            }

            loadMedia(from: resolvedURL) // Renamed for clarity

            // No need to stop access immediately — keep until app closes
        } catch {
            print("Error resolving saved folder: \(error)")
        }
    }

    private func loadMedia(from folderURL: URL) {
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: folderURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )

            var found: [MediaFile] = []

            for url in contents {
                let values = try url.resourceValues(forKeys: [.isRegularFileKey])
                if values.isRegularFile == true {
                    let mediaFile = MediaFile(url: url)
                    if mediaFile.type != .unknown { // Only add supported types
                        found.append(mediaFile)
                    }
                }
            }

            print("Found content in the folder :", found)
            found.shuffle()

            DispatchQueue.main.async {
                mediaFiles = found
                currentMediaIndex = 0
                shuffledMediaFiles = found.shuffled()
                preloadMedia()
            }

        } catch {
            print("Failed to load saved folder contents: \(error)")
        }
    }
}
