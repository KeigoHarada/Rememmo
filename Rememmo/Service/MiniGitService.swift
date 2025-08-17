import Foundation
import MiniGit
import SwiftData

struct MiniGitService: GitServiceProtocol {
    private let fileManager = FileManager.default
    private let modelContext: ModelContext?
    
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
    
    /// Documents ディレクトリ内のremmemoフォルダを取得・作成
    private func getAppManagedFolder() throws -> URL {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let appManagedFolderURL = documentsURL.appendingPathComponent("remmemo")
        
        // remmemoフォルダが存在しない場合は作成
        if !fileManager.fileExists(atPath: appManagedFolderURL.path) {
            try fileManager.createDirectory(at: appManagedFolderURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        return appManagedFolderURL
    }
    
    /// タイトルフォルダを作成・準備する
    private func createTitleFolder(title: String, in appManagedFolderURL: URL) throws -> URL {
        let titleFolderURL = appManagedFolderURL.appendingPathComponent(title)
        
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

    func gitInit(title: String, log: inout String) {
        do {
            let appManagedFolderURL = try getAppManagedFolder()
            log += "remmemoフォルダを確保しました: \(appManagedFolderURL.path)\n"
            
            let titleFolderURL = try createTitleFolder(title: title, in: appManagedFolderURL)
            log += "タイトルディレクトリを作成しました: \(titleFolderURL.path)\n"
            
            let credentialsManager = try createCredentialsManager(for: titleFolderURL)
            log += "credentials.jsonファイルを作成しました\n"
            
            // MiniGitでリポジトリを作成
            let repo = GitRepository(titleFolderURL, credentialsManager)
            repo.create()
            log += "Gitリポジトリを作成しました（git init）\n"
            repo.open()
            log += "Gitリポジトリを開きました\n"
            
            // Git設定を追加
            try createGitConfig(at: titleFolderURL)
            log += "✅ Git設定を追加しました\n"
            
            if repo.hasRepo {
                log += "✅ リポジトリ作成成功: \(titleFolderURL.path)\n"
            } else {
                log += "❌ リポジトリ作成失敗\n"
            }
        } catch {
            log += "❌ リポジトリ作成エラー: \(error)\n"
        }
        log += "=== Git Init テスト完了 ===\n\n"
    }

    func gitCommit(log: inout String) {
        do {
            // アプリ管理フォルダ（remmemo）を確認
            let appManagedFolderURL = try getAppManagedFolder()
            
            // 既存のリポジトリフォルダを探す（credentials.json の存在で判定）
            let contents = try fileManager.contentsOfDirectory(at: appManagedFolderURL, includingPropertiesForKeys: nil)
            guard let repoFolderURL = contents.first(where: { url in
                let credentialsURL = url.appendingPathComponent("credentials.json")
                return fileManager.fileExists(atPath: credentialsURL.path)
            }) else {
                log += "❌ 既存のリポジトリが見つかりません。まずgit initを実行してください\n"
                return
            }
            
            let fileURL = repoFolderURL.appendingPathComponent("test.txt")
            let content = "MiniGitテスト \(Date())"
            
            // ファイル作成
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            log += "ファイル作成: \(fileURL.lastPathComponent) in \(repoFolderURL.lastPathComponent)\n"
            
            // MiniGitでリポジトリを開く
            let credentialsManager = try createCredentialsManager(for: repoFolderURL)
            let repo = GitRepository(repoFolderURL, credentialsManager)
            repo.open()
            
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
