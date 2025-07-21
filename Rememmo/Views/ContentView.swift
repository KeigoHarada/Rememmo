import SwiftUI
import MiniGit

struct ContentView: View {
    @State private var log: String = ""
    @State private var testCount = 0
    @State private var repository: GitRepository?
    @State private var repoURL: URL?
    @State private var userName: String = "Rememmo User"
    @State private var userEmail: String = "user@rememmo.local"

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
                runFileTest()
            }
            .buttonStyle(.borderedProminent)
            
            Button("Git Init") {
                createRepository()
            }
            .buttonStyle(.borderedProminent)
            .disabled(repository != nil)
            
            Button("Git Commit") {
                commitFile()
            }
            .buttonStyle(.bordered)
            .disabled(repository == nil)
            
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

    private func runFileTest() {
        testCount += 1
        log += "=== ファイルテスト \(testCount) ===\n"
        
        // 基本的なファイル操作テスト
        let fileManager = FileManager.default
        let docURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let testURL = docURL.appendingPathComponent("test-file.txt")
        
        do {
            let content = "テスト内容 \(Date())"
            try content.write(to: testURL, atomically: true, encoding: .utf8)
            log += "✅ ファイル作成成功: \(testURL.path)\n"
            
            let readContent = try String(contentsOf: testURL, encoding: .utf8)
            log += "✅ ファイル読み込み成功: \(readContent)\n"
            
        } catch {
            log += "❌ ファイル操作エラー: \(error)\n"
        }
        
        log += "=== ファイルテスト完了 ===\n\n"
    }

    private func createRepository() {
        log += "=== Git Init テスト ===\n"
        
        let fileManager = FileManager.default
        let docURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let repoURL = docURL.appendingPathComponent("test-repo")
        self.repoURL = repoURL

        do {
            // 既存のディレクトリを削除
            if fileManager.fileExists(atPath: repoURL.path) {
                try fileManager.removeItem(at: repoURL)
                log += "既存ディレクトリを削除しました\n"
            }
            
            // 新しいディレクトリを作成
            try fileManager.createDirectory(at: repoURL, withIntermediateDirectories: true, attributes: nil)
            log += "ディレクトリを作成しました: \(repoURL.path)\n"
            
            // credentials.jsonファイルを作成（配列形式）
            let credentialsFileURL = repoURL.appendingPathComponent("credentials.json")
            let credentialsContent = """
            []
            """
            try credentialsContent.write(to: credentialsFileURL, atomically: true, encoding: .utf8)
            log += "credentials.jsonファイルを作成しました\n"
            
            // MiniGitでリポジトリを作成
            let credentialsManager = CredentialsManager(credentialsFileUrl: credentialsFileURL)
            let repo = GitRepository(repoURL, credentialsManager)
            
            // git init を実行
            repo.create()
            log += "Gitリポジトリを作成しました（git init）\n"
            
            // リポジトリを開く
            repo.open()
            log += "Gitリポジトリを開きました\n"
            
            // Git設定を追加
            try setupGitConfiguration(repo: repo)
            
            // リポジトリが有効かチェック
            if repo.hasRepo {
                log += "✅ リポジトリ作成成功: \(repoURL.path)\n"
                repository = repo
            } else {
                log += "❌ リポジトリ作成失敗\n"
            }
        } catch {
            log += "❌ リポジトリ作成エラー: \(error)\n"
            log += "エラー詳細: \(error.localizedDescription)\n"
        }
        
        log += "=== Git Init テスト完了 ===\n\n"
    }

    private func setupGitConfiguration(repo: GitRepository) throws {
        log += "Git設定を追加中...\n"
        
        // Git設定ファイルのパス
        let configPath = repoURL!.appendingPathComponent(".git/config")
        
        // 基本的なGit設定を作成
        let configContent = """
        [core]
        \trepositoryformatversion = 0
        \tfilemode = true
        \tbare = false
        \tlogallrefupdates = true
        \tignorecase = true
        \tprecomposeunicode = true
        
        [user]
        \tname = \(userName)
        \temail = \(userEmail)
        """
        
        try configContent.write(to: configPath, atomically: true, encoding: .utf8)
        log += "✅ Git設定を追加しました\n"
        log += "  名前: \(userName)\n"
        log += "  メール: \(userEmail)\n"
    }

    private func commitFile() {
        guard let repo = repository, repo.hasRepo, let repoURL = repoURL else {
            log += "❌ リポジトリがありません\n"
            return
        }
        
        log += "=== Git Commit テスト ===\n"
        
        let fileURL = repoURL.appendingPathComponent("test.txt")
        let content = "MiniGitテスト \(Date())"
        
        do {
            // ファイル作成
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            log += "ファイル作成: \(fileURL.lastPathComponent)\n"
            
            // ステージング
            repo.stage("test.txt")
            log += "ステージング完了\n"
            
            // コミット
            repo.commit("テストコミット")
            log += "✅ コミット成功: テストコミット\n"
            
        } catch {
            log += "❌ コミットエラー: \(error)\n"
        }
        
        log += "=== Git Commit テスト完了 ===\n\n"
    }
}

#Preview {
    ContentView()
}