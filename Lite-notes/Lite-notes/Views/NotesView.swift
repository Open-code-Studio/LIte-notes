import SwiftUI
import SwiftData

struct NotesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Note.updatedAt, order: .reverse) private var notes: [Note]
    @Binding var selectedNote: Note?
    @Binding var isCreatingFromTemplate: Bool
    
    @State private var noteToDelete: Note?
    @State private var showDeleteConfirm = false
    @State private var selectedNotes = Set<UUID>()
    @State private var showBatchDeleteConfirm = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(notes) { note in
                    Button {
                        if selectedNotes.isEmpty {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedNote = note
                            }
                        } else {
                            toggleSelection(note.id)
                        }
                    } label: {
                        HStack {
                            if !selectedNotes.isEmpty {
                                Image(systemName: selectedNotes.contains(note.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedNotes.contains(note.id) ? .accentColor : .secondary)
                                    .padding(.trailing, 8)
                            }
                            noteRowView(for: note)
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init(top: 4, leading: 8, bottom: 4, trailing: 8))
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            noteToDelete = note
                            showDeleteConfirm = true
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            noteToDelete = note
                            showDeleteConfirm = true
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("笔记")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                if !selectedNotes.isEmpty {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") {
                            selectedNotes.removeAll()
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button(role: .destructive) {
                            showBatchDeleteConfirm = true
                        } label: {
                            Label("删除 \(selectedNotes.count)", systemImage: "trash")
                        }
                    }
                } else {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            createNewNote()
                        } label: {
                            Label("新建笔记", systemImage: "plus")
                        }
                    }
                    
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            isCreatingFromTemplate = true
                        } label: {
                            Label("从模板创建", systemImage: "square.text.square")
                        }
                    }
                    
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            enterSelectionMode()
                        } label: {
                            Label("选择", systemImage: "checkmark.circle")
                        }
                    }
                }
            }
            .overlay {
                if notes.isEmpty {
                    EmptyNotesView()
                }
            }
            .alert("确认删除", isPresented: $showDeleteConfirm, presenting: noteToDelete) { note in
                Button("取消", role: .cancel) {
                    noteToDelete = nil
                }
                Button("删除", role: .destructive) {
                    deleteNote(note)
                    noteToDelete = nil
                }
            } message: { note in
                Text("确定要删除笔记 \"\(note.title.isEmpty ? "无标题" : note.title)\" 吗？")
            }
            .alert("确认批量删除", isPresented: $showBatchDeleteConfirm) {
                Button("取消", role: .cancel) {
                    showBatchDeleteConfirm = false
                }
                Button("删除", role: .destructive) {
                    deleteSelectedNotes()
                    showBatchDeleteConfirm = false
                }
            } message: {
                Text("确定要删除选中的 \(selectedNotes.count) 条笔记吗？")
            }
            .onTapGesture {
                if !selectedNotes.isEmpty {
                    selectedNotes.removeAll()
                }
            }
        }
    }
    
    private func toggleSelection(_ id: UUID) {
        if selectedNotes.contains(id) {
            selectedNotes.remove(id)
        } else {
            selectedNotes.insert(id)
        }
    }
    
    @ViewBuilder
    private func noteRowView(for note: Note) -> some View {
        NoteRowView(note: note, isSelected: selectedNote?.id == note.id)
    }
    
    private func enterSelectionMode() {
        selectedNotes = Set()
        if let firstNote = notes.first {
            selectedNotes.insert(firstNote.id)
        }
    }
    
    private func createNewNote() {
        let note = Note()
        modelContext.insert(note)
        Task { @MainActor in
            try? await modelContext.save()
        }
    }
    
    private func deleteNote(_ note: Note) {
        withAnimation(.easeInOut(duration: 0.3)) {
            modelContext.delete(note)
        }
    }
    
    private func deleteSelectedNotes() {
        withAnimation(.easeInOut(duration: 0.3)) {
            for id in selectedNotes {
                if let note = notes.first(where: { $0.id == id }) {
                    modelContext.delete(note)
                }
            }
            selectedNotes.removeAll()
        }
    }
}

struct NoteRowView: View {
    let note: Note
    let isSelected: Bool
    
    #if os(macOS)
    @State private var isHovered = false
    #endif
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "note.text")
                .font(.title)
                .foregroundColor(isSelected ? .accentColor : .secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(note.title.isEmpty ? "无标题" : note.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(note.content.prefix(50))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(note.updatedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : .platformControlBackground)
                #if os(macOS)
                .shadow(color: isHovered ? .black.opacity(0.1) : .black.opacity(0.03), radius: isHovered ? 8 : 2, x: 0, y: isHovered ? 4 : 1)
                #endif
        )
        #if os(macOS)
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .onHover { hovering in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isHovered = hovering
            }
        }
        #endif
        .transition(.asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .scale(scale: 0.9).combined(with: .opacity)
        ))
    }
}

struct EmptyNotesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "pencil.and.outline")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
                .opacity(0.6)
            
            Text("还没有笔记")
                .font(.title)
                .foregroundColor(.secondary)
            
            Text("点击右上角的按钮创建你的第一篇笔记")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NotesView(selectedNote: .constant(nil), isCreatingFromTemplate: .constant(false))
        .modelContainer(for: Note.self, inMemory: true)
}