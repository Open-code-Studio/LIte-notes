import SwiftUI
import SwiftData

enum TabType {
    case notes
    case templates
}

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: TabType = .notes
    @State private var selectedNote: Note?
    @State private var selectedTemplate: Template?
    @State private var isEditing = false
    @State private var isCreatingFromTemplate = false
    
    var body: some View {
        #if os(macOS)
        NavigationSplitView {
            SidebarView(selectedTab: $selectedTab)
        } content: {
            contentView
        } detail: {
            detailView
        }
        .sheet(isPresented: $isCreatingFromTemplate) {
            TemplateSelectorView()
        }
        #else
        TabView(selection: $selectedTab) {
            NotesView(selectedNote: $selectedNote, isCreatingFromTemplate: $isCreatingFromTemplate)
                .tabItem {
                    Label("笔记", systemImage: "note.text")
                }
                .tag(TabType.notes)
            
            TemplatesView(selectedTemplate: $selectedTemplate, isCreatingFromTemplate: $isCreatingFromTemplate)
                .tabItem {
                    Label("模板", systemImage: "square.text.square")
                }
                .tag(TabType.templates)
        }
        .sheet(item: $selectedNote) { note in
            NoteEditorView(note: note)
                .presentationDetents([.medium, .large])
        }
        .sheet(item: $selectedTemplate) { template in
            TemplateEditorView(template: template)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $isCreatingFromTemplate) {
            TemplateSelectorView()
                .presentationDetents([.medium, .large])
        }
        #endif
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch selectedTab {
        case .notes:
            NotesView(selectedNote: $selectedNote, isCreatingFromTemplate: $isCreatingFromTemplate)
        case .templates:
            TemplatesView(selectedTemplate: $selectedTemplate, isCreatingFromTemplate: $isCreatingFromTemplate)
        }
    }
    
    @ViewBuilder
    private var detailView: some View {
        if let note = selectedNote {
            NoteEditorView(note: note)
        } else if let template = selectedTemplate {
            TemplatePreviewView(template: template, isCreatingFromTemplate: $isCreatingFromTemplate)
        } else {
            EmptyDetailView()
        }
    }
}

struct SidebarView: View {
    @Binding var selectedTab: TabType
    
    var body: some View {
        #if os(macOS)
        List(selection: $selectedTab) {
            Label("笔记", systemImage: "note.text")
                .tag(TabType.notes)
            
            Label("模板", systemImage: "square.text.square")
                .tag(TabType.templates)
        }
        .navigationTitle("Light Note")
        .listStyle(.sidebar)
        #else
        List {
            Button(action: { selectedTab = .notes }) {
                Label("笔记", systemImage: "note.text")
            }
            
            Button(action: { selectedTab = .templates }) {
                Label("模板", systemImage: "square.text.square")
            }
        }
        .navigationTitle("Light Note")
        #endif
    }
}

struct EmptyDetailView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "note.text")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("选择一个笔记或模板")
                .font(.title)
                .foregroundColor(.secondary)
            
            Text("开始记录你的想法")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.platformBackground)
    }
}

#Preview {
    MainView()
        .modelContainer(for: [Note.self, Template.self], inMemory: true)
}