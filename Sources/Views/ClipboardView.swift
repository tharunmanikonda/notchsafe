import SwiftUI

struct ClipboardView: View {
    let manager: ClipboardManager
    @Binding var items: [ClipboardItem]
    @State private var searchText = ""
    
    var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return items
        }
        return items.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                
                TextField("Search clipboard...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
            }
            .padding(10)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            // Items list
            if filteredItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary.opacity(0.5))
                    Text(items.isEmpty ? "Clipboard is empty" : "No matches found")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(filteredItems) { item in
                        ClipboardItemRow(item: item, onCopy: {
                            copyToClipboard(item)
                        }, onDelete: {
                            deleteItem(item)
                        })
                    }
                }
            }
            
            // Footer
            HStack {
                Text("\(items.count) items")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button("Clear All") {
                    manager.clearAll()
                    items.removeAll()
                }
                .font(.system(size: 11))
                .foregroundStyle(.red.opacity(0.7))
                .buttonStyle(.plain)
            }
        }
    }
    
    func copyToClipboard(_ item: ClipboardItem) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.content, forType: .string)
    }
    
    func deleteItem(_ item: ClipboardItem) {
        manager.deleteItem(item)
        items.removeAll { $0.id == item.id }
    }
}

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let onCopy: () -> Void
    let onDelete: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 10) {
            // Content preview
            VStack(alignment: .leading, spacing: 4) {
                Text(item.preview)
                    .font(.system(size: 13))
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                
                Text(item.timeAgo)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 4) {
                Button(action: onCopy) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.accent)
                .opacity(isHovered ? 1 : 0)
                
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(isHovered ? Color.white.opacity(0.08) : Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Model
struct ClipboardItem: Identifiable {
    let id = UUID()
    let content: String
    let timestamp: Date
    let type: ClipboardType
    
    enum ClipboardType {
        case text, url, email, code
    }
    
    var preview: String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > 100 {
            return String(trimmed.prefix(100)) + "..."
        }
        return trimmed
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
