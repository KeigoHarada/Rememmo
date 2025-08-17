import SwiftUI
import SwiftData

struct Memo: Identifiable {
    let id = UUID()
    var title: String
    var content: String
    var createdAt: Date
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var memos: [Memo] = []
    @State private var showingNewMemo = false
    @State private var gitLog: String = ""
    
    let gitService: GitServiceProtocol
    
    init(gitService: GitServiceProtocol = MiniGitService()) {
        self.gitService = gitService
        print("ContentView initialized with: \(type(of: gitService))")
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(memos) { memo in
                    NavigationLink(destination: MemoDetailView(memo: memo) { updatedMemo in
                        if let index = memos.firstIndex(where: { $0.id == updatedMemo.id }) {
                            memos[index] = updatedMemo
                        }
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(memo.title)
                                .font(.headline)
                            Text(memo.content)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                            Text(memo.createdAt, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete { indexSet in
                    memos.remove(atOffsets: indexSet)
                }
            }
            .navigationTitle("メモ一覧")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: UserSettingView()) {
                        Image(systemName: "person.circle")
                            .foregroundColor(.blue)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("新規作成") {
                        showingNewMemo = true
                    }
                }
            }
            .sheet(isPresented: $showingNewMemo) {
                MemoEditView(memo: nil) { newMemo in
                    // メモを追加
                    memos.append(newMemo)
                    
                    // 新しいメモ用のGitリポジトリを初期化
                    gitService.gitInit(title: newMemo.title, log: &gitLog)
                    
                    // デバッグ用ログを出力
                    print("Git Init Log for memo '\(newMemo.title)':")
                    print(gitLog)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(gitService: DummyGitService())
            .modelContainer(for: [UserSettings.self])
    }
}
