import SwiftUI
import SwiftData

struct MemoCommitHistoryView: View {
    let memo: Memo
    let gitService: MemoGitService
    @State private var commits: [MemoCommit] = []
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                if commits.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("まだコミットがありません")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("メモを編集すると自動的にコミットが作成されます")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(commits, id: \.id) { commit in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(commit.commitMessage)
                                .font(.headline)
                            
                            Text(commit.timestamp, format: .dateTime.day().month().year().hour().minute())
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if commit.branchName != "main" {
                                Text("ブランチ: \(commit.branchName)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("コミット履歴")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            commits = gitService.getCommitHistory(memoId: memo.id)
        }
    }
}

#Preview {
    let schema = Schema([Memo.self, MemoCommit.self])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    
    do {
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        let context = ModelContext(container)
        
        // サンプルメモを作成
        let memo = Memo(title: "サンプルメモ", content: "これはサンプルのメモ内容です。")
        context.insert(memo)
        
        // サンプルコミットを作成
        let gitService = MemoGitService(modelContext: context)
        let commit1 = gitService.commit(memo: memo, message: "初回コミット")
        let commit2 = gitService.commit(memo: memo, message: "内容を更新")
        
        return MemoCommitHistoryView(memo: memo, gitService: gitService)
    } catch {
        return Text("Preview Error: \(error.localizedDescription)")
    }
} 
