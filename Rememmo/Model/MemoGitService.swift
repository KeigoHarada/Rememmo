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

/// メモのGit操作を管理するサービス
/// Single Responsibility Principle: メモのGit操作のみに責任を持つ
class MemoGitService: ObservableObject {
    private let modelContext: ModelContext
    private var repositories: [UUID: GitRepository] = [:]
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Repository Management
    
    /// メモ用のGitリポジトリを初期化
    /// Open/Closed Principle: 拡張可能な設計
    func initializeRepository(for memo: Memo) throws {
        let repoURL = getMemoRepositoryURL(memoId: memo.id)
        
        // リポジトリが存在しない場合は初期化
        if !FileManager.default.fileExists(atPath: repoURL.path) {
            try createRepository(at: repoURL)
        }
        
        // リポジトリを開く
        let credentialsManager = CredentialsManager(credentialsFileUrl: repoURL)
        let repository = GitRepository(repoURL, credentialsManager)
        repositories[memo.id] = repository
        
        // リポジトリを開く（存在しない場合は初期化される）
        if !repository.hasRepo {
            try repository.open()
        }
        
        print("Gitリポジトリを初期化しました: \(repoURL.path)")
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
        try repository.create()
        print("新しいGitリポジトリを作成しました: \(url.path)")
    }
    
    // MARK: - Git Operations
    
    /// メモの内容をGitリポジトリにコミット
    /// Single Responsibility Principle: Git操作とSwiftData管理の統合
    func commit(memo: Memo, message: String) -> MemoCommit {
        do {
            // リポジトリが初期化されていない場合は初期化
            if repositories[memo.id] == nil {
                try initializeRepository(for: memo)
            }
            
            guard let repository = repositories[memo.id] else {
                throw GitError.repositoryNotFound
            }
            
            // メモの内容をファイルに保存
            try saveMemoToFile(memo: memo)
            
            // ファイルをステージングエリアに追加
            repository.stage("memo.md")
            
            // Gitコミットを作成
            repository.commit(message)
            
            // SwiftDataにもコミット情報を保存
            let commit = MemoCommit(
                memoId: memo.id,
                title: memo.title,
                content: memo.content,
                commitMessage: message,
                parentCommitId: memo.currentCommitId
            )
            
            memo.currentCommitId = commit.id
            memo.updatedAt = Date()
            
            modelContext.insert(commit)
            
            print("Gitコミットを作成しました: \(message)")
            return commit
            
        } catch {
            print("Gitコミットエラー: \(error)")
            // エラーが発生した場合は従来のSwiftDataのみのコミット
            return createSwiftDataCommit(memo: memo, message: message)
        }
    }
    
    /// メモの内容をファイルに保存
    private func saveMemoToFile(memo: Memo) throws {
        let repoURL = getMemoRepositoryURL(memoId: memo.id)
        let memoFileURL = repoURL.appendingPathComponent("memo.md")
        
        let content = """
        # \(memo.title)
        
        \(memo.content)
        
        ---
        作成日: \(memo.createdAt)
        更新日: \(memo.updatedAt)
        """
        
        try content.write(to: memoFileURL, atomically: true, encoding: .utf8)
    }
    
    /// SwiftDataのみのコミット（フォールバック）
    private func createSwiftDataCommit(memo: Memo, message: String) -> MemoCommit {
        let commit = MemoCommit(
            memoId: memo.id,
            title: memo.title,
            content: memo.content,
            commitMessage: message,
            parentCommitId: memo.currentCommitId
        )
        
        memo.currentCommitId = commit.id
        memo.updatedAt = Date()
        
        modelContext.insert(commit)
        return commit
    }
    
    /// Gitコミット履歴を取得（SwiftDataとGitの統合）
    func getCommitHistory(memoId: UUID) -> [MemoCommit] {
        // まずSwiftDataから取得
        let swiftDataCommits = getSwiftDataCommitHistory(memoId: memoId)
        
        // Gitリポジトリが利用可能な場合はGit履歴も取得
        if let repository = repositories[memoId] {
            repository.log(repository.commitGraph)
        }
        
        return swiftDataCommits
    }
    
    /// SwiftDataからコミット履歴を取得
    private func getSwiftDataCommitHistory(memoId: UUID) -> [MemoCommit] {
        let descriptor = FetchDescriptor<MemoCommit>(
            predicate: #Predicate<MemoCommit> { commit in
                commit.memoId == memoId
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("SwiftDataコミット履歴の取得エラー: \(error)")
            return []
        }
    }
    
    // 最新のコミットを取得
    func getLatestCommit(memoId: UUID) -> MemoCommit? {
        let commits = getCommitHistory(memoId: memoId)
        return commits.first
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
    
    /// コミットから復元（Git対応）
    func restoreFromCommit(memo: Memo, commit: MemoCommit) -> MemoCommit {
        do {
            // 現在の状態をGitにコミット
            let currentCommit = self.commit(memo: memo, message: "復元前の状態を保存")
            
            // コミットの内容で復元
            memo.title = commit.title
            memo.content = commit.content
            memo.updatedAt = Date()
            
            // 復元コミットを作成
            let restoreCommit = MemoCommit(
                memoId: memo.id,
                title: memo.title,
                content: memo.content,
                commitMessage: "コミット「\(commit.commitMessage)」から復元",
                parentCommitId: currentCommit.id
            )
            
            memo.currentCommitId = restoreCommit.id
            modelContext.insert(restoreCommit)
            
            // Gitにも復元をコミット
            if let repository = repositories[memo.id] {
                try saveMemoToFile(memo: memo)
                repository.stage("memo.md")
                repository.commit("コミット「\(commit.commitMessage)」から復元")
            }
            
            return restoreCommit
            
        } catch {
            print("Git復元エラー: \(error)")
            // エラーが発生した場合は従来のSwiftDataのみの復元
            return createSwiftDataRestore(memo: memo, commit: commit)
        }
    }
    
    /// SwiftDataのみの復元（フォールバック）
    private func createSwiftDataRestore(memo: Memo, commit: MemoCommit) -> MemoCommit {
        // 現在の状態を保存
        let currentCommit = createSwiftDataCommit(memo: memo, message: "復元前の状態を保存")
        
        // コミットの内容で復元
        memo.title = commit.title
        memo.content = commit.content
        memo.updatedAt = Date()
        
        // 復元コミットを作成
        let restoreCommit = MemoCommit(
            memoId: memo.id,
            title: memo.title,
            content: memo.content,
            commitMessage: "コミット「\(commit.commitMessage)」から復元",
            parentCommitId: currentCommit.id
        )
        
        memo.currentCommitId = restoreCommit.id
        modelContext.insert(restoreCommit)
        
        return restoreCommit
    }
} 
