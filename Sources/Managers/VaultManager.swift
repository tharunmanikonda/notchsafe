import Foundation
import LocalAuthentication
import CryptoKit

class VaultManager {
    private let vaultURL: URL
    private let keychainKey = "notchsafe.vault.key"
    private var encryptionKey: SymmetricKey?
    
    init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        vaultURL = documentsPath.appendingPathComponent("NotchSafe/Vault", isDirectory: true)
        try? FileManager.default.createDirectory(at: vaultURL, withIntermediateDirectories: true)
        
        // Initialize or retrieve encryption key
        encryptionKey = getOrCreateEncryptionKey()
    }
    
    // MARK: - Encryption Key Management
    
    private func getOrCreateEncryptionKey() -> SymmetricKey? {
        // Try to retrieve existing key from Keychain
        if let existingKey = KeychainHelper.retrieveKey(key: keychainKey) {
            return existingKey
        }
        
        // Generate new key
        let newKey = SymmetricKey(size: .bits256)
        if KeychainHelper.storeKey(newKey, key: keychainKey) {
            return newKey
        }
        
        return nil
    }
    
    // MARK: - Authentication
    
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
            // Device doesn't support biometrics - still allow access with warning
            // In production, you'd want a password fallback
            completion(true)
        }
    }
    
    func isBiometricAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }
    
    // MARK: - File Operations with Encryption
    
    func saveFile(from url: URL) -> StoredFile? {
        guard let key = encryptionKey else {
            print("Vault: No encryption key available")
            return nil
        }
        
        let filename = url.lastPathComponent
        let encryptedFilename = filename + ".encrypted"
        let destinationURL = vaultURL.appendingPathComponent(encryptedFilename)
        
        do {
            // Read original file
            let fileData = try Data(contentsOf: url)
            
            // Encrypt the data
            let sealedBox = try AES.GCM.seal(fileData, using: key)
            guard let encryptedData = sealedBox.combined else {
                return nil
            }
            
            // Remove existing if present
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            // Write encrypted data
            try encryptedData.write(to: destinationURL)
            
            // Store metadata separately
            saveMetadata(filename: filename, originalSize: fileData.count)
            
            return StoredFile(
                url: destinationURL,
                name: filename, // Show original name in UI
                size: Int64(encryptedData.count),
                createdAt: Date(),
                type: detectFileType(url)
            )
        } catch {
            print("Vault save error: \(error)")
            return nil
        }
    }
    
    func getFiles() -> [StoredFile] {
        guard let contents = try? FileManager.default.contentsOfDirectory(at: vaultURL, includingPropertiesForKeys: nil) else {
            return []
        }
        
        return contents.compactMap { url in
            // Skip metadata files
            guard !url.lastPathComponent.hasSuffix(".metadata") else { return nil }
            
            // Get original filename (remove .encrypted suffix)
            let originalName = url.lastPathComponent.replacingOccurrences(of: ".encrypted", with: "")
            
            guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                  let size = attributes[.size] as? Int64,
                  let createdAt = attributes[.creationDate] as? Date else {
                return nil
            }
            
            // Get original size from metadata if available
            let displaySize = getOriginalSize(for: originalName) ?? Int(size)
            
            return StoredFile(
                url: url,
                name: originalName, // Show original name
                size: Int64(displaySize),
                createdAt: createdAt,
                type: detectFileType(URL(fileURLWithPath: originalName))
            )
        }.sorted { $0.createdAt > $1.createdAt }
    }
    
    func decryptFile(_ file: StoredFile) -> Data? {
        guard let key = encryptionKey else { return nil }
        
        do {
            let encryptedData = try Data(contentsOf: file.url)
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return decryptedData
        } catch {
            print("Vault decrypt error: \(error)")
            return nil
        }
    }
    
    func deleteFile(_ file: StoredFile) {
        try? FileManager.default.removeItem(at: file.url)
        
        // Also delete metadata
        let metadataURL = file.url.appendingPathExtension("metadata")
        try? FileManager.default.removeItem(at: metadataURL)
    }
    
    // MARK: - Metadata
    
    private func saveMetadata(filename: String, originalSize: Int) {
        let metadata = ["originalSize": originalSize, "createdAt": Date().timeIntervalSince1970] as [String : Any]
        let metadataURL = vaultURL.appendingPathComponent(filename + ".encrypted.metadata")
        
        if let data = try? JSONSerialization.data(withJSONObject: metadata) {
            try? data.write(to: metadataURL)
        }
    }
    
    private func getOriginalSize(for filename: String) -> Int? {
        let metadataURL = vaultURL.appendingPathComponent(filename + ".encrypted.metadata")
        guard let data = try? Data(contentsOf: metadataURL),
              let metadata = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return metadata["originalSize"] as? Int
    }
    
    // MARK: - Helpers
    
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

// MARK: - Keychain Helper

class KeychainHelper {
    static func storeKey(_ key: SymmetricKey, key account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecValueData as String: key.withUnsafeBytes { Data($0) },
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }
    
    static func retrieveKey(key account: String) -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        
        return SymmetricKey(data: data)
    }
}
