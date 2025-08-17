import SwiftUI
import SwiftData

struct UserSettingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userSettings: [UserSettings]
    
    @State private var userName: String = ""
    @State private var userEmail: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    /// フォームのバリデーション状態
    private var isFormValid: Bool {
        let tempSettings = UserSettings(userName: userName, userEmail: userEmail)
        return tempSettings.isValid
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Git設定")) {
                    TextField("ユーザー名", text: $userName)
                        .textContentType(.name)
                    
                    TextField("メールアドレス", text: $userEmail)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section {
                    Button("設定を保存") {
                        saveSettings()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("設定")
            .alert("設定", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                loadSettings()
            }
            .onChange(of: userSettings) { _, _ in
                loadSettings()
            }
        }
    }
    
    private func saveSettings() {
        // アプリ管理フォルダのURLを取得
        let appManagedFolderURL = getAppManagedFolderURL()
        
        // UserSettingsの静的メソッドを使用してGit設定を更新
        let result = UserSettings.updateGitConfiguration(
            userName: userName,
            userEmail: userEmail,
            in: appManagedFolderURL,
            modelContext: modelContext
        )
        
        alertMessage = result.message
        showingAlert = true
        
        if result.success {
            print("✅ Git configuration updated successfully")
        } else {
            print("❌ Failed to update Git configuration: \(result.message)")
        }
    }
    
    /// アプリ管理フォルダのURLを取得
    private func getAppManagedFolderURL() -> URL {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsURL.appendingPathComponent("remmemo")
    }
    
    private func loadSettings() {
        if let settings = userSettings.first {
            // 既存の設定がある場合はその値を使用
            userName = settings.userName
            userEmail = settings.userEmail
        } else {
            // 初回読み込み時で設定が無い場合は、UserSettingsのデフォルト値を使用
            let defaultSettings = UserSettings()
            userName = defaultSettings.userName
            userEmail = defaultSettings.userEmail
        }
    }
}

struct UserSettingView_Previews: PreviewProvider {
    static var previews: some View {
        UserSettingView()
    }
}
