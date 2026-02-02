import SwiftUI
import LocalAuthentication

struct VaultView: View {
    let vaultManager: VaultManager
    @Binding var isLocked: Bool
    @State private var vaultFiles: [StoredFile] = []
    @State private var isDragging = false
    @State private var showDecryptedPreview = false
    @State private var decryptedFileData: Data?
    @State private var selectedFile: StoredFile?
    
    var body: some View {
        VStack(spacing: 12) {
            if isLocked {
                LockedVaultView(
                    vaultManager: vaultManager,
                    onUnlock: authenticate
                )
            } else {
                UnlockedVaultView(
                    vaultManager: vaultManager,
                    files: $vaultFiles,
                    isDragging: $isDragging,
                    selectedFile: $selectedFile,
                    decryptedData: $decryptedFileData,
                    showPreview: $showDecryptedPreview,
                    onLock: { isLocked = true }
                )
            }
        }
        .onAppear {
            if !isLocked {
                vaultFiles = vaultManager.getFiles()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .vaultShouldLock)) { _ in
            isLocked = true
            vaultFiles = []
        }
        .sheet(isPresented: $showDecryptedPreview) {
            if let file = selectedFile, let data = decryptedFileData {
                DecryptedFilePreview(file: file, data: data)
            }
        }
    }
    
    func authenticate() {
        vaultManager.authenticate { success in
            DispatchQueue.main.async {
                if success {
                    isLocked = false
                    vaultFiles = vaultManager.getFiles()
                }
            }
        }
    }
}

struct LockedVaultView: View {
    let vaultManager: VaultManager
    let onUnlock: () -> Void
    @State private var isAuthenticating = false
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "lock.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(.green)
            }
            
            VStack(spacing: 8) {
                Text("Vault Locked")
                    .font(.system(size: 18, weight: .semibold))
                
                Text(vaultManager.isBiometricAvailable() 
                    ? "Authenticate to access your secure files"
                    : "Tap to unlock your secure files")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                isAuthenticating = true
                onUnlock()
            }) {
                HStack(spacing: 8) {
                    if isAuthenticating {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: vaultManager.isBiometricAvailable() ? "touchid" : "lock.open")
                            .font(.system(size: 16))
                    }
                    
                    Text(vaultManager.isBiometricAvailable() ? "Unlock with Touch ID" : "Unlock Vault")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.green)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .disabled(isAuthenticating)
            
            Spacer()
        }
        .padding(20)
    }
}

struct UnlockedVaultView: View {
    let vaultManager: VaultManager
    @Binding var files: [StoredFile]
    @Binding var isDragging: Bool
    @Binding var selectedFile: StoredFile?
    @Binding var decryptedData: Data?
    @Binding var showPreview: Bool
    let onLock: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with lock button
            HStack {
                Label("AES-256 Encrypted Vault", systemImage: "checkmark.shield.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.green)
                
                Spacer()
                
                Button(action: onLock) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            
            // Drop zone
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isDragging ? Color.green : Color.white.opacity(0.1),
                            style: StrokeStyle(lineWidth: 2, dash: [6]))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isDragging ? Color.green.opacity(0.1) : Color.clear)
                    )
                
                VStack(spacing: 6) {
                    Image(systemName: "shield.badge.checkmark")
                        .font(.system(size: 28))
                        .foregroundStyle(.green.opacity(0.7))
                    
                    Text("Drop sensitive files here")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    
                    Text("Files are AES-256 encrypted")
                        .font(.system(size: 10))
                        .foregroundStyle(.green.opacity(0.6))
                }
            }
            .frame(height: 90)
            .onDrop(of: [.fileURL], isTargeted: $isDragging) { providers in
                handleDrop(providers: providers)
                return true
            }
            
            // Files list
            if files.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary.opacity(0.5))
                    Text("Vault is empty")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(files) { file in
                        VaultFileRow(
                            file: file,
                            onDecrypt: { decryptAndOpen(file) },
                            onDelete: { deleteFile(file) }
                        )
                    }
                }
            }
        }
    }
    
    func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            _ = provider.loadObject(ofClass: URL.self) { url, error in
                guard let url = url else { return }
                
                DispatchQueue.main.async {
                    if let storedFile = vaultManager.saveFile(from: url) {
                        files.append(storedFile)
                    }
                }
            }
        }
    }
    
    func decryptAndOpen(_ file: StoredFile) {
        guard let data = vaultManager.decryptFile(file) else {
            return
        }
        
        selectedFile = file
        decryptedData = data
        showPreview = true
        
        // Also write to temp and open
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(file.name)
        try? data.write(to: tempURL)
        NSWorkspace.shared.open(tempURL)
    }
    
    func deleteFile(_ file: StoredFile) {
        vaultManager.deleteFile(file)
        files.removeAll { $0.id == file.id }
    }
}

struct VaultFileRow: View {
    let file: StoredFile
    let onDecrypt: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: file.iconName)
                .font(.system(size: 20))
                .foregroundStyle(.green)
                .frame(width: 36, height: 36)
                .background(Color.green.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 8))
                    Text("AES-256")
                        .font(.system(size: 9))
                }
                .foregroundStyle(.green.opacity(0.8))
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: onDecrypt) {
                    Image(systemName: "lock.open")
                        .font(.system(size: 12))
                        .foregroundStyle(.green)
                }
                .buttonStyle(.plain)
                
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10))
                        .foregroundStyle(.red.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(Color.green.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct DecryptedFilePreview: View {
    let file: StoredFile
    let data: Data
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(file.name)
                    .font(.headline)
                Spacer()
                Button("Close") { dismiss() }
                    .buttonStyle(.bordered)
            }
            
            if let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
            } else if let text = String(data: data, encoding: .utf8), text.count < 10000 {
                ScrollView {
                    Text(text)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 300)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "doc")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("File decrypted")
                        .font(.headline)
                    Text(ByteCountFormatter().string(fromByteCount: Int64(data.count)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack(spacing: 12) {
                Button("Open in Default App") {
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(file.name)
                    try? data.write(to: tempURL)
                    NSWorkspace.shared.open(tempURL)
                }
                .buttonStyle(.borderedProminent)
                
                Button("Save As...") {
                    saveFile()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(width: 400)
    }
    
    func saveFile() {
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = file.name
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            try? data.write(to: url)
        }
    }
}
