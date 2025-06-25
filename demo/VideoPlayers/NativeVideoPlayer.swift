import SwiftUI
import AVKit

struct NativeVideoPlayer: View {
    let player: AVPlayer?
    let aspectFill: Bool

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
        .ignoresSafeArea()
    }
}
