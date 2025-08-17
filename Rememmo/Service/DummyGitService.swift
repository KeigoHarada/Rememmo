import SwiftData

struct DummyGitService: GitServiceProtocol {
    init(modelContext: ModelContext? = nil) {
        // プレビュー用なのでmodelContextは使用しない
    }
    
    func gitInit(repositoryPath: String, log: inout String) { 
        log += "[PREVIEW] Git Init(\(repositoryPath))は無効です\n" 
    }
    func gitCommit(repositoryPath: String, fileName: String, commitMessage: String, log: inout String) { 
        log += "[PREVIEW] Git Commit(\(fileName): \(commitMessage))は無効です\n" 
    }
    func gitLog(log: inout String) { log += "[PREVIEW] Git Logは無効です\n" }
    func gitDiff(log: inout String) { log += "[PREVIEW] Git Diffは無効です\n"}
}
