import Cocoa

class ClipboardManager {
    private var lastChangeCount: Int = 0
    private var items: [ClipboardItem] = []
    private let maxItems = 50
    
    init() {
        lastChangeCount = NSPasteboard.general.changeCount
        startMonitoring()
    }
    
    func startMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    func checkClipboard() {
        let pasteboard = NSPasteboard.general
        
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        
        guard let content = pasteboard.string(forType: .string),
              !content.isEmpty else { return }
        
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
        if content.contains("@") && content.contains(".") {
            let emailRegex = try? NSRegularExpression(pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}")
            let range = NSRange(location: 0, length: content.utf16.count)
            if emailRegex?.firstMatch(in: content, options: [], range: range) != nil {
                return .email
            }
        }
        
        if content.hasPrefix("http://") || content.hasPrefix("https://") {
            return .url
        }
        
        if content.contains("func ") || content.contains("class ") || content.contains("import ") {
            return .code
        }
        
        return .text
    }
}
