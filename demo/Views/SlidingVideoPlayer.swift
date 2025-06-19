//
//  SlidingVideoPlayer.swift
//  demo
//
//  Created by Harshit Mishra on 20/06/25.
//

import SwiftUI
import AVKit

struct SlidingVideoPlayer: View {
    let player: AVPlayer?
    let offsetY: CGFloat
    let isTopPlayer: Bool

    var body: some View {
        Group {
            if let player = player {
                VideoPlayer(player: player)
                    .scaleEffect(1.01) // Optional zoom to avoid video border flashes
                    .offset(y: offsetY)
                    .zIndex(isTopPlayer ? 1 : 0)
                    .clipped()
            } else {
                Color.black
            }
        }
    }
}
