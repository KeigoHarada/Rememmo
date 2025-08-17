protocol GitServiceProtocol {
    func gitInit(title: String, log: inout String)
    func gitCommit(log: inout String)
}
