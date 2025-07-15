import Foundation
import SwiftData
import MiniGit

/// Git操作に関するエラー定義
enum GitError: Error, LocalizedError {
    case repositoryNotFound
    case initializationFailed
    case commitFailed
    
    var errorDescription: String? {
        switch self {
        case .repositoryNotFound:
            return "Gitリポジトリが見つかりません"
        case .initializationFailed:
            return "Gitリポジトリの初期化に失敗しました"
        case .commitFailed:
            return "Gitコミットに失敗しました"
        }
    }
}

// GitService用のプロトコル
protocol GitServiceProtocol {
    func initializeRepository( memo: Memo) throws
    func commit(memo: Memo, message: String) throws
}

/// メモのGit操作を管理するサービス
class GitService: ObservableObject, GitServiceProtocol {
    private let modelContext: ModelContext
    private let fileRepository: FileRepositoryProtocol
    private var repositories: [UUID: GitRepository] = [:]
    
    init(modelContext: ModelContext, fileRepository: FileRepositoryProtocol = FileRepository()) {
        self.modelContext = modelContext
        self.fileRepository = fileRepository
    }
    
    /// メモ用のGitリポジトリを初期化
    func initializeRepository(memo: Memo) throws {
        let repoURL = getMemoRepositoryURL(memoId: memo.id)
        
        // リポジトリが存在しない場合は初期化
        if !fileRepository.exists(at: repoURL) {
            try createRepository(at: repoURL)
        }
        
        // リポジトリを開く
        let credentialsManager = CredentialsManager(credentialsFileUrl: repoURL)
        let repository = GitRepository(repoURL, credentialsManager)
        repositories[memo.id] = repository
        
        print("Gitリポジトリを初期化しました: \(repoURL.path)")
    }
    
    /// メモの内容をGitリポジトリにコミット
    func commit(memo: Memo, message: String) throws {
            guard let repository = repositories[memo.id] else {
                throw GitError.repositoryNotFound
            }
            
            // メモの内容をファイルに保存
            try saveMemoToFile(memo: memo)
            
            // ファイルをステージングエリアに追加
            repository.stage(memo.title + ".md")
            
            // Gitコミットを作成
            repository.commit(message)
            memo.updatedAt = Date()
                        
            print("Gitコミットを作成しました: \(message)")
    }
    
    /// メモのリポジトリURLを取得
    private func getMemoRepositoryURL(memoId: UUID) -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent("memos/\(memoId.uuidString)")
    }
    
    /// 新しいリポジトリを作成
    private func createRepository(at url: URL) throws {
        let credentialsManager = CredentialsManager(credentialsFileUrl: url)
        let repository = GitRepository(url, credentialsManager)
        repository.create()
        print("新しいGitリポジトリを作成しました: \(url.path)")
    }
        
    /// メモの内容をファイルに保存
    private func saveMemoToFile(memo: Memo) throws {
        let repoURL = getMemoRepositoryURL(memoId: memo.id)
        let memoFileURL = repoURL.appendingPathComponent(memo.title + ".md")
        
        let content = createMemoContent(memo)
        
        // ファイル操作は専用のリポジトリに委譲
        try fileRepository.save(content: content, to: memoFileURL)
    }
    
    private func createMemoContent(_ memo: Memo) -> String {
        return """
        # \(memo.title)
        
        \(memo.content)
        
        ---
        作成日: \(memo.createdAt)
        更新日: \(memo.updatedAt)
        """
    }
    
    // コミットメッセージを自動生成
    func generateCommitMessage(oldTitle: String, oldContent: String, newTitle: String, newContent: String) -> String {
        let titleChanged = oldTitle != newTitle
        let contentChanged = oldContent != newContent
        
        if titleChanged && contentChanged {
            return "タイトルと内容を更新"
        } else if titleChanged {
            return "タイトルを更新"
        } else if contentChanged {
            return "内容を更新"
        } else {
            return "変更なし"
        }
    }
} 
