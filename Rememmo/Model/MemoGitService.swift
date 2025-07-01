import Foundation
import SwiftData

class MemoGitService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // コミットを作成
    func commit(memo: Memo, message: String) -> MemoCommit {
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
    
    // コミット履歴を取得
    func getCommitHistory(memoId: UUID) -> [MemoCommit] {
        let descriptor = FetchDescriptor<MemoCommit>(
            predicate: #Predicate<MemoCommit> { commit in
                commit.memoId == memoId
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("コミット履歴の取得エラー: \(error)")
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
    
    // コミットから復元
    func restoreFromCommit(memo: Memo, commit: MemoCommit) -> MemoCommit {
        // 現在の状態を保存
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
        
        return restoreCommit
    }
} 
