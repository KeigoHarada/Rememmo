import Foundation  // 追加

// ファイル操作専用のプロトコル
protocol FileRepositoryProtocol {
    func save(content: String, to url: URL) throws
    func read(from url: URL) throws -> String
    func delete(at url: URL) throws
    func exists(at url: URL) -> Bool
}

// ファイル操作の実装
class FileRepository: FileRepositoryProtocol {
    private let fileManager: FileManager
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    func save(content: String, to url: URL) throws {
        try content.write(to: url, atomically: true, encoding: .utf8)
    }
        
    func read(from url: URL) throws -> String {
        return try String(contentsOf: url, encoding: .utf8)
    }
    
    func delete(at url: URL) throws {
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }
    
    func exists(at url: URL) -> Bool {
        return fileManager.fileExists(atPath: url.path)
    }
}
