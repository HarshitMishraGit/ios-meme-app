import SwiftUI
import AVKit

struct ContentView: View {
    @State private var isPickerPresented = false
    @State private var videoFiles: [VideoFile] = []
    @State private var currentVideoIndex = 0
    @State private var showMenu = false
    @State private var currentAccessingURL: URL?
    @State private var slideOffset: CGFloat = 0
    @State private var isAnimating = false
    @State private var activePlayerIndex = 0
    @State private var players: [AVPlayer?] = [nil, nil]

    var body: some View {
        ZStack {
            if !videoFiles.isEmpty {
                // Render both players for animation
                ZStack {
                    ForEach(0..<2, id: \.self) { index in
                        SlidingVideoPlayer(
                            player: players[index],
                            offsetY: activePlayerIndex == index ? slideOffset : (slideOffset > 0 ? -UIScreen.main.bounds.height : UIScreen.main.bounds.height),
                            isTopPlayer: activePlayerIndex == index
                        )
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

            FloatingMenu(
                showMenu: $showMenu,
                isPickerPresented: $isPickerPresented,
                videoFiles: videoFiles,
                currentVideoIndex: currentVideoIndex,
                playRandomVideo: playRandomVideo
            )

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
        .sheet(isPresented: $isPickerPresented) {
            FolderPicker(videoFiles: $videoFiles, currentIndex: $currentVideoIndex)
        }
        .onChange(of: videoFiles) { _, new in
            if !new.isEmpty {
                currentVideoIndex = 0
                preloadPlayers()
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
            let nextIndex = currentVideoIndex + direction

            guard nextIndex >= 0, nextIndex < videoFiles.count else {
                withAnimation { slideOffset = 0 }
                isAnimating = false
                return
            }

            let inactiveIndex = (activePlayerIndex + 1) % 2
            let nextVideo = videoFiles[nextIndex]
            if let url = nextVideo.getAccessibleURL() {
                players[inactiveIndex] = AVPlayer(url: url)
            }

            withAnimation(.easeInOut(duration: 0.3)) {
                slideOffset = CGFloat(direction) * -UIScreen.main.bounds.height
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                // Pause and clear the old player
                players[activePlayerIndex]?.pause()
                players[activePlayerIndex] = nil

                // Switch to new player
                activePlayerIndex = inactiveIndex
                currentVideoIndex = nextIndex
                slideOffset = 0

                // Start new player
                players[activePlayerIndex]?.play()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isAnimating = false
                }
            }

        } else {
            withAnimation(.easeOut(duration: 0.2)) {
                slideOffset = 0
            }
        }
    }

    private func playRandomVideo() {
        guard !videoFiles.isEmpty else { return }
        let randomIndex = Int.random(in: 0..<videoFiles.count)
        if randomIndex != currentVideoIndex {
            currentVideoIndex = randomIndex
            preloadPlayers()
        }
    }

    private func preloadPlayers() {
        cleanupCurrentAccess()
        activePlayerIndex = 0
        
        players[1]?.pause()
        players[1] = nil
        
        if let url = videoFiles[currentVideoIndex].getAccessibleURL() {
            currentAccessingURL = url
            players[0] = AVPlayer(url: url)
            players[0]?.play()
            players[1] = nil // reset other buffer
        }
    }

    private func cleanupCurrentAccess() {
        if let url = currentAccessingURL {
            url.stopAccessingSecurityScopedResource()
            currentAccessingURL = nil
        }
    }
}

