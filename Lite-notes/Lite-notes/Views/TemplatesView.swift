import SwiftUI
import SwiftData

struct TemplatesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Template.updatedAt, order: .reverse) private var templates: [Template]
    @Binding var selectedTemplate: Template?
    @Binding var isCreatingFromTemplate: Bool
    
    @State private var showCreatorView = false
    @State private var showTemplateDetail: Template?
    @State private var templateToDelete: Template?
    @State private var showDeleteConfirm = false
    @State private var selectedTemplates = Set<UUID>()
    @State private var showBatchDeleteConfirm = false
    
    var body: some View {
        List {
            ForEach(templates) { template in
                HStack {
                    if !selectedTemplates.isEmpty {
                        Image(systemName: selectedTemplates.contains(template.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedTemplates.contains(template.id) ? .accentColor : .secondary)
                            .padding(.trailing, 8)
                            .onTapGesture {
                                toggleSelection(template.id)
                            }
                    }
                    
                    Button {
                        if selectedTemplates.isEmpty {
                            showTemplateDetail = template
                        } else {
                            toggleSelection(template.id)
                        }
                    } label: {
                        TemplateRowView(template: template, isSelected: selectedTemplate?.id == template.id)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            templateToDelete = template
                            showDeleteConfirm = true
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            templateToDelete = template
                            showDeleteConfirm = true
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(.init(top: 4, leading: 8, bottom: 4, trailing: 8))
            }
        }
        .listStyle(.plain)
        .navigationTitle("模板")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            if !selectedTemplates.isEmpty {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        selectedTemplates.removeAll()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(role: .destructive) {
                        showBatchDeleteConfirm = true
                    } label: {
                        Label("删除 \(selectedTemplates.count)", systemImage: "trash")
                    }
                }
            } else {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreatorView = true
                    } label: {
                        Label("新建", systemImage: "plus")
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
            if templates.isEmpty {
                EmptyTemplatesView()
            }
        }
        .sheet(isPresented: $showCreatorView) {
            TemplateCreatorView()
        }
        .sheet(item: $showTemplateDetail) { template in
            TemplateDetailView(template: template, isCreatingFromTemplate: $isCreatingFromTemplate)
                .presentationDetents([.medium, .large])
        }
        .alert("确认删除", isPresented: $showDeleteConfirm, presenting: templateToDelete) { template in
            Button("取消", role: .cancel) {
                templateToDelete = nil
            }
            Button("删除", role: .destructive) {
                deleteTemplate(template)
                templateToDelete = nil
            }
        } message: { template in
            Text("确定要删除模板 \"\(template.name.isEmpty ? "未命名模板" : template.name)\" 吗？")
        }
        .alert("确认批量删除", isPresented: $showBatchDeleteConfirm) {
            Button("取消", role: .cancel) {
                showBatchDeleteConfirm = false
            }
            Button("删除", role: .destructive) {
                deleteSelectedTemplates()
                showBatchDeleteConfirm = false
            }
        } message: {
            Text("确定要删除选中的 \(selectedTemplates.count) 个模板吗？")
        }
    }
    
    private func toggleSelection(_ id: UUID) {
        if selectedTemplates.contains(id) {
            selectedTemplates.remove(id)
        } else {
            selectedTemplates.insert(id)
        }
    }
    
    private func enterSelectionMode() {
        selectedTemplates = Set()
        if let firstTemplate = templates.first {
            selectedTemplates.insert(firstTemplate.id)
        }
    }
    
    private func deleteTemplate(_ template: Template) {
        withAnimation(.easeInOut(duration: 0.3)) {
            modelContext.delete(template)
        }
    }
    
    private func deleteSelectedTemplates() {
        withAnimation(.easeInOut(duration: 0.3)) {
            for id in selectedTemplates {
                if let template = templates.first(where: { $0.id == id }) {
                    modelContext.delete(template)
                }
            }
            selectedTemplates.removeAll()
        }
    }
}

struct TemplateRowView: View {
    let template: Template
    let isSelected: Bool
    
    #if os(macOS)
    @State private var isHovered = false
    #endif
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "square.text.square")
                .font(.title)
                .foregroundColor(isSelected ? .accentColor : .secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name.isEmpty ? "未命名模板" : template.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text("包含 \(template.placeholderKeys.count) 个占位符")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(template.updatedAt.formatted(date: .abbreviated, time: .shortened))
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
    }
}

struct EmptyTemplatesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.text.square")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
                .opacity(0.6)
            
            Text("还没有模板")
                .font(.title)
                .foregroundColor(.secondary)
            
            Text("点击右上角的按钮创建你的第一个模板")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    TemplatesView(selectedTemplate: .constant(nil), isCreatingFromTemplate: .constant(false))
        .modelContainer(for: Template.self, inMemory: true)
}