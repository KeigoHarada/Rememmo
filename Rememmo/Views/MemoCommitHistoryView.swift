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
                        NavigationLink(destination: MemoCommitPreviewView(
                            commit: commit,
                            memo: memo,
                            gitService: gitService
                        )
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)) {
                            CommitHistoryRow(commit: commit)
                        }
                    }
                }
            }
            .navigationTitle("コミット履歴")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            commits = gitService.getCommitHistory(memoId: memo.id)
        }
    }
}

struct CommitHistoryRow: View {
    let commit: MemoCommit
    
    var body: some View {
        HStack(spacing: 12) {
            // コミットアイコン
            VStack {
                Image(systemName: "circle.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.blue)
                
                if commit.branchName != "main" {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 2, height: 20)
                }
            }
            .frame(width: 20)
            
            // コミット情報
            VStack(alignment: .leading, spacing: 6) {
                Text(commit.commitMessage)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                HStack {
                    Text(commit.timestamp, format: .dateTime.day().month().year().hour().minute())
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if commit.branchName != "main" {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(commit.branchName)
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                // プレビューテキスト
                Text(commit.title.isEmpty ? commit.content : commit.title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
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
