import SwiftUI

struct NotchSafeView: View {
    let screenshotManager: ScreenshotManager
    let fileStorage: FileStorageManager
    let vaultManager: VaultManager
    let clipboardManager: ClipboardManager
    let onClose: () -> Void
    
    @State private var selectedTab: Tab = .actions
    @State private var files: [StoredFile] = []
    @State private var clipboardItems: [ClipboardItem] = []
    @State private var isVaultLocked = true
    @State private var showAuthPrompt = false
    
    enum Tab: String, CaseIterable {
        case actions = "bolt.fill"
        case files = "folder.fill"
        case vault = "lock.shield.fill"
        case clipboard = "doc.on.clipboard.fill"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle bar at top
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 8)
            
            // Tab selector
            HStack(spacing: 20) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    TabButton(icon: tab.rawValue, isSelected: selectedTab == tab) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedTab = tab
                            if tab == .vault && isVaultLocked {
                                showAuthPrompt = true
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 12)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    switch selectedTab {
                    case .actions:
                        ActionsView(screenshotManager: screenshotManager)
                    case .files:
                        FilesView(fileStorage: fileStorage, files: $files)
                    case .vault:
                        VaultView(vaultManager: vaultManager, isLocked: $isVaultLocked)
                    case .clipboard:
                        ClipboardView(manager: clipboardManager, items: $clipboardItems)
                    }
                }
                .padding(16)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .frame(width: 340, height: 460)
        .onAppear {
            files = fileStorage.getFiles()
            clipboardItems = clipboardManager.getRecentItems()
        }
        .sheet(isPresented: $showAuthPrompt) {
            AuthSheet(vaultManager: vaultManager, isLocked: $isVaultLocked)
        }
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(isSelected ? Color.accentColor : Color.clear)
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Actions View
struct ActionsView: View {
    let screenshotManager: ScreenshotManager
    @State private var isRecording = false
    
    var body: some View {
        VStack(spacing: 12) {
            ActionButton(
                icon: "camera.fill",
                title: "Screenshot",
                subtitle: "Capture full screen",
                color: .blue
            ) {
                screenshotManager.captureFullScreen()
            }
            
            ActionButton(
                icon: "crop",
                title: "Crop Screenshot",
                subtitle: "Select area to capture",
                color: .green
            ) {
                screenshotManager.captureWithCrop()
            }
            
            ActionButton(
                icon: isRecording ? "stop.circle.fill" : "video.circle.fill",
                title: isRecording ? "Stop Recording" : "Screen Record",
                subtitle: isRecording ? "Recording in progress..." : "Record your screen",
                color: isRecording ? .red : .purple
            ) {
                if isRecording {
                    screenshotManager.stopRecording()
                    isRecording = false
                } else {
                    screenshotManager.startRecording()
                    isRecording = true
                }
            }
        }
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
