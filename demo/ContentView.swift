//  ContentView.swift
//  demo
//
//  Created by Harshit Mishra on 20/06/25.

import SwiftUI
import AVKit
import UniformTypeIdentifiers // Import for UTType to help with file types

struct ContentView: View {
    @State private var isPickerPresented = false
    @State private var mediaFiles: [MediaFile] = [] // All loaded files
    @State private var filteredMediaFiles: [MediaFile] = [] // Filtered by type
    @State private var currentMediaIndex = 0 // Index in filteredMediaFiles
    @State private var showMenu = false
    @State private var currentAccessingURL: URL?
    @State private var slideOffset: CGFloat = 0
    @State private var isAnimating = false
    @State private var activePlayerIndex = 0
    @State private var players: [AVPlayer?] = [nil, nil]
    @State private var shuffledMediaFiles: [MediaFile] = []
    @State private var randomHistory: [Int] = []
    @State private var randomHistoryIndex: Int = -1
    @AppStorage("SelectedMediaTypes") private var storedMediaTypes: String = "video,image,gif"
    @State private var selectedMediaTypes: Set<MediaType> = [.video, .image, .gif]

    @AppStorage("VideoAspectMode") private var isAspectFill: Bool = true // Keep for video aspect
    @AppStorage("SeekDuration") private var storedSeekDuration: Double = 5.0
    @State private var seekDuration: Double = 5.0

    var body: some View {
        ZStack {
            if !filteredMediaFiles.isEmpty {
                GeometryReader { geometry in
                    MediaDisplayView(
                        mediaFile: filteredMediaFiles[currentMediaIndex],
                        player: players[activePlayerIndex],
                        offsetY: slideOffset,
                        isTopPlayer: true,
                        aspectFill: isAspectFill,
                        seekDuration: seekDuration
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .offset(y: slideOffset)

                    let preloadIndex = (currentMediaIndex + (slideOffset > 0 ? -1 : 1) + filteredMediaFiles.count) % filteredMediaFiles.count
                    if filteredMediaFiles.indices.contains(preloadIndex) {
                        MediaDisplayView(
                            mediaFile: filteredMediaFiles[preloadIndex],
                            player: players[(activePlayerIndex + 1) % 2],
                            offsetY: slideOffset > 0 ? -geometry.size.height : geometry.size.height,
                            isTopPlayer: false,
                            aspectFill: isAspectFill,
                            seekDuration: seekDuration
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .offset(y: slideOffset > 0 ? -geometry.size.height : geometry.size.height)
                    }
                }
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .background(Color.black.ignoresSafeArea())
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
                    Image(systemName: "photo.on.rectangle.angled")
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
                videoFiles: filteredMediaFiles,
                currentVideoIndex: currentMediaIndex,
                playRandomVideo: playRandomMedia,
                playRandomPrev: playRandomPrev,
                playRandomNext: playRandomNext,
                canGoPrev: randomHistoryIndex > 0,
                canGoNext: randomHistoryIndex >= 0 && randomHistoryIndex < randomHistory.count - 1,
                seekDuration: $seekDuration,
                selectedMediaTypes: $selectedMediaTypes,
                onMediaTypeChange: handleMediaTypeChange
            )

            if !filteredMediaFiles.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Text(filteredMediaFiles[currentMediaIndex].name)
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
            if !storedMediaTypes.isEmpty {
                let types = storedMediaTypes.split(separator: ",").compactMap { MediaType(rawValue: String($0)) }
                if !types.isEmpty {
                    selectedMediaTypes = Set(types)
                }
            }
            filteredMediaFiles = mediaFiles.filter { selectedMediaTypes.contains($0.type) }
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

            guard nextIndex >= 0, nextIndex < filteredMediaFiles.count else {
                withAnimation { slideOffset = 0 }
                isAnimating = false
                return
            }

            if filteredMediaFiles[currentMediaIndex].type == .video {
                players[activePlayerIndex]?.pause()
                players[activePlayerIndex] = nil
            }

            let nextMedia = filteredMediaFiles[nextIndex]
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

                if filteredMediaFiles[currentMediaIndex].type == .video {
                    let inactiveIndex = (activePlayerIndex + 1) % 2
                    activePlayerIndex = inactiveIndex
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
        guard !filteredMediaFiles.isEmpty else { return }
        cleanupCurrentAccess()
        if randomHistoryIndex < randomHistory.count - 1 {
            randomHistory = Array(randomHistory.prefix(randomHistoryIndex + 1))
        }
        if shuffledMediaFiles.isEmpty {
            shuffledMediaFiles = filteredMediaFiles.shuffled()
        }
        let nextMedia = shuffledMediaFiles.removeFirst()
        if let newIndex = filteredMediaFiles.firstIndex(of: nextMedia) {
            currentMediaIndex = newIndex
            randomHistory.append(newIndex)
            randomHistoryIndex = randomHistory.count - 1
        }
        players[activePlayerIndex]?.pause()
        if filteredMediaFiles[currentMediaIndex].type == .video {
            players[activePlayerIndex] = nil
        }
        if let url = nextMedia.getAccessibleURL() {
            currentAccessingURL = url
            if nextMedia.type == .video {
                let inactiveIndex = (activePlayerIndex + 1) % 2
                players[inactiveIndex] = AVPlayer(url: url)
                activePlayerIndex = inactiveIndex
                players[activePlayerIndex]?.play()
            }
        }
    }

    private func playRandomPrev() {
        guard randomHistoryIndex > 0 else { return }
        randomHistoryIndex -= 1
        let prevIndex = randomHistory[randomHistoryIndex]
        currentMediaIndex = prevIndex
        players[activePlayerIndex]?.pause()
        players[activePlayerIndex] = nil
        let media = filteredMediaFiles[prevIndex]
        if media.type == .video, let url = media.getAccessibleURL() {
            let inactiveIndex = (activePlayerIndex + 1) % 2
            players[inactiveIndex] = AVPlayer(url: url)
            activePlayerIndex = inactiveIndex
            players[activePlayerIndex]?.play()
        }
    }

    private func playRandomNext() {
        guard randomHistoryIndex >= 0 && randomHistoryIndex < randomHistory.count - 1 else { return }
        randomHistoryIndex += 1
        let nextIndex = randomHistory[randomHistoryIndex]
        currentMediaIndex = nextIndex
        players[activePlayerIndex]?.pause()
        players[activePlayerIndex] = nil
        let media = filteredMediaFiles[nextIndex]
        if media.type == .video, let url = media.getAccessibleURL() {
            let inactiveIndex = (activePlayerIndex + 1) % 2
            players[inactiveIndex] = AVPlayer(url: url)
            activePlayerIndex = inactiveIndex
            players[activePlayerIndex]?.play()
        }
    }

    private func preloadMedia() {
        cleanupCurrentAccess()
        activePlayerIndex = 0 // Reset active player to the first one
        players[1]?.pause()
        players[1] = nil
        guard !filteredMediaFiles.isEmpty else { return }
        let currentMedia = filteredMediaFiles[currentMediaIndex]
        if let url = currentMedia.getAccessibleURL() {
            currentAccessingURL = url
            if currentMedia.type == .video {
                players[0] = AVPlayer(url: url)
                players[0]?.play()
            }
        }
        // Reset random history on folder change
        randomHistory = []
        randomHistoryIndex = -1
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
                    if mediaFile.type != .unknown {
                        found.append(mediaFile)
                    }
                }
            }
            print("Found content in the folder :", found)
            found.shuffle()
            DispatchQueue.main.async {
                mediaFiles = found
                filteredMediaFiles = found.filter { selectedMediaTypes.contains($0.type) }
                currentMediaIndex = 0
                shuffledMediaFiles = filteredMediaFiles.shuffled()
                preloadMedia()
            }
        } catch {
            print("Failed to load saved folder contents: \(error)")
        }
    }

    private func handleMediaTypeChange(_ newTypes: Set<MediaType>) {
        guard !newTypes.isEmpty else { return }
        selectedMediaTypes = newTypes
        storedMediaTypes = newTypes.map { $0.rawValue }.joined(separator: ",")
        filteredMediaFiles = mediaFiles.filter { newTypes.contains($0.type) }
        // Kill all video players if videos are removed from filter
        if !newTypes.contains(.video) {
            for i in players.indices {
                players[i]?.pause()
                players[i] = nil
            }
        }
        currentMediaIndex = 0
        randomHistory = []
        randomHistoryIndex = -1
        shuffledMediaFiles = filteredMediaFiles.shuffled()
    }
}
