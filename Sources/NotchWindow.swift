import Cocoa
import SwiftUI

class NotchWindow: NSObject {
    var window: NSPanel!
    var chevronWindow: NSWindow?
    var isVisible = false
    
    let screenshotManager: ScreenshotManager
    let fileStorage: FileStorageManager
    let vaultManager: VaultManager
    let clipboardManager: ClipboardManager
    
    init(screenshotManager: ScreenshotManager, fileStorage: FileStorageManager, vaultManager: VaultManager, clipboardManager: ClipboardManager) {
        self.screenshotManager = screenshotManager
        self.fileStorage = fileStorage
        self.vaultManager = vaultManager
        self.clipboardManager = clipboardManager
        super.init()
        createWindow()
        createChevronWindow()
    }
    
    func createWindow() {
        let contentView = NotchSafeView(
            screenshotManager: screenshotManager,
            fileStorage: fileStorage,
            vaultManager: vaultManager,
            clipboardManager: clipboardManager,
            onClose: { [weak self] in self?.hide() }
        )
        
        let hostingView = NSHostingView(rootView: contentView)
        
        window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 500),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        window.contentView = hostingView
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.hasShadow = true
        window.animationBehavior = .utilityWindow
        
        positionWindow()
    }
    
    func createChevronWindow() {
        let chevronSize: CGFloat = 40
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let screenFrame = screen.visibleFrame
        
        chevronWindow = NSWindow(
            contentRect: NSRect(
                x: screenFrame.midX - chevronSize/2,
                y: screenFrame.maxY - 5,
                width: chevronSize,
                height: chevronSize
            ),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        let chevronView = ChevronView(onTap: { [weak self] in
            self?.toggle()
        })
        
        chevronWindow?.contentView = NSHostingView(rootView: chevronView)
        chevronWindow?.isOpaque = false
        chevronWindow?.backgroundColor = .clear
        chevronWindow?.level = .floating
        chevronWindow?.ignoresMouseEvents = false
        chevronWindow?.alphaValue = 0
    }
    
    func positionWindow() {
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let screenFrame = screen.visibleFrame
        let windowWidth: CGFloat = 360
        let windowHeight: CGFloat = 500
        
        let x = screenFrame.midX - (windowWidth / 2)
        let y = screenFrame.maxY - windowHeight - 10
        
        window.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
    }
    
    func showChevron() {
        guard !isVisible else { return }
        chevronWindow?.alphaValue = 0
        chevronWindow?.orderFront(nil)
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            chevronWindow?.animator().alphaValue = 1
        })
    }
    
    func hideChevron() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            chevronWindow?.animator().alphaValue = 0
        }) {
            self.chevronWindow?.orderOut(nil)
        }
    }
    
    func show() {
        guard !isVisible else { return }
        hideChevron()
        positionWindow()
        
        window.alphaValue = 0
        window.orderFrontRegardless()
        
        // Animate in from notch
        let startFrame = window.frame
        var endFrame = startFrame
        endFrame.origin.y += 20
        
        window.setFrame(endFrame, display: false)
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1
            window.animator().setFrame(startFrame, display: true)
        })
        
        isVisible = true
    }
    
    func hide() {
        guard isVisible else { return }
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0
            var frame = window.frame
            frame.origin.y += 10
            window.animator().setFrame(frame, display: true)
        }) {
            self.window.orderOut(nil)
            self.isVisible = false
        }
    }
    
    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }
}
