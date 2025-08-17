import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var memos: [Memo]
    @State private var showingNewMemo = false
    @State private var gitLog: String = ""
    
    private let gitService: GitServiceProtocol
    
    init(gitService: GitServiceProtocol = MiniGitService()) {
        self.gitService = gitService
        print("ContentView initialized with: \(type(of: gitService))")
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(memos) { memo in
                    NavigationLink(destination: MemoDetailView(memo: memo) { _ in }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(memo.title)
                                .font(.headline)
                            Text(memo.previewContent())
                                .font(.body)
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                            Text(memo.lastModifiedDate() ?? Date(), style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let memoToDelete = memos[index]
                        modelContext.delete(memoToDelete)
                    }
                    try? modelContext.save()
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
                MemoEditView(memo: nil) { tempMemo in
                    createNewMemo(title: tempMemo.title, content: tempMemo.content)
                }
            }
        }
    }
    
    /// 新しいメモを作成
    private func createNewMemo(title: String, content: String) {
        guard !title.isEmpty else { return }
        
        let appManagedFolderURL = getAppManagedFolderURL()
        
        // Memoのファクトリーメソッドを使用（初期コンテンツを指定）
        let result = Memo.createNew(title: title, initialContent: content, using: gitService, in: appManagedFolderURL)
        
        gitLog = result.log
        
        if let memo = result.memo {
            // SwiftDataに保存
            modelContext.insert(memo)
            try? modelContext.save()
            
            print("✅ Memo created successfully:")
            print("- Title: \(title)")
            print("- Repository: \(memo.repoUrl)")
            print("- ID: \(memo.id)")
        } else {
            print("❌ Failed to create memo:")
        }
        
        print("Creation Log:")
        print(gitLog)
    }
    
    /// アプリ管理フォルダのURLを取得
    private func getAppManagedFolderURL() -> URL {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsURL
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: UserSettings.self, Memo.self, configurations: config)
        
        // プレビュー用のダミーデータを挿入
        let context = container.mainContext
        context.insert(Memo(repoUrl: "/Documents/remmemo/サンプルメモ1"))
        context.insert(Memo(repoUrl: "/Documents/remmemo/サンプルメモ2"))
        context.insert(Memo(repoUrl: "/Documents/remmemo/重要なメモ"))
        
        // プレビューでもDummyGitServiceを使用
        return ContentView(gitService: DummyGitService())
            .modelContainer(container)
    }
}
