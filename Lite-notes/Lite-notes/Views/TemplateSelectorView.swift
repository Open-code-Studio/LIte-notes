import SwiftUI
import SwiftData

struct TemplateSelectorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var templates: [Template] = []
    @State private var selectedTemplate: Template?
    @State private var placeholderValues: [String: String] = [:]
    
    var body: some View {
        NavigationStack {
            if let template = selectedTemplate {
                VStack(spacing: 16) {
                    Text("填写占位符")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Divider()
                    
                    Form {
                        ForEach(template.placeholderKeys, id: \.self) { key in
                            TextField(key, text: Binding(
                                get: { placeholderValues[key] ?? "" },
                                set: { placeholderValues[key] = $0 }
                            ))
                        }
                    }
                    
                    Button("创建笔记") {
                        createNoteFromTemplate()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .navigationTitle(template.name)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("返回") {
                            selectedTemplate = nil
                            fetchTemplates()
                        }
                    }
                }
            } else {
                VStack(spacing: 0) {
                    Text("选择一个模板")
                        .font(.headline)
                        .padding()
                    
                    Divider()
                    
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(templates, id: \.id) { template in
                                Button(action: {
                                    selectedTemplate = template
                                    placeholderValues = [:]
                                    template.placeholderKeys.forEach { key in
                                        placeholderValues[key] = ""
                                    }
                                }) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(template.name.isEmpty ? "未命名模板" : template.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        Text("\(template.placeholderKeys.count) 个占位符")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.accentColor.opacity(0.1))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                }
                .navigationTitle("选择模板")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") {
                            dismiss()
                        }
                    }
                }
                .overlay {
                    if templates.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "square.text.square")
                                .font(.system(size: 64))
                                .foregroundColor(.accentColor)
                                .opacity(0.6)
                            
                            Text("还没有模板")
                                .font(.title)
                                .foregroundColor(.secondary)
                            
                            Text("请先创建模板")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        .onAppear {
            fetchTemplates()
            if let template = selectedTemplate, placeholderValues.isEmpty {
                template.placeholderKeys.forEach { key in
                    placeholderValues[key] = ""
                }
            }
        }
    }
    
    private func fetchTemplates() {
        let descriptor = FetchDescriptor<Template>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        do {
            templates = try modelContext.fetch(descriptor)
            print("获取到 \(templates.count) 个模板")
        } catch {
            print("获取模板失败: \(error)")
        }
    }
    
    private func createNoteFromTemplate() {
        guard let template = selectedTemplate else { return }
        
        let content = template.applyPlaceholderValues(placeholderValues)
        let note = Note(
            title: placeholderValues["title"] ?? placeholderValues["标题"] ?? template.name,
            content: content,
            templateId: template.id
        )
        
        modelContext.insert(note)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("创建笔记失败: \(error)")
        }
    }
}

#Preview {
    TemplateSelectorView()
        .modelContainer(for: [Template.self, Note.self], inMemory: true)
}