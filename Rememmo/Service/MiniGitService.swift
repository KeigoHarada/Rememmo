import Foundation
import MiniGit
import SwiftData

struct MiniGitService: GitServiceProtocol {
    private let modelContext: ModelContext?
    private let fileManager = FileManager.default

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }
    
    /// ローカルリポジトリ用のcredentials.jsonファイルを作成してCredentialsManagerを返す
    private func createCredentialsManager(for repositoryURL: URL) throws -> CredentialsManager {
        let credentialsFileURL = repositoryURL.appendingPathComponent("credentials.json")
        
        // ファイルが存在しない場合は作成
        if !fileManager.fileExists(atPath: credentialsFileURL.path) {
            let credentialsContent = "[]" // 空の配列（ローカル用）
            try credentialsContent.write(to: credentialsFileURL, atomically: true, encoding: .utf8)
        }
        
        return CredentialsManager(credentialsFileUrl: credentialsFileURL)
    }
    
    /// UserSettingsを取得する
    private func getUserSettings() -> UserSettings {
        guard let modelContext = modelContext else {
            // modelContextが無い場合はデフォルト値を返す
            return UserSettings()
        }
        
        let descriptor = FetchDescriptor<UserSettings>()
        let userSettings = try? modelContext.fetch(descriptor)
        return userSettings?.first ?? UserSettings()
    }
    
    /// Git設定ファイルを作成する（最小限の設定）
    private func createGitConfig(at repositoryURL: URL) throws {
        let userSettings = getUserSettings()
        let configPath = repositoryURL.appendingPathComponent(".git/config")
        let configContent = """
        [core]
        \trepositoryformatversion = 0
        \tbare = false
        \tignorecase = true
        \tprecomposeunicode = true
        
        [user]
        \tname = \(userSettings.userName)
        \temail = \(userSettings.userEmail)
        """
        try configContent.write(to: configPath, atomically: true, encoding: .utf8)
    }

    func gitInit(repositoryPath: String, log: inout String) {
        do {
            print("🚀 gitInit started for repositoryPath: \(repositoryPath)")
            log += "=== Git Init 開始: \(repositoryPath) ===\n"
            
            let repositoryURL = URL(fileURLWithPath: repositoryPath)
            
            // ディレクトリが存在しない場合は作成
            if !fileManager.fileExists(atPath: repositoryURL.path) {
                try fileManager.createDirectory(at: repositoryURL, withIntermediateDirectories: true, attributes: nil)
                log += "リポジトリディレクトリを作成しました: \(repositoryURL.path)\n"
            }
            
            print("🔄 About to call createCredentialsManager...")
            let credentialsManager = try createCredentialsManager(for: repositoryURL)
            print("✅ credentialsManager created successfully")
            log += "credentials.jsonファイルを作成しました\n"
            
            let repo = GitRepository(repositoryURL, credentialsManager)
            repo.create()
            log += "Gitリポジトリを作成しました（git init）\n"
            repo.open()
            log += "Gitリポジトリを開きました\n"
            
            try createGitConfig(at: repositoryURL)
            log += "✅ Git設定を追加しました\n"
            if repo.hasRepo {
                log += "✅ リポジトリ作成成功: \(repositoryURL.path)\n"
            } else {
                log += "❌ リポジトリ作成失敗\n"
            }
        } catch {
            log += "❌ リポジトリ作成エラー: \(error)\n"
        }
        log += "=== Git Init 完了 ===\n\n"
    }

    func gitCommit(repositoryPath: String, commitMessage: String, log: inout String) {
        do {
            print("🚀 gitCommit started for repositoryPath: \(repositoryPath)")
            log += "=== Git Commit 開始: \(repositoryPath) ===\n"
            
            let repositoryURL = URL(fileURLWithPath: repositoryPath)
            
            // リポジトリが存在するかチェック
            let gitPath = repositoryURL.appendingPathComponent(".git").path
            guard fileManager.fileExists(atPath: gitPath) else {
                log += "❌ 無効なリポジトリです: \(repositoryPath)\n"
                print("❌ Invalid repository: \(repositoryPath)")
                return
            }
            
            print("✅ Repository exists")
            log += "リポジトリを確認しました\n"
            
            // MiniGitでリポジトリを開く
            print("🔄 About to create credentials manager...")
            let credentialsManager = try createCredentialsManager(for: repositoryURL)
            print("✅ Credentials manager created")
            
            let repo = GitRepository(repositoryURL, credentialsManager)
            repo.open()
            log += "Gitリポジトリを開きました\n"
            print("✅ Git repository opened")
            
            // リポジトリ内のすべてのファイルをステージング
            let files = try getRepositoryFiles(at: repositoryURL)
            for file in files {
                repo.stage(file)
                print("✅ Staged file: \(file)")
            }
            log += "すべてのファイルをステージングしました（\(files.count)個のファイル）\n"
            print("✅ All files staged: \(files.count) files")
            
            // コミットメッセージが空の場合はデフォルトメッセージを使用
            let finalCommitMessage = commitMessage.isEmpty ? "update" : commitMessage
            
            // コミット実行
            repo.commit(finalCommitMessage)
            log += "✅ コミット成功: \(finalCommitMessage)\n"
            print("✅ Commit successful: \(finalCommitMessage)")
            
            // コミット後の状態確認
            if repo.hasRepo {
                log += "✅ リポジトリは正常な状態です\n"
                print("✅ Repository is in good state")
            } else {
                log += "⚠️ リポジトリの状態に問題があります\n"
                print("⚠️ Repository state issue")
            }
            
        } catch {
            log += "❌ コミットエラー: \(error.localizedDescription)\n"
            print("❌ Commit error: \(error)")
        }
        
        log += "=== Git Commit 完了 ===\n\n"
        print("🏁 gitCommit completed")
    }
    
    /// リポジトリ内のファイル一覧を再帰的に取得（.gitフォルダを除く）
    private func getRepositoryFiles(at directoryURL: URL, relativeTo baseURL: URL? = nil) throws -> [String] {
        let baseURL = baseURL ?? directoryURL
        let contents = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: [.isDirectoryKey], options: [])
        
        var files: [String] = []
        
        for item in contents {
            // .gitフォルダは除外
            if item.lastPathComponent == ".git" {
                continue
            }
            
            var isDirectory: ObjCBool = false
            fileManager.fileExists(atPath: item.path, isDirectory: &isDirectory)
            
            if isDirectory.boolValue {
                // ディレクトリの場合は再帰的に検索
                let subFiles = try getRepositoryFiles(at: item, relativeTo: baseURL)
                files.append(contentsOf: subFiles)
            } else {
                // ファイルの場合は相対パスを追加
                let relativePath = directoryURL == baseURL ? 
                    item.lastPathComponent : 
                    String(item.path.dropFirst(baseURL.path.count + 1))
                files.append(relativePath)
            }
        }
        
        return files
    }
}
