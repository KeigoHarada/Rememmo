import SwiftUI

struct MemoDetailView: View {
    let memo: Memo
    let onUpdate: (Memo) -> Void
    
    @State private var showingEditView = false
    @State private var showingCommitDialog = false
    @State private var commitMessage = ""
    @State private var gitLog = ""
    @State private var showingGitLog = false
    
    private let gitService: GitServiceProtocol
    
    init(memo: Memo, gitService: GitServiceProtocol = MiniGitService(), onUpdate: @escaping (Memo) -> Void) {
        self.memo = memo
        self.gitService = gitService
        self.onUpdate = onUpdate
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(URL(fileURLWithPath: memo.repoUrl).lastPathComponent)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("リポジトリパス: \(memo.repoUrl)")
                    .font(.body)
                    .lineSpacing(4)
                
                Text("メモID: \(memo.id.uuidString)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack {
                    Spacer()
                    Text("作成日: \(Date(), style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("メモ詳細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Git Log") {
                    showingGitLog = true
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button("Commit") {
                        showingCommitDialog = true
                    }
                    Button("編集") {
                        showingEditView = true
                    }
                }
            }
        })
        .sheet(isPresented: $showingEditView) {
            // 現在の設計では編集機能は簡略化
            Text("編集機能は今後実装予定")
        }
        .alert("Git Commit", isPresented: $showingCommitDialog) {
            TextField("コミットメッセージ", text: $commitMessage)
            Button("Commit") {
                performCommit()
            }
            Button("キャンセル", role: .cancel) {
                commitMessage = ""
            }
        } message: {
            Text("変更をコミットしますか？")
        }
        .alert("Git Log", isPresented: $showingGitLog) {
            Button("OK") { }
        } message: {
            Text(gitLog.isEmpty ? "Gitログがありません" : gitLog)
        }
    }
    
    /// コミットを実行
    private func performCommit() {
        let result = memo.commitChanges(commitMessage: commitMessage, using: gitService)
        gitLog = result.log
        
        print("Commit result: \(result.success)")
        print("Commit log: \(result.log)")
        
        // コミット後、ログを表示
        showingGitLog = true
        commitMessage = ""
    }
}

struct MemoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MemoDetailView(
                memo: Memo(repoUrl: "/Documents/remmemo/サンプルメモ"),
                onUpdate: { _ in }
            )
        }
    }
}
