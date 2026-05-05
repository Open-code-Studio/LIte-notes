import SwiftUI
import SwiftData

struct TemplateEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var template: Template
    
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    TextField("模板名称", text: $template.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    Divider()
                    
                    Text("使用 {{关键字}} 的格式添加占位符，例如：{{标题}}、{{日期}}")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    TextEditor(text: $template.content)
                        .font(.body)
                        .padding(.horizontal)
                        .frame(minHeight: 400)
                        .background(Color.platformTextBackground)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    
                    if !template.placeholderKeys.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("已识别的占位符：")
                                .font(.headline)
                            
                            HStack {
                                ForEach(template.placeholderKeys, id: \.self) { key in
                                    Text("{{\(key)}}")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.accentColor.opacity(0.1))
                                        .foregroundColor(.accentColor)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 16)
            }
            .navigationTitle(template.name.isEmpty ? "新建模板" : template.name)
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
                        saveTemplate()
                    }
                    .disabled(template.name.isEmpty && template.content.isEmpty)
                }
            }
            .onChange(of: template.content) { _ in
                updatePlaceholderKeys()
            }
        }
    }
    
    private func updatePlaceholderKeys() {
        template.placeholderKeys = Template.extractPlaceholderKeys(from: template.content)
        template.updatedAt = Date()
    }
    
    private func saveTemplate() {
        isSaving = true
        template.updatedAt = Date()
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

struct TemplatePreviewView: View {
    let template: Template
    @Binding var isCreatingFromTemplate: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(template.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                Divider()
                
                Text("预览：")
                    .font(.headline)
                
                Text(template.content)
                    .font(.body)
                    .padding()
                    .background(Color.platformTextBackground)
                    .cornerRadius(12)
                
                if !template.placeholderKeys.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("占位符列表：")
                            .font(.headline)
                        
                        ForEach(template.placeholderKeys, id: \.self) { key in
                            HStack {
                                Text("• {{ \(key) }}")
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .background(Color.accentColor.opacity(0.05))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("模板预览")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("使用模板") {
                    isCreatingFromTemplate = true
                }
            }
        }
    }
}

#Preview {
    TemplateEditorView(template: Template(name: "会议记录", content: "会议主题：{{主题}}\n日期：{{日期}}\n参会人员：{{人员}}\n会议内容：\n\n{{内容}}"))
        .modelContainer(for: Template.self, inMemory: true)
}