import Cocoa

class ClipboardManager {
    private var lastChangeCount: Int = 0
    private var items: [ClipboardItem] = []
    private let maxItems = 50
    private var monitoringTimer: Timer?
    private var isMonitoring = false
    
    init() {
        lastChangeCount = NSPasteboard.general.changeCount
    }
    
    deinit {
        stopMonitoring()
    }
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        // Use 1.5s interval instead of 1s (less battery impact)
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        isMonitoring = false
    }
    
    func checkClipboard() {
        let pasteboard = NSPasteboard.general
        
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        
        guard let content = pasteboard.string(forType: .string),
              !content.isEmpty,
              content.count < 10000 else { return } // Limit max size
        
        // Don't add duplicates
        if items.first?.content == content {
            return
        }
        
        let item = ClipboardItem(
            content: content,
            timestamp: Date(),
            type: detectType(content)
        )
        
        items.insert(item, at: 0)
        
        // Keep only recent items
        if items.count > maxItems {
            items.removeLast()
        }
    }
    
    func getRecentItems() -> [ClipboardItem] {
        return items
    }
    
    func deleteItem(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
    }
    
    func clearAll() {
        items.removeAll()
    }
    
    private func detectType(_ content: String) -> ClipboardItem.ClipboardType {
        // Limit regex to first 200 chars for performance
        let checkContent = String(content.prefix(200))
        
        if checkContent.contains("@") && checkContent.contains(".") {
            let emailRegex = try? NSRegularExpression(pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}")
            let range = NSRange(location: 0, length: checkContent.utf16.count)
            if emailRegex?.firstMatch(in: checkContent, options: [], range: range) != nil {
                return .email
            }
        }
        
        if checkContent.hasPrefix("http://") || checkContent.hasPrefix("https://") {
            return .url
        }
        
        // Simple code detection without heavy regex
        if checkContent.contains("func ") || 
           checkContent.contains("class ") || 
           checkContent.contains("import ") ||
           checkContent.contains("def ") ||
           checkContent.contains("function ") {
            return .code
        }
        
        return .text
    }
}
