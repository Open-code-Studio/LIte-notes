import SwiftUI
import SwiftData

struct TemplateCreatorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPreset: TemplatePreset?
    @State private var customName: String = ""
    @State private var customContent: String = ""
    @State private var showCustomEditor = false
    
    let presetTemplates: [TemplatePreset] = [
        .meetingNote,
        .todoList,
        .journal,
        .recipe,
        .projectNote
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text("选择预设模板")
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(presetTemplates) { preset in
                            PresetCard(preset: preset, isSelected: selectedPreset?.id == preset.id)
                                .onTapGesture {
                                    withAnimation(.spring()) {
                                        selectedPreset = preset
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    Button(action: {
                        showCustomEditor = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus")
                                .font(.title)
                                .foregroundColor(.accentColor)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("创建自定义模板")
                                    .font(.headline)
                                Text("从空白开始创建专属模板")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.platformControlBackground)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 16)
            }
            .navigationTitle("新建模板")
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
                    Button("创建") {
                        createTemplate()
                    }
                    .disabled(selectedPreset == nil && !showCustomEditor)
                }
            }
            .sheet(isPresented: $showCustomEditor) {
                CustomTemplateEditorView(dismiss: $showCustomEditor)
            }
        }
    }
    
    private func createTemplate() {
        if let preset = selectedPreset {
            let template = Template(name: preset.name, content: preset.content)
            modelContext.insert(template)
        }
        dismiss()
    }
}

struct PresetCard: View {
    let preset: TemplatePreset
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: preset.icon)
                .font(.system(size: 32))
                .foregroundColor(isSelected ? .accentColor : .secondary)
            
            Text(preset.name)
                .font(.headline)
                .lineLimit(1)
            
            Text(preset.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.platformControlBackground)
                .border(isSelected ? Color.accentColor : Color.clear, width: 2)
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isSelected)
    }
}

struct CustomTemplateEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var dismiss: Bool
    
    @State private var templateName: String = ""
    @State private var templateContent: String = ""
    @State private var selectedPlaceholder: String = ""
    @State private var showPlaceholderPicker = false
    
    let availablePlaceholders = ["标题", "日期", "作者", "内容", "标签", "分类", "备注", "链接"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    TextField("模板名称", text: $templateName)
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    Divider()
                    
                    HStack {
                        Text("快速添加占位符：")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Menu {
                            ForEach(availablePlaceholders, id: \.self) { placeholder in
                                Button(placeholder) {
                                    insertPlaceholder(placeholder)
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text("添加占位符")
                                    .font(.caption)
                                Image(systemName: "plus.circle")
                            }
                            .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.horizontal)
                    
                    TextEditor(text: $templateContent)
                        .font(.body)
                        .padding(.horizontal)
                        .frame(minHeight: 400)
                        .background(Color.platformTextBackground)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    
                    if !templateContent.isEmpty {
                        let placeholders = Template.extractPlaceholderKeys(from: templateContent)
                        if !placeholders.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("已添加的占位符：")
                                    .font(.headline)
                                
                                HStack {
                                    ForEach(placeholders, id: \.self) { key in
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
                }
                .padding(.vertical, 16)
            }
            .navigationTitle("自定义模板")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveTemplate()
                    }
                    .disabled(templateName.isEmpty && templateContent.isEmpty)
                }
            }
        }
    }
    
    private func insertPlaceholder(_ placeholder: String) {
        templateContent += "{{\(placeholder)}} "
    }
    
    private func saveTemplate() {
        let template = Template(name: templateName.isEmpty ? "未命名模板" : templateName, content: templateContent)
        modelContext.insert(template)
        dismiss = false
    }
}

enum TemplatePreset: Identifiable {
    case meetingNote
    case todoList
    case journal
    case recipe
    case projectNote
    
    var id: String {
        switch self {
        case .meetingNote: return "meeting"
        case .todoList: return "todo"
        case .journal: return "journal"
        case .recipe: return "recipe"
        case .projectNote: return "project"
        }
    }
    
    var name: String {
        switch self {
        case .meetingNote: return "会议记录"
        case .todoList: return "待办清单"
        case .journal: return "日记"
        case .recipe: return "食谱"
        case .projectNote: return "项目笔记"
        }
    }
    
    var description: String {
        switch self {
        case .meetingNote: return "记录会议要点和决策"
        case .todoList: return "管理日常任务和目标"
        case .journal: return "记录每日心情和想法"
        case .recipe: return "保存美食制作步骤"
        case .projectNote: return "跟踪项目进度和想法"
        }
    }
    
    var icon: String {
        switch self {
        case .meetingNote: return "calendar"
        case .todoList: return "checklist"
        case .journal: return "book"
        case .recipe: return "chefhat"
        case .projectNote: return "folder"
        }
    }
    
    var content: String {
        switch self {
        case .meetingNote:
            return """
            会议主题：{{主题}}
            日期：{{日期}}
            时间：{{时间}}
            地点：{{地点}}
            参会人员：{{人员}}
            
            会议议程：
            {{议程}}
            
            讨论内容：
            {{讨论}}
            
            决策事项：
            {{决策}}
            
            下一步行动：
            {{行动}}
            """
        case .todoList:
            return """
            {{标题}}
            
            待办事项：
            • [ ] {{任务1}}
            • [ ] {{任务2}}
            • [ ] {{任务3}}
            
            优先级：{{优先级}}
            截止日期：{{截止日期}}
            备注：{{备注}}
            """
        case .journal:
            return """
            # {{日期}}
            
            ## 今日心情
            {{心情}}/10
            
            ## 今日总结
            {{总结}}
            
            ## 感恩清单
            • {{感恩1}}
            • {{感恩2}}
            • {{感恩3}}
            
            ## 明日计划
            • {{计划1}}
            • {{计划2}}
            """
        case .recipe:
            return """
            # {{菜名}}
            
            ## 食材
            • {{食材1}}
            • {{食材2}}
            • {{食材3}}
            
            ## 步骤
            1. {{步骤1}}
            2. {{步骤2}}
            3. {{步骤3}}
            
            ## 小贴士
            {{贴士}}
            
            烹饪时间：{{时间}}
            份量：{{份量}}人份
            """
        case .projectNote:
            return """
            # {{项目名称}}
            
            ## 项目概述
            {{概述}}
            
            ## 当前状态
            {{状态}}
            
            ## 目标
            • {{目标1}}
            • {{目标2}}
            
            ## 进度
            {{进度}}%
            
            ## 待办事项
            • [ ] {{任务1}}
            • [ ] {{任务2}}
            
            ## 备注
            {{备注}}
            """
        }
    }
}

#Preview {
    TemplateCreatorView()
        .modelContainer(for: Template.self, inMemory: true)
}