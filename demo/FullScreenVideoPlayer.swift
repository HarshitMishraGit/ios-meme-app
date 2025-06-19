//
//  VideoPlayer.swift
//  demo
//
//  Created by Harshit Mishra on 20/06/25.
//

import SwiftUI
import AVKit

struct FullScreenVideoPlayer: View {
    let videoFiles: [VideoFile]
    @Binding var currentIndex: Int
    @Binding var player: AVPlayer?
    @Binding var currentAccessingURL: URL?
    
    var body: some View {
        Group {
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
}


