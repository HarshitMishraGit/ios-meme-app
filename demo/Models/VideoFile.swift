//
//  VideoFile.swift
//  demo
//
//  Created by Harshit Mishra on 20/06/25.
//

import Foundation

struct VideoFile: Equatable {
    let url: URL
    let bookmark: Data?
    let name: String
    
    static func == (lhs: VideoFile, rhs: VideoFile) -> Bool {
        return lhs.url == rhs.url && lhs.name == rhs.name
    }
    
    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
        do {
            self.bookmark = try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
        } catch {
            print("Failed to create bookmark for \(url.lastPathComponent): \(error)")
            self.bookmark = nil
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

