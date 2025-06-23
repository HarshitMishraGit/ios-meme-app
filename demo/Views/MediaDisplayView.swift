//
//  MediaDisplayView.swift
//  demo
//
//  Created by Harshit Mishra on 20/06/25.
//

import SwiftUI
import AVKit

struct MediaDisplayView: View {
    let mediaFile: MediaFile
    let player: AVPlayer? // Only relevant for video type
    let offsetY: CGFloat
    let isTopPlayer: Bool
    let aspectFill: Bool
    let seekDuration: Double
    
    init(mediaFile: MediaFile, player: AVPlayer?, offsetY: CGFloat, isTopPlayer: Bool, aspectFill: Bool, seekDuration: Double) {
        self.mediaFile = mediaFile
        self.player = player
        self.offsetY = offsetY
        self.isTopPlayer = isTopPlayer
        self.aspectFill = aspectFill
        self.seekDuration = seekDuration
        
        
//        print("MediaDisplayView showing \(mediaFile.name)")
    }

    var body: some View {
        Group {
            switch mediaFile.type {
            case .video:
                SlidingVideoPlayer(
                    player: player,
                    offsetY: offsetY,
                    isTopPlayer: isTopPlayer,
                    aspectFill: aspectFill,
                    seekDuration: seekDuration
                )
            case .image:
                MediaImageView(url: mediaFile.url, aspectFill:aspectFill)
            case .gif:
                // Assuming you're still using MediaImageView for GIFs,
                // or you'd use MediaGifView if you implemented it.
                MediaGifView(url: mediaFile.url, aspectFill: aspectFill)
                
            case .unknown:
                Color.red.opacity(0.5)
                    .overlay(Text("Unsupported Media Type").foregroundColor(.white))
            }
        }
    }
}
