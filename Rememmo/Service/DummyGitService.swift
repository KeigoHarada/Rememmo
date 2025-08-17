import SwiftData

struct DummyGitService: GitServiceProtocol {
    init(modelContext: ModelContext? = nil) {
        // プレビュー用なのでmodelContextは使用しない
    }
    
    func gitInit(title: String, log: inout String) { log += "[PREVIEW] Git Init(\(title))は無効です\n" }
    func gitCommit(log: inout String) { log += "[PREVIEW] Git Commitは無効です\n" }
    func gitLog(log: inout String) { log += "[PREVIEW] Git Logは無効です\n" }
    func gitDiff(log: inout String) { log += "[PREVIEW] Git Diffは無効です\n"}
}
