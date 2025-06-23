//
//  MediaImageView.swift
//  demo
//
//  Created by Harshit Mishra on 23/06/25.
//

import SwiftUI

struct MediaImageView: View {
    let url: URL
    let slideOffset: CGFloat // To participate in the swipe animation

    var body: some View {
        if let uiImage = loadImage(from: url) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit() // Or .scaledToFill() depending on desired behavior
                .ignoresSafeArea()
        } else {
            Color.black
                .overlay(Text("Failed to load image").foregroundColor(.red))
                .ignoresSafeArea()
        }
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
