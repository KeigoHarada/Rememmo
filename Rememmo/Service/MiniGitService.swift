import Foundation
import MiniGit
import SwiftData

struct MiniGitService: GitServiceProtocol {
    private let modelContext: ModelContext?
    private let fileManager = FileManager.default
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

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
    
    /// タイトルフォルダを作成・準備する
    private func createTitleFolder(title: String, in documentsURL: URL) throws -> URL {
        let titleFolderURL = documentsURL.appendingPathComponent(title)
        
        // 既存のディレクトリを削除
        if fileManager.fileExists(atPath: titleFolderURL.path) {
            try fileManager.removeItem(at: titleFolderURL)
        }
        
        // 新しいディレクトリを作成
        try fileManager.createDirectory(at: titleFolderURL, withIntermediateDirectories: true, attributes: nil)
        
        return titleFolderURL
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

    func gitCommit(repositoryPath: String, fileName: String, commitMessage: String, log: inout String) {
        do {
            print("🚀 gitCommit started for repositoryPath: \(repositoryPath), fileName: \(fileName)")
            log += "=== Git Commit 開始: \(repositoryPath) ===\n"
            
            let repositoryURL = URL(fileURLWithPath: repositoryPath)
            let fileURL = repositoryURL.appendingPathComponent(fileName)
            
            // リポジトリが存在するかチェック
            let gitPath = repositoryURL.appendingPathComponent(".git").path
            guard fileManager.fileExists(atPath: gitPath) else {
                log += "❌ 無効なリポジトリです: \(repositoryPath)\n"
                print("❌ Invalid repository: \(repositoryPath)")
                return
            }
            
            // ファイルが存在するかチェック
            guard fileManager.fileExists(atPath: fileURL.path) else {
                log += "❌ ファイルが見つかりません: \(fileURL.path)\n"
                print("❌ File not found: \(fileURL.path)")
                return
            }
            
            print("✅ Repository and file exist")
            log += "リポジトリとファイルを確認しました\n"
            
            // MiniGitでリポジトリを開く
            print("🔄 About to create credentials manager...")
            let credentialsManager = try createCredentialsManager(for: repositoryURL)
            print("✅ Credentials manager created")
            
            let repo = GitRepository(repositoryURL, credentialsManager)
            repo.open()
            log += "Gitリポジトリを開きました\n"
            print("✅ Git repository opened")
            
            // ファイルをステージング
            repo.stage(fileName)
            log += "ファイルをステージングしました: \(fileName)\n"
            print("✅ File staged: \(fileName)")
            
            // コミットメッセージが空の場合はデフォルトメッセージを使用
            let finalCommitMessage = commitMessage.isEmpty ? "ファイルを更新: \(fileName)" : commitMessage
            
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
}
