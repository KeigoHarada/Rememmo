import Foundation
import SwiftData

@Model
class Memo: Identifiable {
    var id: UUID
    var repoUrl: String
    
    init(id: UUID = UUID(), repoUrl: String) {
        self.id = id
        self.repoUrl = repoUrl
    }
    
    // MARK: - Computed Properties
    
    /// メモのタイトル（ディレクトリ名から取得）
    var title: String {
        return URL(fileURLWithPath: repoUrl).lastPathComponent
    }
    
    /// リポジトリのURL
    var repositoryURL: URL {
        return URL(fileURLWithPath: repoUrl)
    }
    
    /// マークダウンファイルのURL
    var markdownFileURL: URL {
        return repositoryURL.appendingPathComponent("\(title).md")
    }
    
    // MARK: - File Operations
    
    /// マークダウンファイルが存在するかチェック
    func markdownFileExists() -> Bool {
        return FileManager.default.fileExists(atPath: markdownFileURL.path)
    }
    
    /// マークダウンファイルの内容を読み取り
    func readMarkdownContent() throws -> String {
        return try String(contentsOf: markdownFileURL, encoding: .utf8)
    }
    
    /// マークダウンファイルに内容を書き込み
    func writeMarkdownContent(_ content: String) throws {
        try content.write(to: markdownFileURL, atomically: true, encoding: .utf8)
    }
    
    /// ファイルの最終更新日時を取得
    func lastModifiedDate() -> Date? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: markdownFileURL.path)
            return attributes[.modificationDate] as? Date
        } catch {
            return nil
        }
    }
    
    /// プレビュー用の短い内容を取得（最初の3行）
    func previewContent() -> String {
        do {
            let content = try readMarkdownContent()
            let lines = content.components(separatedBy: .newlines)
            let previewLines = lines.prefix(3).joined(separator: "\n")
            return previewLines.isEmpty ? "（内容なし）" : previewLines
        } catch {
            return "ファイル読み取りエラー"
        }
    }
    
    /// マークダウンファイルの完全な内容を取得（編集用）
    func fullContent() -> String {
        do {
            return try readMarkdownContent()
        } catch {
            return ""
        }
    }
    
    // MARK: - Validation
    
    /// リポジトリのパスが有効かチェック
    func isValidRepository() -> Bool {
        let gitPath = repositoryURL.appendingPathComponent(".git").path
        return FileManager.default.fileExists(atPath: gitPath)
    }
    
    // MARK: - Git Operations
    
    /// メモの内容をコミット
    func commitChanges(commitMessage: String = "", using gitService: GitServiceProtocol) -> (success: Bool, log: String) {
        var log = ""
        gitService.gitCommit(repositoryPath: repoUrl, commitMessage: commitMessage, log: &log)
        
        // ログから成功/失敗を判定
        let success = log.contains("✅ コミット成功") && !log.contains("❌")
        return (success: success, log: log)
    }
    
    /// メモの内容を更新してコミット
    func updateAndCommit(content: String, commitMessage: String = "", using gitService: GitServiceProtocol) -> (success: Bool, log: String) {
        do {
            // マークダウンファイルに内容を書き込み
            try writeMarkdownContent(content)
            
            // 変更をコミット
            let finalMessage = commitMessage.isEmpty ? "メモを更新: \(title)" : commitMessage
            return commitChanges(commitMessage: finalMessage, using: gitService)
        } catch {
            return (success: false, log: "❌ ファイル書き込みエラー: \(error.localizedDescription)\n")
        }
    }
    
    // MARK: - Factory Methods
    
    /// 新しいメモを作成（GitServiceを使用してリポジトリ初期化）
    static func createNew(title: String, initialContent: String = "", using gitService: GitServiceProtocol, in managedFolderURL: URL) -> (memo: Memo?, log: String) {
        var log = ""
        
        do {
            // リポジトリパスを生成
            let repositoryURL = managedFolderURL.appendingPathComponent(title)
            
            // Gitリポジトリを初期化
            gitService.gitInit(repositoryPath: repositoryURL.path, log: &log)
            
            // Memoインスタンスを作成
            let memo = Memo(repoUrl: repositoryURL.path)
            
            // 初期マークダウンファイルを作成
            let defaultContent = initialContent.isEmpty ? """
            # \(title)
            
            ここにメモの内容を記述してください。
            
            作成日: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))
            """ : initialContent
            
            try memo.writeMarkdownContent(defaultContent)
            
            // 初期コミット
            let commitResult = memo.commitChanges(commitMessage: "first-commit: \(title)", using: gitService)
            log += commitResult.log
            
            let success = log.contains("✅ リポジトリ作成成功") && commitResult.success
            return (memo: success ? memo : nil, log: log)
        } catch {
            log += "❌ メモ作成エラー: \(error.localizedDescription)\n"
            return (memo: nil, log: log)
        }
    }
}
