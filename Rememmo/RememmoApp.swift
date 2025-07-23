import SwiftUI

@main
struct RememmoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(
                gitService: RealGitService()
            ) // 本番はRealGitService()に切り替え
        }
    }
}
