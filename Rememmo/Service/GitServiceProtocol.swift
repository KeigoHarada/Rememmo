protocol GitServiceProtocol {
    func gitInit(log: inout String)
    func gitCommit(log: inout String)
}
