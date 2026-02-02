import Foundation

class FileStorageManager {
    private let storageURL: URL
    
    init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        storageURL = documentsPath.appendingPathComponent("NotchSafe/Files", isDirectory: true)
        try? FileManager.default.createDirectory(at: storageURL, withIntermediateDirectories: true)
    }
    
    func saveFile(from url: URL) -> StoredFile? {
        let filename = url.lastPathComponent
        let destinationURL = storageURL.appendingPathComponent(filename)
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: url, to: destinationURL)
            
            let attributes = try FileManager.default.attributesOfItem(atPath: destinationURL.path)
            let size = attributes[.size] as? Int64 ?? 0
            
            return StoredFile(
                url: destinationURL,
                name: filename,
                size: size,
                createdAt: Date(),
                type: detectFileType(url)
            )
        } catch {
            print("Error saving file: \(error)")
            return nil
        }
    }
    
    func getFiles() -> [StoredFile] {
        guard let contents = try? FileManager.default.contentsOfDirectory(at: storageURL, includingPropertiesForKeys: nil) else {
            return []
        }
        
        return contents.compactMap { url in
            guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                  let size = attributes[.size] as? Int64,
                  let createdAt = attributes[.creationDate] as? Date else {
                return nil
            }
            
            return StoredFile(
                url: url,
                name: url.lastPathComponent,
                size: size,
                createdAt: createdAt,
                type: detectFileType(url)
            )
        }.sorted { $0.createdAt > $1.createdAt }
    }
    
    func deleteFile(_ file: StoredFile) {
        try? FileManager.default.removeItem(at: file.url)
    }
    
    private func detectFileType(_ url: URL) -> StoredFile.FileType {
        let ext = url.pathExtension.lowercased()
        
        switch ext {
        case "jpg", "jpeg", "png", "gif", "webp", "heic":
            return .image
        case "mp4", "mov", "avi", "mkv", "webm":
            return .video
        case "pdf", "doc", "docx", "txt", "rtf", "pages":
            return .document
        case "mp3", "wav", "aac", "m4a", "flac":
            return .audio
        case "zip", "rar", "7z", "tar", "gz":
            return .archive
        default:
            return .other
        }
    }
}
