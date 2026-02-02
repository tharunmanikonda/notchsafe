import Cocoa
import SwiftUI
import ScreenCaptureKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var notchWindow: NotchWindow?
    var statusItem: NSStatusItem?
    var screenshotManager: ScreenshotManager?
    var fileStorage: FileStorageManager?
    var vaultManager: VaultManager?
    var clipboardManager: ClipboardManager?
    
    // Hotkey
    var hotkeyMonitor: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory) // Hide dock icon
        
        // Initialize managers
        screenshotManager = ScreenshotManager()
        fileStorage = FileStorageManager()
        vaultManager = VaultManager()
        clipboardManager = ClipboardManager()
        
        // Setup notch window
        setupNotchWindow()
        
        // Setup menu bar item
        setupStatusItem()
        
        // Setup global hotkey (Cmd + Shift + N)
        setupHotkey()
        
        // Start tracking mouse for notch hover
        startMouseTracking()
    }
    
    func setupNotchWindow() {
        notchWindow = NotchWindow(
            screenshotManager: screenshotManager!,
            fileStorage: fileStorage!,
            vaultManager: vaultManager!,
            clipboardManager: clipboardManager!
        )
    }
    
    func setupStatusItem() {
        statusItem = NSStatusBar.shared.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.image = NSImage(systemSymbolName: "lock.shield", accessibilityDescription: "NotchSafe")
        statusItem?.button?.action = #selector(toggleNotchWindow)
        statusItem?.button?.target = self
    }
    
    func setupHotkey() {
        hotkeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Cmd + Shift + N
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 45 {
                self?.toggleNotchWindow()
            }
        }
    }
    
    func startMouseTracking() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.checkNotchHover()
        }
    }
    
    func checkNotchHover() {
        guard let window = notchWindow?.window else { return }
        
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let screenFrame = screen.frame
        
        // Notch area (center top of screen)
        let notchWidth: CGFloat = 200
        let notchHeight: CGFloat = 32
        let notchX = screenFrame.midX - (notchWidth / 2)
        let notchY = screenFrame.maxY - notchHeight
        
        let notchRect = CGRect(x: notchX, y: notchY, width: notchWidth, height: notchHeight)
        let hoverBuffer: CGFloat = 50 // Detection area above notch
        let hoverRect = CGRect(x: notchX, y: notchY - hoverBuffer, width: notchWidth, height: notchHeight + hoverBuffer)
        
        if hoverRect.contains(mouseLocation) {
            notchWindow?.showChevron()
        } else if !window.frame.contains(mouseLocation) {
            notchWindow?.hide()
        }
    }
    
    @objc func toggleNotchWindow() {
        notchWindow?.toggle()
    }
}
