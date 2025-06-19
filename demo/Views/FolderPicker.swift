//
//  FolderPicker.swift
//  demo
//
//  Created by Harshit Mishra on 20/06/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct FolderPicker: UIViewControllerRepresentable {
    @Binding var videoFiles: [VideoFile]
    @Binding var currentIndex: Int
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.folder], asCopy: false)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: FolderPicker

        init(_ parent: FolderPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let folderURL = urls.first else { return }
            guard folderURL.startAccessingSecurityScopedResource() else { return }

            defer { folderURL.stopAccessingSecurityScopedResource() }

            let extensions = ["mp4", "mov", "avi", "mkv", "m4v", "wmv", "flv", "webm", "mpg", "mpeg", "3gp"]
            var foundVideos: [VideoFile] = []

            do {
                let contents = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: [.isRegularFileKey], options: .skipsHiddenFiles)
                for url in contents {
                    let values = try url.resourceValues(forKeys: [.isRegularFileKey])
                    if values.isRegularFile == true, extensions.contains(url.pathExtension.lowercased()) {
                        foundVideos.append(VideoFile(url: url))
                    }
                }

                foundVideos.sort { $0.name < $1.name }

                DispatchQueue.main.async {
                    self.parent.videoFiles = foundVideos
                    self.parent.currentIndex = 0
                    self.parent.dismiss()
                }
                
                if let bookmark = try? folderURL.bookmarkData(
                    options: .withoutImplicitSecurityScope,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                ) {
                    UserDefaults.standard.set(bookmark, forKey: "SavedFolderBookmark")
                }

            } catch {
                print("Error loading videos: \(error)")
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}

