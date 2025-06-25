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
import UIKit

struct FloatingMenu: View {
    @Binding var showMenu: Bool
    @Binding var isPickerPresented: Bool
    let videoFiles: [MediaFile]
    let currentVideoIndex: Int
    let playRandomVideo: () -> Void
    let playRandomPrev: () -> Void
    let playRandomNext: () -> Void
    let canGoPrev: Bool
    let canGoNext: Bool
    @Binding var seekDuration: Double
    @Binding var selectedMediaTypes: Set<MediaType>
    let onMediaTypeChange: (Set<MediaType>) -> Void
    @Binding var playerType: VideoPlayerType
    let isVideoPlaying: Bool

    @State private var dragOffset: CGSize = .zero
    @State private var corner: MenuCorner = Self.loadCorner()

    private static let userDefaultsKey = "FloatingMenuCorner"
    @AppStorage("VideoAspectMode") private var isAspectFill: Bool = true
    @AppStorage("SeekDuration") private var storedSeekDuration: Double = 5.0
    @State private var showSeekOptions: Bool = false
    @State private var showMediaTypeOptions: Bool = false

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
                    .background(Color.black.opacity(0.7))
                    .clipShape(Circle())
            }

            if showMenu {
                VStack(spacing: 10) {
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

                       // Only show Player Type and Seek if video is playing
                    if isVideoPlaying {
                        // Player Type Toggle
                        Button(action: {
                            playerType = (playerType == .native) ? .sliding : .native
                        }) {
                            VStack {
                                Image(systemName: "film")
                                    .font(.title3)
                                    .foregroundColor(playerType == .native ? .blue : .white)
                                Text("Native")
                                    .font(.caption)
                                    .foregroundColor(playerType == .native ? .blue : .white)
                            }
                            .frame(width: 60, height: 50)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(12)
                        }

                        // Seek Duration Button + Slider
                        HStack(alignment: .center, spacing: 8) {
                            Button(action: { withAnimation { showSeekOptions.toggle() } }) {
                                VStack {
                                    Image(systemName: "clock")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                        .frame(width: 36, height: 36)
                                        .background(Color.black.opacity(0.7))
                                        .clipShape(Circle())
                                    Text("Seek")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                }
                            }
                            if showSeekOptions {
                                SeekSlider(seekDuration: $seekDuration, storedSeekDuration: $storedSeekDuration)
                                    .transition(.move(edge: .trailing).combined(with: .opacity))
                            }
                        }
                    }

                    // Media Type Filter Button + Toggles
                    HStack(alignment: .center, spacing: 8) {
                        Button(action: { withAnimation { showMediaTypeOptions.toggle() } }) {
                            VStack {
                                Image(systemName: "rectangle.stack")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Color.black.opacity(0.7))
                                    .clipShape(Circle())
                                Text("Type")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            }
                        }
                        if showMediaTypeOptions {
                            MediaTypeToggles(selectedTypes: $selectedMediaTypes, onChange: onMediaTypeChange)
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                    
                    
                    // Random + History Controls
                    RandomHistoryButton(
                        playRandom: playRandomVideo,
                        playPrev: playRandomPrev,
                        playNext: playRandomNext,
                        canGoPrev: canGoPrev,
                        canGoNext: canGoNext
                    )

                    Button(action: {
                        isAspectFill.toggle()
                    }) {
                        VStack {
                            Image(systemName: isAspectFill ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")
                                .font(.title3)
                            Text(isAspectFill ? "Fill" : "Fit")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .frame(width: 60, height: 50)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(12)
                    }
                }
                .padding(12)
                .background(BlurView(style: .systemUltraThinMaterialDark).clipShape(RoundedRectangle(cornerRadius: 24)))
                .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .onAppear {
            seekDuration = storedSeekDuration
        }
        .onChange(of: seekDuration) { _, newValue in
            storedSeekDuration = newValue
        }
        // Hide slider if tap outside
        .background(
            Color.clear.contentShape(Rectangle()).onTapGesture {
                if showSeekOptions { withAnimation { showSeekOptions = false } }
            }
        )
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

struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// Add SeekSlider view
struct SeekSlider: View {
    @Binding var seekDuration: Double
    @Binding var storedSeekDuration: Double
    @State private var sliderValue: Double = 5.0
    @State private var showTooltip: Bool = false

    let minValue: Double = 5
    let maxValue: Double = 30
    let step: Double = 5

    var body: some View {
        ZStack(alignment: .top) {
            HStack(spacing: 0) {
                Slider(value: Binding(
                    get: { sliderValue },
                    set: { newValue in
                        // Snap to nearest 5
                        let snapped = (round((newValue - minValue) / step) * step) + minValue
                        sliderValue = min(max(snapped, minValue), maxValue)
                        seekDuration = sliderValue
                        storedSeekDuration = sliderValue
                        showTooltip = true
                    }),
                    in: minValue...maxValue
                )
                .frame(width: 120)
                .accentColor(.white)
                .onAppear { sliderValue = seekDuration }
                .onChange(of: seekDuration) { _, new in sliderValue = new }
            }
            // Tooltip above thumb
            if showTooltip {
                Text("\(Int(sliderValue))s")
                    .font(.caption2)
                    .padding(6)
                    .background(Color.black.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .offset(y: -32)
                    .transition(.opacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            withAnimation { showTooltip = false }
                        }
                    }
            }
        }
        .frame(width: 130)
        .padding(.trailing, 4)
        .overlay(
            // Gaps at each 5s
            GeometryReader { geo in
                let sliderWidth = geo.size.width - 16 // padding
                HStack(spacing: 0) {
                    ForEach(Array(stride(from: minValue, through: maxValue, by: step)), id: \ .self) { value in
                        Rectangle()
                            .fill(Color.white.opacity(0.5))
                            .frame(width: 2, height: 10)
                            .offset(x: CGFloat((value - minValue) / (maxValue - minValue)) * sliderWidth - 1, y: 18)
                    }
                }
            }
        )
    }
}

struct RandomHistoryButton: View {
    let playRandom: () -> Void
    let playPrev: () -> Void
    let playNext: () -> Void
    let canGoPrev: Bool
    let canGoNext: Bool
    @State private var dragOffset: CGFloat = 0
    @State private var showIcon: String? = nil
    @State private var showRed: Bool = false
    @State private var isActionInProgress: Bool = false
    let maxOffset: CGFloat = 20
    var body: some View {
        ZStack {
            VStack {
                Image(systemName: showIcon ?? "shuffle")
                    .font(.title3)
                    .foregroundColor(showRed ? .red : .white)
                    .frame(width: 60, height: 50)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(12)
                Text("Random").font(.caption).foregroundColor(.white)
            }
            .offset(x: dragOffset)
            .gesture(
                DragGesture(minimumDistance: 10, coordinateSpace: .local)
                    .onChanged { value in
                        guard !isActionInProgress else { return }
                        let clamped = min(max(value.translation.width, -maxOffset), maxOffset)
                        dragOffset = clamped
                        if clamped > 15 {
                            showIcon = canGoPrev ? "chevron.left" : "xmark"
                            showRed = !canGoPrev
                        } else if clamped < -15 {
                            showIcon = canGoNext ? "chevron.right" : "xmark"
                            showRed = !canGoNext
                        } else {
                            showIcon = nil
                            showRed = false
                        }
                    }
                    .onEnded { value in
                        guard !isActionInProgress else { return }
                        isActionInProgress = true
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if dragOffset > 15 {
                                if canGoPrev { playPrev() }
                            } else if dragOffset < -15 {
                                if canGoNext { playNext() }
                            } else {
                                playRandom()
                            }
                            dragOffset = 0
                            showIcon = nil
                            showRed = false
                        }
                        // Allow new drags after a short delay to let parent update state
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            isActionInProgress = false
                        }
                    }
            )
            .onTapGesture {
                guard !isActionInProgress else { return }
                isActionInProgress = true
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    playRandom()
                    dragOffset = 0
                    showIcon = nil
                    showRed = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isActionInProgress = false
                }
            }
            .animation(.easeInOut(duration: 0.2), value: dragOffset)
        }
    }
}

struct MediaTypeToggles: View {
    @Binding var selectedTypes: Set<MediaType>
    let onChange: (Set<MediaType>) -> Void
    var body: some View {
        HStack(spacing: 10) {
            ToggleIcon(
                icon: "film",
                label: "Video",
                isOn: selectedTypes.contains(.video),
                onTap: { toggle(.video) }
            )
            ToggleIcon(
                icon: "photo",
                label: "Image",
                isOn: selectedTypes.contains(.image),
                onTap: { toggle(.image) }
            )
            ToggleIcon(
                icon: "sparkles.tv",
                label: "GIF",
                isOn: selectedTypes.contains(.gif),
                onTap: { toggle(.gif) }
            )
        }
    }
    private func toggle(_ type: MediaType) {
        var newSet = selectedTypes
        if newSet.contains(type) {
            if newSet.count > 1 {
                newSet.remove(type)
            }
        } else {
            newSet.insert(type)
        }
        onChange(newSet)
    }
}

struct ToggleIcon: View {
    let icon: String
    let label: String
    let isOn: Bool
    let onTap: () -> Void
    var body: some View {
        VStack {
            Button(action: onTap) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isOn ? .blue : .gray)
                    .frame(width: 36, height: 36)
                    .background(isOn ? Color.white.opacity(0.8) : Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(isOn ? .blue : .gray)
        }
    }
}
