//
//  FolderPicker.swift
//  demo
//
//  Created by Harshit Mishra on 20/06/25.
//

import SwiftUI
import UniformTypeIdentifiers // For UTType

struct FolderPicker: UIViewControllerRepresentable {
    @Binding var mediaFiles: [MediaFile] // Changed to mediaFiles
    @Binding var currentIndex: Int // Changed to currentIndex

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let supportedTypes: [UTType] = [
            .movie, // Covers .mp4, .mov, etc.
            .image, // Covers .png, .jpeg, .heic
            UTType("com.compuserve.gif")! // Specific for GIF, as .image might not cover it explicitly for picker
        ]

        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: false)
        picker.allowsMultipleSelection = false // Keep it to single folder selection
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: FolderPicker

        init(parent: FolderPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let folderURL = urls.first else { return }

            // Persist the security-scoped bookmark
            do {
                let bookmarkData = try folderURL.bookmarkData(includingResourceValuesForKeys: nil, relativeTo: nil)
                UserDefaults.standard.set(bookmarkData, forKey: "SavedFolderBookmark")
            } catch {
                print("Error saving bookmark data: \(error)")
            }

            // Start accessing the security-scoped resource
            _ = folderURL.startAccessingSecurityScopedResource()
            
            loadMedia(from: folderURL) // Renamed for clarity
        }

        private func loadMedia(from folderURL: URL) {
            do {
                let contents = try FileManager.default.contentsOfDirectory(
                    at: folderURL,
                    includingPropertiesForKeys: [.isRegularFileKey],
                    options: [.skipsHiddenFiles]
                )

                var found: [MediaFile] = []
                for url in contents {
                    let values = try url.resourceValues(forKeys: [.isRegularFileKey])
                    if values.isRegularFile == true {
                        let mediaFile = MediaFile(url: url)
                        if mediaFile.type != .unknown {
                            found.append(mediaFile)
                        }
                    }
                }

                DispatchQueue.main.async {
                    self.parent.mediaFiles = found
                    self.parent.currentIndex = 0
                }
            } catch {
                print("Failed to load folder contents: \(error)")
            }
        }
    }
}

