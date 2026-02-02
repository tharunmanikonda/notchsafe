import SwiftUI

struct NotesView: View {
    let notesManager: NotesManager
    @State private var notes: [QuickNote] = []
    @State private var selectedNote: QuickNote?
    @State private var isEditing = false
    @State private var searchText = ""
    
    var filteredNotes: [QuickNote] {
        if searchText.isEmpty {
            return notes.sorted { $0.isPinned && !$1.isPinned }
        }
        return notesManager.searchNotes(query: searchText)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Quick Notes")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                Button(action: createNewNote) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.accent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                
                TextField("Search notes...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
            }
            .padding(10)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            // Notes list or Editor
            if isEditing, let note = selectedNote {
                NoteEditor(
                    note: note,
                    onSave: { updatedNote in
                        saveNote(updatedNote)
                    },
                    onClose: {
                        isEditing = false
                        selectedNote = nil
                    }
                )
            } else {
                notesList
            }
        }
    }
    
    var notesList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 8) {
                if filteredNotes.isEmpty {
                    emptyState
                } else {
                    ForEach(filteredNotes) { note in
                        NoteRow(
                            note: note,
                            onTap: {
                                selectedNote = note
                                isEditing = true
                            },
                            onPin: { togglePin(note) },
                            onDelete: { deleteNote(note) }
                        )
                    }
                }
            }
            .padding(16)
        }
    }
    
    var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "note.text")
                .font(.system(size: 48))
                .foregroundStyle(.secondary.opacity(0.5))
            
            Text("No notes yet")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            
            Button("Create your first note") {
                createNewNote()
            }
            .font(.system(size: 13))
            .foregroundStyle(.accent)
            .buttonStyle(.plain)
        }
        .frame(maxHeight: .infinity)
        .padding(.top, 60)
    }
    
    func createNewNote() {
        let newNote = notesManager.createNote()
        notes.insert(newNote, at: 0)
        selectedNote = newNote
        isEditing = true
    }
    
    func saveNote(_ note: QuickNote) {
        notesManager.saveNote(note)
        loadNotes()
    }
    
    func deleteNote(_ note: QuickNote) {
        notesManager.deleteNote(note)
        notes.removeAll { $0.id == note.id }
    }
    
    func togglePin(_ note: QuickNote) {
        var updated = note
        updated.isPinned.toggle()
        saveNote(updated)
    }
    
    func loadNotes() {
        notes = notesManager.getNotes()
    }
}

struct NoteRow: View {
    let note: QuickNote
    let onTap: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 10) {
            // Pin indicator
            if note.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.accent)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(note.preview)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                
                Text(note.timeAgo)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 4) {
                Button(action: onPin) {
                    Image(systemName: note.isPinned ? "pin.slash" : "pin")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundStyle(note.isPinned ? .accent : .secondary)
                .opacity(isHovered ? 1 : 0)
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red.opacity(0.7))
            }
        }
        .padding(12)
        .background(isHovered ? Color.white.opacity(0.08) : Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            onTap()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(note.isPinned ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

struct NoteEditor: View {
    let note: QuickNote
    let onSave: (QuickNote) -> Void
    let onClose: () -> Void
    
    @State private var content: String = ""
    @FocusState private isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Button("Back") {
                    saveAndClose()
                }
                .font(.system(size: 13))
                .foregroundStyle(.accent)
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("Note")
                    .font(.system(size: 14, weight: .medium))
                
                Spacer()
                
                Button("Done") {
                    saveAndClose()
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.accent)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Text editor
            TextEditor(text: $content)
                .font(.system(size: 14))
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .focused($isFocused)
                .padding(12)
        }
        .onAppear {
            content = note.content
            isFocused = true
        }
    }
    
    func saveAndClose() {
        var updatedNote = note
        updatedNote.content = content
        onSave(updatedNote)
        onClose()
    }
}
