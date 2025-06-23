//
//  MediaImageView.swift
//  demo
//
//  Created by Harshit Mishra on 23/06/25.
//

import SwiftUI

struct MediaImageView: View {
    let url: URL
    let aspectFill : Bool // To participate in the swipe animation

    var body: some View {
        GeometryReader { geometry in
            if let uiImage = loadImage(from: url) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: aspectFill ? .fill : .fit)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            } else {
                Color.black
                    .overlay(Text("Failed to load image").foregroundColor(.red))
            }
        }
        .ignoresSafeArea()
    }

    private func loadImage(from url: URL) -> UIImage? {
        // Ensure access to security-scoped resources if needed
        let started = url.startAccessingSecurityScopedResource()
        defer { if started { url.stopAccessingSecurityScopedResource() } }

        guard let data = try? Data(contentsOf: url) else {
            print("Could not load data from URL: \(url)")
            return nil
        }
        return UIImage(data: data)
    }
}
