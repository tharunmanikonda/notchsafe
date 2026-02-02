import Foundation

class NotesManager {
    private let notesURL: URL
    private var notes: [QuickNote] = []
    
    init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        notesURL = documentsPath.appendingPathComponent("NotchSafe/Notes", isDirectory: true)
        try? FileManager.default.createDirectory(at: notesURL, withIntermediateDirectories: true)
        
        loadNotes()
    }
    
    func loadNotes() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: notesURL, includingPropertiesForKeys: nil) else {
            return
        }
        
        notes = files.compactMap { url in
            guard let data = try? Data(contentsOf: url),
                  let note = try? JSONDecoder().decode(QuickNote.self, from: data) else {
                return nil
            }
            return note
        }.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    func getNotes() -> [QuickNote] {
        return notes
    }
    
    func saveNote(_ note: QuickNote) {
        var updatedNote = note
        updatedNote.updatedAt = Date()
        
        let fileURL = notesURL.appendingPathComponent("\(note.id.uuidString).json")
        
        do {
            let data = try JSONEncoder().encode(updatedNote)
            try data.write(to: fileURL)
            
            // Update in-memory array
            if let index = notes.firstIndex(where: { $0.id == note.id }) {
                notes[index] = updatedNote
            } else {
                notes.insert(updatedNote, at: 0)
            }
        } catch {
            print("Error saving note: \(error)")
        }
    }
    
    func createNote(content: String = "") -> QuickNote {
        let note = QuickNote(content: content)
        saveNote(note)
        return note
    }
    
    func deleteNote(_ note: QuickNote) {
        let fileURL = notesURL.appendingPathComponent("\(note.id.uuidString).json")
        try? FileManager.default.removeItem(at: fileURL)
        notes.removeAll { $0.id == note.id }
    }
    
    func searchNotes(query: String) -> [QuickNote] {
        guard !query.isEmpty else { return notes }
        return notes.filter { $0.content.localizedCaseInsensitiveContains(query) }
    }
}

struct QuickNote: Identifiable, Codable {
    let id: UUID
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool
    
    init(id: UUID = UUID(), content: String = "", createdAt: Date = Date(), updatedAt: Date = Date(), isPinned: Bool = false) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPinned = isPinned
    }
    
    var preview: String {
        let lines = content.split(separator: "\n")
        let firstLine = String(lines.first ?? "")
        if firstLine.count > 50 {
            return String(firstLine.prefix(50)) + "..."
        }
        return firstLine.isEmpty ? "Empty note" : firstLine
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: updatedAt, relativeTo: Date())
    }
}
