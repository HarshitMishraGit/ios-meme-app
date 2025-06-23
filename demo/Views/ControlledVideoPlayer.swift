import SwiftUI
import AVKit

struct ControlledVideoPlayer: View {
    let player: AVPlayer?
    let offsetY: CGFloat
    let isTopPlayer: Bool
    let aspectFill: Bool
    let seekDuration: Double

    var body: some View {
        Group {
            if let player = player {
                AVPlayerControllerRepresentable(player: player, aspectFill: aspectFill)
                    .offset(y: offsetY)
                    .zIndex(isTopPlayer ? 1 : 0)
                    .clipped()
            } else {
                Color.black
            }
        }
    }
}

struct AVPlayerControllerRepresentable: UIViewControllerRepresentable {
    let player: AVPlayer
    let aspectFill: Bool

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        controller.videoGravity = aspectFill ? .resizeAspectFill : .resizeAspect
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
        uiViewController.videoGravity = aspectFill ? .resizeAspectFill : .resizeAspect
    }
} 