import SwiftUI
import LocalAuthentication

struct VaultView: View {
    let vaultManager: VaultManager
    @Binding var isLocked: Bool
    @State private var vaultFiles: [StoredFile] = []
    @State private var isDragging = false
    
    var body: some View {
        VStack(spacing: 12) {
            if isLocked {
                LockedVaultView(onUnlock: authenticate)
            } else {
                UnlockedVaultView(
                    vaultManager: vaultManager,
                    files: $vaultFiles,
                    isDragging: $isDragging,
                    onLock: { isLocked = true }
                )
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
    let onUnlock: () -> Void
    @State private var isAuthenticating = false
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "lock.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(.accent)
            }
            
            VStack(spacing: 8) {
                Text("Vault Locked")
                    .font(.system(size: 18, weight: .semibold))
                
                Text("Authenticate to access your secure files")
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
                        Image(systemName: "touchid")
                            .font(.system(size: 16))
                    }
                    
                    Text("Unlock with Touch ID")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.accentColor)
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
    let onLock: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with lock button
            HStack {
                Label("Secure Vault", systemImage: "checkmark.shield.fill")
                    .font(.system(size: 14, weight: .medium))
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
                }
            }
            .frame(height: 80)
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
                        VaultFileRow(file: file, onDelete: {
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
                    
                    if let storedFile = vaultManager.saveFile(from: url) {
                        files.append(storedFile)
                    }
                }
            }
        }
    }
    
    func deleteFile(_ file: StoredFile) {
        vaultManager.deleteFile(file)
        files.removeAll { $0.id == file.id }
    }
}

struct VaultFileRow: View {
    let file: StoredFile
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
                
                Text("••• Encrypted")
                    .font(.system(size: 10))
                    .foregroundStyle(.green.opacity(0.8))
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 10))
                    .foregroundStyle(.red.opacity(0.7))
            }
            .buttonStyle(.plain)
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

struct AuthSheet: View {
    let vaultManager: VaultManager
    @Binding var isLocked: Bool
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(.accent)
            
            Text("Authentication Required")
                .font(.system(size: 18, weight: .semibold))
            
            Text("Access your secure vault using Touch ID or password")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Authenticate") {
                vaultManager.authenticate { success in
                    DispatchQueue.main.async {
                        if success {
                            isLocked = false
                        }
                        dismiss()
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            
            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(32)
        .frame(width: 300)
    }
}
