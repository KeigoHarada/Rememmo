import Foundation
import SwiftData

@Model
final class Memo {
    var id: UUID
    var title: String
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var currentCommitId: UUID?
    
    init(title: String, content: String) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
        self.currentCommitId = nil
    }
}
