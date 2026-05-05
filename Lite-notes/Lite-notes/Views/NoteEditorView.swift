import SwiftUI
import SwiftData

struct NoteEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var note: Note
    
    @State private var isSaving = false
    @State private var showTemplateMode = false
    @State private var placeholderValues: [String: String] = [:]
    @Query private var templates: [Template]
    
    private var associatedTemplate: Template? {
        guard let templateId = note.templateId else { return nil }
        return templates.first { $0.id == templateId }
    }
    
    var body: some View {
        NavigationStack {
            if showTemplateMode, let template = associatedTemplate {
                templateEditingView(template: template)
            } else {
                normalEditingView()
            }
        }
        .onAppear {
            if let template = associatedTemplate {
                extractPlaceholderValues(from: template)
            }
        }
    }
    
    @ViewBuilder
    private func normalEditingView() -> some View {
        ScrollView {
            VStack(spacing: 16) {
                TextField("标题", text: $note.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                Divider()
                
                TextEditor(text: $note.content)
                    .font(.body)
                    .padding(.horizontal)
                    .frame(minHeight: 400)
                    .background(Color.platformTextBackground)
                    .cornerRadius(12)
                    .padding(.horizontal)
                
                if let template = associatedTemplate {
                    HStack {
                        Text("基于模板: \(template.name)")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                            .padding(.horizontal)
                        
                        Spacer()
                        
                        Button("模板模式编辑") {
                            showTemplateMode = true
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundColor(.accentColor)
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical, 16)
        }
        .navigationTitle(note.title.isEmpty ? "编辑笔记" : note.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    saveNote()
                }
                .disabled(note.title.isEmpty && note.content.isEmpty)
            }
        }
        .onChange(of: note.title) { _ in
            updateTimestamp()
        }
        .onChange(of: note.content) { _ in
            updateTimestamp()
        }
    }
    
    @ViewBuilder
    private func templateEditingView(template: Template) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                TextField("标题", text: $note.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                Divider()
                
                Text("编辑占位符值")
                    .font(.headline)
                    .padding(.horizontal)
                
                Form {
                    ForEach(template.placeholderKeys, id: \.self) { key in
                        TextField(key, text: Binding(
                            get: { placeholderValues[key] ?? "" },
                            set: { placeholderValues[key] = $0 }
                        ))
                    }
                }
                
                Text("预览")
                    .font(.headline)
                    .padding(.horizontal)
                
                Text(template.applyPlaceholderValues(placeholderValues))
                    .font(.body)
                    .padding()
                    .background(Color.platformTextBackground)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            .padding(.vertical, 16)
        }
        .navigationTitle(template.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("返回") {
                    showTemplateMode = false
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("应用并保存") {
                    applyTemplateAndSave(template: template)
                }
                .disabled(placeholderValues.values.allSatisfy { $0.isEmpty })
            }
        }
    }
    
    private func extractPlaceholderValues(from template: Template) {
        placeholderValues = [:]
        let content = note.content
        
        for key in template.placeholderKeys {
            let pattern = "\\{\\{\(key)\\}\\s*([^\\}]*)"
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)),
               let valueRange = Range(match.range(at: 1), in: content) {
                placeholderValues[key] = String(content[valueRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                placeholderValues[key] = ""
            }
        }
    }
    
    private func applyTemplateAndSave(template: Template) {
        note.content = template.applyPlaceholderValues(placeholderValues)
        updateTimestamp()
        saveNote()
    }
    
    private func updateTimestamp() {
        note.updatedAt = Date()
    }
    
    private func saveNote() {
        isSaving = true
        do {
            try modelContext.save()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isSaving = false
                dismiss()
            }
        } catch {
            print("保存失败: \(error)")
            isSaving = false
        }
    }
}

#Preview {
    NoteEditorView(note: Note(title: "测试笔记", content: "这是一篇测试笔记内容"))
        .modelContainer(for: Note.self, inMemory: true)
}