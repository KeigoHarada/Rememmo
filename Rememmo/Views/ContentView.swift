import SwiftUI

struct ContentView: View {
    @State private var log: String = ""
    @State private var testCount = 0
    @State private var userName: String = "Rememmo User"
    @State private var userEmail: String = "user@rememmo.local"
    let gitService: GitServiceProtocol

    var body: some View {
        VStack(spacing: 20) {
            Text("Rememmo テスト")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Git設定:")
                    .font(.headline)
                
                HStack {
                    Text("名前:")
                    TextField("ユーザー名", text: $userName)
                        .textFieldStyle(.roundedBorder)
                }
                
                HStack {
                    Text("メール:")
                    TextField("メールアドレス", text: $userEmail)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            Button("ファイルテスト") {
                gitService.fileTest(log: &log)
            }
            .buttonStyle(.borderedProminent)
            
            Button("Git Init") {
                gitService.gitInit(log: &log)
            }
            .buttonStyle(.borderedProminent)
            .disabled(false)
            
            Button("Git Commit") {
                gitService.gitCommit(log: &log)
            }
            .buttonStyle(.bordered)
            .disabled(false)
            
            Button("ログクリア") {
                log = ""
            }
            .buttonStyle(.bordered)
            
            ScrollView {
                Text(log)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .frame(height: 300)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(gitService: DummyGitService())
    }
}
