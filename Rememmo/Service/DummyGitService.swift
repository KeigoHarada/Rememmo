struct DummyGitService: GitServiceProtocol {
    func fileTest(log: inout String) { log += "[PREVIEW] ファイルテストは無効です\n" }
    func gitInit(log: inout String) { log += "[PREVIEW] Git Initは無効です\n" }
    func gitCommit(log: inout String) { log += "[PREVIEW] Git Commitは無効です\n" }
}
