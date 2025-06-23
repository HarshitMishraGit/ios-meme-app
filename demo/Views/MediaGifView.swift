//
//  MediaGifView.swift
//  demo
//
//  Created by Harshit Mishra on 23/06/25.
//

import SwiftUI
import Kingfisher

struct MediaGifView: View {
    let url: URL
    let aspectFill: Bool

    var body: some View {
        // --- CHANGE HERE: Use Kingfisher's Source for local files ---
        KFAnimatedImage(source:Source.provider(LocalFileImageDataProvider(fileURL: url)))
            .placeholder {
                ProgressView() // Show a progress indicator while loading
            }
            // .loadDiskFileSynchronously() // This is often not needed with LocalFileImageDataProvider, as it's designed for local access
            .aspectRatio(contentMode: aspectFill ? .fill : .fit) // Apply scaling mode
            .ignoresSafeArea() // Let it take up the full screen
    }
}
