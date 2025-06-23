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
        GeometryReader { geometry in
            KFAnimatedImage(source:Source.provider(LocalFileImageDataProvider(fileURL: url)))
                .placeholder {
                    ProgressView() // Show a progress indicator while loading
                }
                .aspectRatio(contentMode: aspectFill ? .fill : .fit)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        }
        .ignoresSafeArea()
    }
}
