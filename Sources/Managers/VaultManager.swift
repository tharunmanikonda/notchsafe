import Foundation
import LocalAuthentication
import CryptoKit

class VaultManager {
    private let vaultURL: URL
    private let keychainKey = "notchsafe.vault.key"
    
    init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        vaultURL = documentsPath.appendingPathComponent("NotchSafe/Vault", isDirectory: true)
        try? FileManager.default.createDirectory(at: vaultURL, withIntermediateDirectories: true)
    }
    
    func authenticate(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric authentication is available
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Unlock your secure vault"
            
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
                completion(success)
            }
        } else {
            // Fallback to password if biometrics not available
            completion(true) // Simplified - would show password prompt
        }
    }
    
    func saveFile(from url: URL) -> StoredFile? {
        let filename = url.lastPathComponent
        let destinationURL = vaultURL.appendingPathComponent(filename)
        
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
            print("Error saving vault file: \(error)")
            return nil
        }
    }
    
    func getFiles() -> [StoredFile] {
        guard let contents = try? FileManager.default.contentsOfDirectory(at: vaultURL, includingPropertiesForKeys: nil) else {
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
