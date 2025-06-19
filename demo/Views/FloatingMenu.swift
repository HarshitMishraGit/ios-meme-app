//
//  FloatingMenu.swift
//  demo
//
//  Created by Harshit Mishra on 20/06/25.
//

enum MenuCorner: String, CaseIterable {
    case topLeading, topTrailing, bottomLeading, bottomTrailing
    
    var alignment: Alignment {
        switch self {
        case .topLeading: return .topLeading
        case .topTrailing: return .topTrailing
        case .bottomLeading: return .bottomLeading
        case .bottomTrailing: return .bottomTrailing
        }
    }
}

import SwiftUI

struct FloatingMenu: View {
    @Binding var showMenu: Bool
    @Binding var isPickerPresented: Bool
    let videoFiles: [VideoFile]
    let currentVideoIndex: Int
    let playRandomVideo: () -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var corner: MenuCorner = Self.loadCorner()

    private static let userDefaultsKey = "FloatingMenuCorner"

    var body: some View {
        GeometryReader { geometry in
            VStack {
                if corner.alignment.vertical == .bottom { Spacer() }
                
                HStack {
                    if corner.alignment.horizontal == .trailing { Spacer() }

                    menuContent
                        .offset(dragOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    dragOffset = value.translation
                                }
                                .onEnded { _ in
                                    snapToNearestCorner(in: geometry.size)
                                }
                        )

                    if corner.alignment.horizontal == .leading { Spacer() }
                }

                if corner.alignment.vertical == .top { Spacer() }
            }
            .padding(20)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    private var menuContent: some View {
        VStack(spacing: 12) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showMenu.toggle()
                }
            }) {
                Image(systemName: showMenu ? "xmark" : "ellipsis")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }

            if showMenu {
                VStack(spacing: 8) {
                    Button(action: {
                        isPickerPresented = true
                        withAnimation { showMenu = false }
                    }) {
                        VStack {
                            Image(systemName: "folder").font(.title3)
                            Text("Folder").font(.caption)
                        }
                        .foregroundColor(.white)
                        .frame(width: 60, height: 50)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(12)
                    }

                    if !videoFiles.isEmpty {
                        Text("\(currentVideoIndex + 1)/\(videoFiles.count)")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                    }

                    Button(action: playRandomVideo) {
                        VStack {
                            Image(systemName: "shuffle").font(.title3)
                            Text("Random").font(.caption)
                        }
                        .foregroundColor(.white)
                        .frame(width: 60, height: 50)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(12)
                    }
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
    }

    private func snapToNearestCorner(in size: CGSize) {
        let x = dragOffset.width
        let y = dragOffset.height

        let newCorner: MenuCorner
        if y < 0 {
            newCorner = x < 0 ? .topLeading : .topTrailing
        } else {
            newCorner = x < 0 ? .bottomLeading : .bottomTrailing
        }

        corner = newCorner
        dragOffset = .zero

        saveCorner(newCorner)
    }

    private static func loadCorner() -> MenuCorner {
        if let raw = UserDefaults.standard.string(forKey: userDefaultsKey),
           let saved = MenuCorner(rawValue: raw) {
            return saved
        }
        return .topTrailing
    }

    private func saveCorner(_ corner: MenuCorner) {
        UserDefaults.standard.set(corner.rawValue, forKey: Self.userDefaultsKey)
    }
}
