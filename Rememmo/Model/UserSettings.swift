import Foundation
import SwiftData

@Model
class UserSettings {
    var userName: String
    var userEmail: String
    var createdAt: Date
    
    init(userName: String = "サンプルユーザー", userEmail: String = "sample@example.com") {
        self.userName = userName
        self.userEmail = userEmail
        self.createdAt = Date()
    }
    
    // MARK: - Validation
    
    /// ユーザー名のバリデーション
    func validateUserName() -> ValidationResult {
        guard !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure("ユーザー名を入力してください")
        }
        
        guard userName.count >= 2 else {
            return .failure("ユーザー名は2文字以上で入力してください")
        }
        
        return .success
    }
    
    /// メールアドレスのバリデーション
    func validateEmail() -> ValidationResult {
        guard !userEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure("メールアドレスを入力してください")
        }
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        guard emailPredicate.evaluate(with: userEmail) else {
            return .failure("正しいメールアドレスの形式で入力してください")
        }
        
        return .success
    }
    
    /// すべての設定項目のバリデーション
    func validateAll() -> ValidationResult {
        // ユーザー名をチェック
        switch validateUserName() {
        case .failure(let message):
            return .failure(message)
        case .success:
            break
        }
        
        // メールアドレスをチェック
        switch validateEmail() {
        case .failure(let message):
            return .failure(message)
        case .success:
            break
        }
        
        return .success
    }
    
    // MARK: - Utility Methods
    
    /// 設定が有効かどうか
    var isValid: Bool {
        return validateAll().isSuccess
    }
    
    /// Git設定用の表示名
    var gitDisplayName: String {
        return "\(userName) <\(userEmail)>"
    }
    
    /// 設定の更新
    func updateSettings(userName: String, userEmail: String) -> ValidationResult {
        let trimmedUserName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUserEmail = userEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 一時的にコピーして検証
        let tempSettings = UserSettings(userName: trimmedUserName, userEmail: trimmedUserEmail)
        
        switch tempSettings.validateAll() {
        case .success:
            self.userName = trimmedUserName
            self.userEmail = trimmedUserEmail
            return .success
        case .failure(let message):
            return .failure(message)
        }
    }
    
    // MARK: - Git Configuration
    
    /// Git設定の更新（全リポジトリに適用）
    static func updateGitConfiguration(userName: String, userEmail: String, in managedFolderURL: URL, modelContext: ModelContext?) -> (success: Bool, message: String) {
        
        // まず新しい設定を検証
        let tempSettings = UserSettings(userName: userName, userEmail: userEmail)
        switch tempSettings.validateAll() {
        case .failure(let message):
            return (success: false, message: message)
        case .success:
            break
        }
        
        do {
            // 既存のGitリポジトリを検索
            let repositories = try findGitRepositories(in: managedFolderURL)
            
            // 各リポジトリのGit設定を更新
            var updatedCount = 0
            for repoURL in repositories {
                do {
                    try updateGitConfig(at: repoURL, userName: userName, userEmail: userEmail)
                    updatedCount += 1
                } catch {
                    print("⚠️ Failed to update git config at \(repoURL.path): \(error)")
                }
            }
            
            // UserSettingsを更新（モデルコンテキストがある場合）
            if let context = modelContext {
                if let existingSettings = try context.fetch(FetchDescriptor<UserSettings>()).first {
                    let result = existingSettings.updateSettings(userName: userName, userEmail: userEmail)
                    if result.isSuccess {
                        try context.save()
                    }
                } else {
                    let newSettings = UserSettings(userName: userName, userEmail: userEmail)
                    context.insert(newSettings)
                    try context.save()
                }
            }
            
            let message = updatedCount > 0 ? 
                "Git設定を更新しました（\(updatedCount)個のリポジトリ）" : 
                "設定を保存しました（既存のリポジトリはありません）"
            
            return (success: true, message: message)
            
        } catch {
            return (success: false, message: "Git設定更新エラー: \(error.localizedDescription)")
        }
    }
    
    /// Git設定ファイルを更新
    private static func updateGitConfig(at repositoryURL: URL, userName: String, userEmail: String) throws {
        let configPath = repositoryURL.appendingPathComponent(".git/config")
        let configContent = """
        [core]
        \trepositoryformatversion = 0
        \tbare = false
        \tignorecase = true
        \tprecomposeunicode = true

        [user]
        \tname = \(userName)
        \temail = \(userEmail)
        """
        try configContent.write(to: configPath, atomically: true, encoding: .utf8)
    }
    
    /// 管理フォルダ内のGitリポジトリを検索
    private static func findGitRepositories(in managedFolderURL: URL) throws -> [URL] {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: managedFolderURL.path) else {
            return []
        }
        
        let contents = try fileManager.contentsOfDirectory(at: managedFolderURL, includingPropertiesForKeys: nil)
        return contents.filter { url in
            let gitPath = url.appendingPathComponent(".git").path
            return fileManager.fileExists(atPath: gitPath)
        }
    }
}

// MARK: - Validation Result

enum ValidationResult {
    case success
    case failure(String)
    
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .success:
            return nil
        case .failure(let message):
            return message
        }
    }
}
