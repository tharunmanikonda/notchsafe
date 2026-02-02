# NotchSafe

A lightweight macOS menu bar app that lives in your MacBook's notch. Quick screenshots, file storage, secure vault, and clipboard history - all from a beautiful dropdown interface.

![NotchSafe Demo](demo.png)

## Features

### 🎯 Notch Integration
- Hover over the MacBook notch to reveal a chevron
- Click to open a beautiful dropdown menu
- Smooth animations and transitions
- Global hotkey: **Cmd + Shift + N**

### 📸 Screenshots & Recording
- **Full Screenshot** - Capture entire screen instantly
- **Crop Screenshot** - Select area to capture
- **Screen Record** - Record your screen with one click

### 📁 File Storage
- Drag and drop any files into the app
- Quick access to stored files
- Organized by file type with icons
- One-click open or delete

### 🔒 Secure Vault
- Biometric authentication (Touch ID)
- Store sensitive files securely
- Vault locks automatically
- Encrypted storage

### 📋 Clipboard History
- Automatically tracks copied text
- Search through clipboard history
- Copy any previous item back to clipboard
- Clears after 50 items (configurable)

## Requirements

- macOS 13.0+ (Ventura or later)
- MacBook with notch (or works on external displays)
- Screen Recording permission (for screenshots)

## Installation

### From Source

```bash
# Clone the repository
git clone https://github.com/tharunmanikonda/notchsafe.git
cd notchsafe

# Build and run
swift build
swift run

# Or open in Xcode
open Package.swift
```

### Build Release

```bash
swift build -c release
```

The executable will be at `.build/release/NotchSafe`

## Permissions

On first launch, NotchSafe will request:

1. **Screen Recording** - Required for screenshots and recording
2. **Accessibility** - For global hotkeys (optional)
3. **Folder Access** - To save files

Grant these in **System Settings > Privacy & Security**

## Usage

| Action | How To |
|--------|--------|
| Open NotchSafe | Hover over notch or press Cmd+Shift+N |
| Screenshot | Click "Screenshot" or "Crop Screenshot" |
| Store File | Drag file into Files tab |
| Access Vault | Click Vault tab → Authenticate with Touch ID |
| View Clipboard | Click Clipboard tab |
| Quick Copy | Click any clipboard item |

## Architecture

```
NotchSafe/
├── Sources/
│   ├── NotchSafeApp.swift          # App entry point
│   ├── AppDelegate.swift           # App lifecycle, hotkeys, notch detection
│   ├── NotchWindow.swift           # Main popup window
│   ├── Views/
│   │   ├── NotchSafeView.swift     # Main UI container
│   │   ├── ChevronView.swift       # Notch hover indicator
│   │   ├── FilesView.swift         # File storage UI
│   │   ├── VaultView.swift         # Secure vault UI
│   │   └── ClipboardView.swift     # Clipboard history UI
│   └── Managers/
│       ├── ScreenshotManager.swift # Screenshot/recording logic
│       ├── FileStorageManager.swift # File operations
│       ├── VaultManager.swift      # Biometric auth & encryption
│       └── ClipboardManager.swift  # Clipboard monitoring
├── Package.swift
└── Info.plist
```

## Technical Details

- **Language**: Swift 5.9
- **UI Framework**: SwiftUI + AppKit
- **No external dependencies** - Uses only native macOS APIs
- **Lightweight**: < 5MB binary
- **Memory efficient**: Background monitoring with minimal footprint

## Privacy

- All data stored locally on your Mac
- No network calls or cloud storage
- Vault uses FileVault encryption via standard macOS APIs
- Clipboard data never leaves your device

## License

MIT License - Free to use and modify

## Roadmap

- [ ] Custom hotkey configuration
- [ ] Cloud sync option (iCloud)
- [ ] OCR for screenshots
- [ ] Quick share via AirDrop
- [ ] Dark mode optimization

## Credits

Created by Tharun Manikonda
