//
//  FloatingMenu.swift
//  demo
//
//  Created by Harshit Mishra on 20/06/25.
//


import SwiftUI

struct FloatingMenu: View {
    @Binding var showMenu: Bool
    @Binding var isPickerPresented: Bool
    let videoFiles: [VideoFile]
    let currentVideoIndex: Int
    let playRandomVideo: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                VStack(spacing: 12) {
                    // Menu toggle button
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
                            // Folder picker button
                            Button(action: {
                                isPickerPresented = true
                                withAnimation {
                                    showMenu = false
                                }
                            }) {
                                VStack {
                                    Image(systemName: "folder")
                                        .font(.title3)
                                    Text("Folder")
                                        .font(.caption)
                                }
                                .foregroundColor(.white)
                                .frame(width: 60, height: 50)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(12)
                            }
                            
                            // Video counter
                            if !videoFiles.isEmpty {
                                Text("\(currentVideoIndex + 1)/\(videoFiles.count)")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(8)
                            }
                            
                            // Shuffle/random play
                            Button(action: playRandomVideo) {
                                VStack {
                                    Image(systemName: "shuffle")
                                        .font(.title3)
                                    Text("Random")
                                        .font(.caption)
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
                .padding(.trailing, 20)
            }
            .padding(.top, 20)
            
            Spacer()
        }
    }
}
