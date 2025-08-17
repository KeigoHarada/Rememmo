import SwiftUI
import SwiftData

struct UserSettingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userSettings: [UserSettings]
    
    @State private var userName: String = ""
    @State private var userEmail: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
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
                    .disabled(userName.isEmpty || userEmail.isEmpty)
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
        // 基本的なバリデーション
        guard !userName.isEmpty else {
            alertMessage = "ユーザー名を入力してください"
            showingAlert = true
            return
        }
        
        guard !userEmail.isEmpty else {
            alertMessage = "メールアドレスを入力してください"
            showingAlert = true
            return
        }
        
        // SwiftDataに保存
        if let existingSettings = userSettings.first {
            existingSettings.userName = userName
            existingSettings.userEmail = userEmail
        } else {
            let newSettings = UserSettings(userName: userName, userEmail: userEmail)
            modelContext.insert(newSettings)
        }
        
        do {
            try modelContext.save()
            alertMessage = "設定を保存しました"
            showingAlert = true
        } catch {
            alertMessage = "設定の保存に失敗しました"
            showingAlert = true
        }
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
