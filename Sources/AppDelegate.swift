import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var notchWindow: NotchWindow?
    var statusItem: NSStatusItem?
    var screenshotManager: ScreenshotManager?
    var fileStorage: FileStorageManager?
    var vaultManager: VaultManager?
    var clipboardManager: ClipboardManager?
    var notesManager: NotesManager?
    
    // Timers - stored to prevent leaks and allow invalidation
    private var mouseTrackingTimer: Timer?
    private var hotkeyMonitor: Any?
    
    // Screen detection
    private var notchHoverWorkItem: DispatchWorkItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory) // Hide dock icon
        
        // Initialize managers
        screenshotManager = ScreenshotManager()
        fileStorage = FileStorageManager()
        vaultManager = VaultManager()
        clipboardManager = ClipboardManager()
        notesManager = NotesManager()
        
        // Setup auto-lock callback
        vaultManager?.onAutoLock = { [weak self] in
            DispatchQueue.main.async {
                // Post notification to lock vault
                NotificationCenter.default.post(name: .vaultShouldLock, object: nil)
            }
        }
        
        // Setup notch window
        setupNotchWindow()
        
        // Setup menu bar item
        setupStatusItem()
        
        // Setup global hotkey (Cmd + Shift + N)
        setupHotkey()
        
        // Start tracking mouse for notch hover (BATTERY OPTIMIZED)
        startMouseTracking()
        
        // Listen for screen changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        
        // Start clipboard monitoring
        clipboardManager?.startMonitoring()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up timers to prevent leaks
        mouseTrackingTimer?.invalidate()
        mouseTrackingTimer = nil
        
        if let monitor = hotkeyMonitor {
            NSEvent.removeMonitor(monitor)
            hotkeyMonitor = nil
        }
        
        // Stop clipboard monitoring
        clipboardManager?.stopMonitoring()
        
        // Stop vault auto-lock
        vaultManager?.stopAutoLockTimer()
        
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func screenDidChange() {
        // Recalculate window position when screen changes
        notchWindow?.positionWindow()
    }
    
    func setupNotchWindow() {
        guard let screenshot = screenshotManager,
              let files = fileStorage,
              let vault = vaultManager,
              let clipboard = clipboardManager,
              let notes = notesManager else { return }
        
        notchWindow = NotchWindow(
            screenshotManager: screenshot,
            fileStorage: files,
            vaultManager: vault,
            clipboardManager: clipboard,
            notesManager: notes
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
    
    // MARK: - Battery Optimized Mouse Tracking
    
    func startMouseTracking() {
        // Use 0.2s interval instead of 0.1s (50% less CPU/battery usage)
        // Skip tracking when window is already visible
        mouseTrackingTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self = self,
                  self.notchWindow?.isVisible == false else { return }
            self.checkNotchHover()
        }
    }
    
    func checkNotchHover() {
        guard let window = notchWindow?.window,
              !window.isVisible else { return }
        
        let mouseLocation = NSEvent.mouseLocation
        
        // Get current screen safely
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) ?? NSScreen.main else {
            return
        }
        
        // Only show chevron if mouse is in top 100px of screen
        let screenFrame = screen.frame
        guard mouseLocation.y > screenFrame.maxY - 100 else {
            notchWindow?.hideChevron()
            return
        }
        
        // Notch area (center top of screen)
        let notchWidth: CGFloat = 200
        let notchHeight: CGFloat = 60
        let notchX = screenFrame.midX - (notchWidth / 2)
        let notchY = screenFrame.maxY - notchHeight
        
        let hoverRect = CGRect(x: notchX, y: notchY, width: notchWidth, height: notchHeight)
        
        if hoverRect.contains(mouseLocation) {
            // Debounce - don't show immediately to prevent flicker
            if notchHoverWorkItem == nil {
                let workItem = DispatchWorkItem { [weak self] in
                    self?.notchWindow?.showChevron()
                }
                notchHoverWorkItem = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: workItem)
            }
        } else {
            // Cancel pending show and hide
            notchHoverWorkItem?.cancel()
            notchHoverWorkItem = nil
            notchWindow?.hideChevron()
        }
    }
    
    @objc func toggleNotchWindow() {
        notchWindow?.toggle()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let vaultShouldLock = Notification.Name("vaultShouldLock")
}
