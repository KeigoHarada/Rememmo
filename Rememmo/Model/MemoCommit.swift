import Foundation
import SwiftData

@Model
final class MemoCommit {
    var id: UUID
    var memoId: UUID
    var title: String
    var content: String
    var commitMessage: String
    var timestamp: Date
    var parentCommitId: UUID?
    var branchName: String
    
    init(memoId: UUID, title: String, content: String, commitMessage: String, parentCommitId: UUID? = nil, branchName: String = "main") {
        self.id = UUID()
        self.memoId = memoId
        self.title = title
        self.content = content
        self.commitMessage = commitMessage
        self.timestamp = Date()
        self.parentCommitId = parentCommitId
        self.branchName = branchName
    }
} 