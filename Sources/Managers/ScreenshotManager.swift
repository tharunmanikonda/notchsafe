import Cocoa
import ScreenCaptureKit

class ScreenshotManager {
    private var isRecording = false
    
    func captureFullScreen() {
        // Use screencapture utility for reliability
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-x", getScreenshotPath()]
        
        do {
            try task.run()
            task.waitUntilExit()
            showNotification(title: "Screenshot Saved", body: "Saved to Desktop")
        } catch {
            print("Screenshot failed: \(error)")
        }
    }
    
    func captureWithCrop() {
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-i", "-x", getScreenshotPath()]
        
        do {
            try task.run()
        } catch {
            print("Crop screenshot failed: \(error)")
        }
    }
    
    func startRecording() {
        guard !isRecording else {
            showNotification(title: "Already Recording", body: "Stop current recording first")
            return
        }
        
        // Use ScreenCaptureKit for proper recording
        Task {
            do {
                let availableContent = try await SCShareableContent.current
                guard let display = availableContent.displays.first else {
                    showNotification(title: "Error", body: "No display found")
                    return
                }
                
                // Configure for recording
                let config = SCStreamConfiguration()
                config.width = display.width
                config.height = display.height
                config.minimumFrameInterval = CMTime(value: 1, timescale: 30) // 30 FPS
                config.showsCursor = true
                
                // For now, use QuickTime Player via AppleScript as full SCStream implementation
                // is complex and beyond scope of lightweight app
                DispatchQueue.main.async {
                    self.startQuickTimeRecording()
                }
            } catch {
                print("Recording setup failed: \(error)")
                showNotification(title: "Recording Failed", body: error.localizedDescription)
            }
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        // Stop QuickTime recording
        let script = """
        tell application "QuickTime Player"
            if (count of documents) > 0 then
                tell document 1
                    if recording then
                        stop
                        close
                    end if
                end tell
            end if
        end tell
        """
        
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
        }
        
        isRecording = false
        showNotification(title: "Recording Stopped", body: "Video saved")
    }
    
    private func startQuickTimeRecording() {
        let script = """
        tell application "QuickTime Player"
            activate
            new screen recording
            delay 0.5
            tell document 1
                start
            end tell
        end tell
        """
        
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
            if error == nil {
                isRecording = true
                showNotification(title: "Recording Started", body: "Use Stop Recording button when done")
            } else {
                showNotification(title: "Recording Failed", body: "Could not start QuickTime")
            }
        }
    }
    
    private func getScreenshotPath() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let filename = "Screenshot-\(formatter.string(from: Date())).png"
        
        let desktopPath = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        return desktopPath.appendingPathComponent(filename).path
    }
    
    private func showNotification(title: String, body: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = body
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }
}
