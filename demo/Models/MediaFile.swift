//
//  MediaFile.swift
//  demo
//
//  Created by Harshit Mishra on 23/06/25.
//

import SwiftUI
import AVKit
import UniformTypeIdentifiers // Import for UTType to help with file types

enum MediaType: String, Codable {
    case video
    case image
    case gif
    case unknown // For any unsupported types, good for error handling
}

let videoExtensions = ["mp4", "mov", "avi", "mkv", "m4v", "wmv", "flv", "webm", "mpg", "mpeg", "3gp"]
let imageExtensions = ["png", "jpg", "jpeg", "heic"] // Added HEIC
let gifExtensions = ["gif"]

struct MediaFile: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let name: String
    let type: MediaType
    let bookmark: Data?

    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
        self.type = MediaFile.determineMediaType(from: url.pathExtension)
        do {
            self.bookmark = try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
        } catch {
            print("Failed to create bookmark for \(url.lastPathComponent): \(error)")
            self.bookmark = nil
        }
    }

    // Helper to determine media type based on extension
    private static func determineMediaType(from extensionString: String) -> MediaType {
        let lowercasedExtension = extensionString.lowercased()

        if videoExtensions.contains(lowercasedExtension) {
            return .video
        } else if imageExtensions.contains(lowercasedExtension) {
            return .image
        } else if gifExtensions.contains(lowercasedExtension) {
            return .gif
        } else {
            return .unknown
        }
    }

    func getAccessibleURL() -> URL? {
        guard let bookmark = bookmark else {
            return url
        }
        do {
            var isStale = false
            let resolvedURL = try URL(resolvingBookmarkData: bookmark, options: .withoutUI, relativeTo: nil, bookmarkDataIsStale: &isStale)
            guard resolvedURL.startAccessingSecurityScopedResource() else {
                return url
            }
            return resolvedURL
        } catch {
            return url
        }
    }
}
