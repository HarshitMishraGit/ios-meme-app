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
   
    
    @State private var isPlaying: Bool = true
    
    var body: some View {
        Group {
            if let player = player {
                ZStack {
                    // Video layer with custom scaling
                    CustomVideoPlayer(player: player, aspectFill: aspectFill)
                        .onTapGesture {
                                                    togglePlayPause()
                                                }
                }
                .scaleEffect(1.01) // Optional zoom to avoid video border flashes
                .offset(y: offsetY)
                .zIndex(isTopPlayer ? 1 : 0)
                .clipped()
            } else {
                Color.black
            }
        }
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
}
