import SwiftUI
import SwiftData

@main
struct RememmoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [UserSettings.self, Memo.self])
    }
}
