protocol GitServiceProtocol {
    func fileTest(log: inout String)
    func gitInit(log: inout String)
    func gitCommit(log: inout String)
}
