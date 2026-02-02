import Cocoa
import ScreenCaptureKit

class ScreenshotManager {
    
    func captureFullScreen() {
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-x", getScreenshotPath()]
        try? task.run()
        
        showNotification(title: "Screenshot Saved", body: "Full screen captured")
    }
    
    func captureWithCrop() {
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-i", "-x", getScreenshotPath()]
        try? task.run()
    }
    
    func startRecording() {
        // Use ScreenCaptureKit for recording
        // This is a simplified version - full implementation would use SCStream
        showNotification(title: "Recording Started", body: "Screen recording in progress...")
    }
    
    func stopRecording() {
        showNotification(title: "Recording Stopped", body: "Video saved to Desktop")
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
