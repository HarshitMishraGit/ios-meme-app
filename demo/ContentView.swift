import SwiftUI
import AVKit

struct ContentView: View {
    @State private var isPickerPresented = false
    @State private var videoFiles: [VideoFile] = []
    @State private var currentVideoIndex = 0
    @State private var showMenu = false
    @State private var player: AVPlayer?
    @State private var currentAccessingURL: URL?
    @State private var slideOffset: CGFloat = 0
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            if !videoFiles.isEmpty {
                FullScreenVideoPlayer(
                    videoFiles: videoFiles,
                    currentIndex: $currentVideoIndex,
                    player: $player,
                    currentAccessingURL: $currentAccessingURL
                )
                .ignoresSafeArea()
                .offset(y: slideOffset)
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
                playCurrentVideo()
            }
        }
        .onChange(of: currentVideoIndex) { _, _ in
            playCurrentVideo()
        }
        .onDisappear {
            cleanupCurrentAccess()
        }
    }

    private func handleSwipe(value: DragGesture.Value) {
        if abs(value.translation.height) > 50 && !isAnimating {
            isAnimating = true
            let direction = value.translation.height < 0 ? -1.0 : 1.0

            withAnimation(.easeInOut(duration: 0.3)) {
                slideOffset = direction * UIScreen.main.bounds.height
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if direction < 0 {
                    nextVideo()
                } else {
                    previousVideo()
                }

                withAnimation(.easeInOut(duration: 0.3)) {
                    slideOffset = 0
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isAnimating = false
                }
            }
        } else {
            withAnimation(.easeOut(duration: 0.2)) {
                slideOffset = 0
            }
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

    private func playRandomVideo() {
        guard !videoFiles.isEmpty else { return }
        currentVideoIndex = Int.random(in: 0..<videoFiles.count)
    }

    private func cleanupCurrentAccess() {
        if let url = currentAccessingURL {
            url.stopAccessingSecurityScopedResource()
            currentAccessingURL = nil
        }
    }

    private func playCurrentVideo() {
        guard !videoFiles.isEmpty else { return }
        player?.pause()
        player = nil
        cleanupCurrentAccess()
        let videoFile = videoFiles[currentVideoIndex]
        guard let url = videoFile.getAccessibleURL() else { return }
        currentAccessingURL = url
        player = AVPlayer(url: url)
        player?.play()
    }
}

