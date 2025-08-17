import Foundation
import SwiftData

@Model
class UserSettings {
    var userName: String
    var userEmail: String
    var createdAt: Date
    
    init(userName: String = "サンプルユーザー", userEmail: String = "sample@example.com") {
        self.userName = userName
        self.userEmail = userEmail
        self.createdAt = Date()
    }
}
