//
//  SlidingVideoPlayer.swift
//  demo
//
//  Created by Harshit Mishra on 20/06/25.
//
import SwiftUI
import AVKit

class PlayerContainerView: UIView {
    let playerLayer = AVPlayerLayer()

    init(player: AVPlayer, aspectFill: Bool) {
        super.init(frame: .zero)
        self.playerLayer.player = player
        self.playerLayer.videoGravity = aspectFill ? .resizeAspectFill : .resizeAspect
        self.layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

struct CustomVideoPlayer: UIViewRepresentable {
    let player: AVPlayer
    let aspectFill: Bool

    func makeUIView(context: Context) -> PlayerContainerView {
        return PlayerContainerView(player: player, aspectFill: aspectFill)
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        uiView.playerLayer.player = player
        uiView.playerLayer.videoGravity = aspectFill ? .resizeAspectFill : .resizeAspect
        uiView.setNeedsLayout()
    }
}

struct SlidingVideoPlayer: View {
    let player: AVPlayer?
    let offsetY: CGFloat
    let isTopPlayer: Bool
    let aspectFill: Bool
    let seekDuration: Double

    @State private var isPlaying: Bool = true
    
    @State private var lastDoubleTapLocation: CGPoint = .zero

    var body: some View {
        Group {
            if let player = player {
                ZStack {
                    CustomVideoPlayer(player: player, aspectFill: aspectFill)
                }
                .scaleEffect(1.01)
                .offset(y: offsetY)
                .zIndex(isTopPlayer ? 1 : 0)
                .clipped()
            } else {
                Color.black
            }
        }
        // Applying the gesture to the top-level ZStack for better recognition
        // and using a more explicit gesture composition.
        .gesture(
            TapGesture(count: 2)
                .onEnded {
                }
                .exclusively(before: TapGesture(count: 1).onEnded {
                    // Single tap detected.
                    togglePlayPause()
                })
        
        )
        .overlay(
            GeometryReader { geometry in
                Color.clear
                    .contentShape(Rectangle())
                    .simultaneousGesture(
                        // This DragGesture will always capture the location of any touch.
                        // We will then use a TapGesture to confirm if it was a single or double tap.
                        DragGesture(minimumDistance: 0, coordinateSpace: .local)
                            .onEnded { value in
                                // Store the last tap location.
                                // This will be used by the double tap handler.
                                lastDoubleTapLocation = value.location
                            }
                    )
                    .highPriorityGesture( // Use highPriorityGesture for the double tap
                        TapGesture(count: 2)
                            .onEnded {
                                // Double tap detected. `lastDoubleTapLocation` should be set.
                                handleDoubleTap(in: geometry.size)
                            }
                    )
                    .onTapGesture(count: 1) { // Use .onTapGesture modifier for single tap
                        // This fires after higher priority gestures are considered.
                        // If a double tap occurs, this won't fire.
                        togglePlayPause()
                    }
            }
        )
    }

    private func togglePlayPause() {
        guard let player = player else { return }
        if player.timeControlStatus == .playing {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }
    
    private func handleDoubleTap(in size: CGSize) {
        // Use last tap location or center as fallback
        let isRightSide = lastDoubleTapLocation.x > (size.width / 2)
        print("isRightSide: \(isRightSide), size: \(size), lastDoubleTapLocation: \(lastDoubleTapLocation)")
        seek(seconds: isRightSide ? seekDuration : -seekDuration)
    }

    private func seek(seconds: Double) {
        guard let player = player,
              let item = player.currentItem else { return }

        let currentTime = player.currentTime()
        let delta = CMTime(seconds: seconds, preferredTimescale: currentTime.timescale)
        var newTime = currentTime + delta

        // Clamp to valid range
        let zero = CMTime.zero
        let duration = item.duration.isIndefinite ? CMTime(seconds: 600, preferredTimescale: currentTime.timescale) : item.duration
        if newTime < zero {
            newTime = zero
        } else if newTime > duration {
            newTime = duration - CMTime(seconds: 0.1, preferredTimescale: currentTime.timescale) // Slightly less than duration
        }

        player.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero) { finished in
            print(">>> seek completed \(finished), time: \(CMTimeGetSeconds(newTime))")
//            player.play()
        }
    }

}
