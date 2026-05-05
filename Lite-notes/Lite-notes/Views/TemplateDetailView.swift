import SwiftUI
import SwiftData

struct TemplateDetailView: View {
    let template: Template
    @Binding var isCreatingFromTemplate: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("模板内容")
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                TextEditor(text: .constant(template.content))
                    .font(.body)
                    .frame(minHeight: 200)
                    .padding()
                    .background(Color.platformControlBackground)
                    .cornerRadius(12)
                    .disabled(true)
                
                if !template.placeholderKeys.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("占位符列表")
                            .font(.headline)
                        
                        HStack {
                            ForEach(template.placeholderKeys, id: \.self) { key in
                                Text("\(key)")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.accentColor.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                Button("使用此模板创建笔记") {
                    isCreatingFromTemplate = true
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle(template.name.isEmpty ? "未命名模板" : template.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                    }
                }
            }
        }
    }
}

#Preview {
    TemplateDetailView(template: Template(name: "测试模板", content: "这是一个测试模板"), isCreatingFromTemplate: .constant(false))
}