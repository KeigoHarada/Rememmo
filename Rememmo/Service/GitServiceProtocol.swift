protocol GitServiceProtocol {
    func gitInit(repositoryPath: String, log: inout String)
    func gitCommit(repositoryPath: String, fileName: String, commitMessage: String, log: inout String)
}
