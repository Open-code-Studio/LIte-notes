import SwiftUI

struct SettingsView: View {
    @AppStorage("icloudSyncEnabled") private var icloudSyncEnabled = true
    
    var body: some View {
        VStack(spacing: 16) {
            Text("设置")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 16)
            
            Form {
                Section("数据同步") {
                    Toggle("启用 iCloud 同步", isOn: $icloudSyncEnabled)
                        .onChange(of: icloudSyncEnabled) { newValue in
                            if newValue {
                                // 启用iCloud同步
                                print("iCloud同步已启用")
                            } else {
                                // 禁用iCloud同步
                                print("iCloud同步已禁用")
                            }
                        }
                    
                    if icloudSyncEnabled {
                        Text("笔记将自动同步到您的iCloud账户")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Light Note")
                        Spacer()
                        Text("简洁高效的笔记应用")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    SettingsView()
}