# iPad Media Player Demo App

<!--
## Screenshots

_Add screenshots of your app here. For example:_

| Home Screen | Media Player | Floating Menu |
|-------------|-------------|--------------|
| ![Home](screenshots/home.png) | ![Player](screenshots/player.png) | ![Menu](screenshots/menu.png) |
-->



---

## Table of Contents

- [Screenshots](#screenshots)
- [Overview](#overview)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [Customization](#customization)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

This is a SwiftUI-based iPad app demo for browsing, filtering, and playing media files (videos, images, GIFs) with a modern floating menu UI. The app demonstrates advanced SwiftUI techniques, custom controls, and persistent user settings.

---

## Features

- **Floating Menu:** Draggable, snappable menu with quick access to controls.
- **Media Type Filtering:** Toggle between videos, images, and GIFs.
- **Random & History Navigation:** Shuffle, previous, and next controls for media playback.
- **Seek Duration Control:** Adjustable seek duration with a custom slider.
- **Aspect Ratio Toggle:** Switch between aspect fill and fit for video playback.
- **Folder Picker:** Select folders to browse media files.
- **Persistent Settings:** User preferences (menu position, seek duration, aspect mode) are saved.
- **Modern UI:** Uses blur effects, custom icons, and smooth animations.

---

## Installation

### Prerequisites

- **Xcode 15+**
- **iOS/iPadOS 17+** (SwiftUI 3 recommended)
- **Swift 5.7+**

### Steps

1. **Clone the repository:**

   ```sh
   git clone <your-repo-url>
   cd demo
   ```

2. **Open the project:**

   - Double-click `demo.xcodeproj` to open in Xcode.

3. **Build and run:**
   - Select an iPad simulator or your iPad device.
   - Press `Cmd+R` to build and run the app.

---

## Usage

1. **Browse Media:**

   - Tap the floating menu's folder icon to pick a folder containing media files.

2. **Play Media:**

   - Select a media file to view/play it.
   - Use the floating menu to shuffle, go to previous/next, or filter by type.

3. **Adjust Settings:**

   - Tap the clock icon to set seek duration.
   - Tap the aspect ratio icon to toggle between fill and fit.
   - Use the type icon to filter by video, image, or GIF.

4. **Move Menu:**
   - Drag the floating menu to any screen corner. Its position is saved for future sessions.

---

## Project Structure

```
demo/
  ├── demo/
  │   ├── ContentView.swift           # Main app view
  │   ├── demoApp.swift               # App entry point
  │   ├── Item.swift                  # Data model for items
  │   ├── Models/
  │   │   └── MediaFile.swift         # Media file model
  │   └── Views/
  │       ├── FloatingMenu.swift      # Floating menu UI and logic
  │       ├── FolderPicker.swift      # Folder picker view
  │       ├── MediaDisplayView.swift  # Main media display
  │       ├── MediaGifView.swift      # GIF display
  │       ├── MediaImageView.swift    # Image display
  │       └── SlidingVideoPlayer.swift# Video player with controls
  ├── demoTests/                      # Unit tests
  └── demoUITests/                    # UI tests
```

---

## Customization

- **Add More Media Types:** Extend `MediaType` and update `MediaTypeToggles` in `FloatingMenu.swift`.
- **Change Default Settings:** Adjust `@AppStorage` defaults in `FloatingMenu.swift`.
- **UI Tweaks:** Modify colors, icons, and layout in the `Views/` directory.

---

## Contributing

1. Fork the repository.
2. Create a new branch: `git checkout -b feature/your-feature`
3. Make your changes and commit: `git commit -am 'Add new feature'`
4. Push to your fork: `git push origin feature/your-feature`
5. Open a Pull Request.

---

## License

[MIT](LICENSE)  
_Replace with your license as appropriate._

---

**Note:**

- For best results, use folders containing supported media types (videos, images, GIFs).
- If you encounter issues, please open an issue or submit a pull request.
