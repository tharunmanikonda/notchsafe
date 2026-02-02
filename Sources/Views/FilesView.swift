import SwiftUI

struct FilesView: View {
    let fileStorage: FileStorageManager
    @Binding var files: [StoredFile]
    @State private var isDragging = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Drop zone
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isDragging ? Color.accentColor : Color.white.opacity(0.1), 
                            style: StrokeStyle(lineWidth: 2, dash: [8]))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isDragging ? Color.accentColor.opacity(0.1) : Color.clear)
                    )
                
                VStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    
                    Text("Drop files here")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 100)
            .onDrop(of: [.fileURL], isTargeted: $isDragging) { providers in
                handleDrop(providers: providers)
                return true
            }
            
            // Files list
            if files.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "folder")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary.opacity(0.5))
                    Text("No files yet")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(files) { file in
                        FileRow(file: file, onDelete: {
                            deleteFile(file)
                        })
                    }
                }
            }
        }
    }
    
    func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (urlData, error) in
                DispatchQueue.main.async {
                    guard let urlData = urlData as? Data,
                          let url = URL(dataRepresentation: urlData, relativeTo: nil) else { return }
                    
                    if let storedFile = fileStorage.saveFile(from: url) {
                        files.append(storedFile)
                    }
                }
            }
        }
    }
    
    func deleteFile(_ file: StoredFile) {
        fileStorage.deleteFile(file)
        files.removeAll { $0.id == file.id }
    }
}

struct FileRow: View {
    let file: StoredFile
    let onDelete: () -> Void
    @State private var showPreview = false
    
    var body: some View {
        HStack(spacing: 12) {
            // File icon
            Image(systemName: file.iconName)
                .font(.system(size: 24))
                .foregroundStyle(file.color)
                .frame(width: 40, height: 40)
                .background(file.color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            // File info
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                
                Text(file.formattedSize)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 8) {
                Button(action: { showPreview = true }) {
                    Image(systemName: "eye")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red.opacity(0.7))
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture {
            NSWorkspace.shared.open(file.url)
        }
    }
}

// MARK: - Models
struct StoredFile: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    let size: Int64
    let createdAt: Date
    let type: FileType
    
    enum FileType {
        case image, video, document, audio, archive, other
    }
    
    var iconName: String {
        switch type {
        case .image: return "photo.fill"
        case .video: return "video.fill"
        case .document: return "doc.text.fill"
        case .audio: return "music.note"
        case .archive: return "archivebox.fill"
        case .other: return "doc.fill"
        }
    }
    
    var color: Color {
        switch type {
        case .image: return .blue
        case .video: return .purple
        case .document: return .orange
        case .audio: return .pink
        case .archive: return .yellow
        case .other: return .gray
        }
    }
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}
