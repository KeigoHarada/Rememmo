import SwiftUI
import SwiftData

struct MemoCommitPreviewView: View {
    let commit: MemoCommit
    let memo: Memo
    let gitService: MemoGitService
    @Environment(\.dismiss) private var dismiss
    @State private var showingRestoreAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // コミット情報カード
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.blue)
                            Text("コミット情報")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("メッセージ:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            Text(commit.commitMessage)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(6)
                            
                            HStack {
                                Text("日時:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(commit.timestamp, format: .dateTime.day().month().year().hour().minute())
                                    .font(.subheadline)
                            }
                            
                            if commit.branchName != "main" {
                                HStack {
                                    Text("ブランチ:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(commit.branchName)
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // メモ内容（シンプル表示）
                    VStack(alignment: .leading, spacing: 16) {
                        Text(commit.title.isEmpty ? "無題" : commit.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(commit.content)
                            .font(.body)
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("コミットプレビュー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("この状態に復元") {
                        showingRestoreAlert = true
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .alert("この状態に復元しますか？", isPresented: $showingRestoreAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("復元", role: .destructive) {
                restoreToCommit()
            }
        } message: {
            Text("現在の内容は失われ、このコミットの状態に戻ります。")
        }
    }
    
    private func restoreToCommit() {
        let restoreCommit = gitService.restoreFromCommit(memo: memo, commit: commit)
        print("復元完了: \(restoreCommit.commitMessage)")
        dismiss()
    }
}

#Preview {
    let commit = MemoCommit(
        memoId: UUID(),
        title: "サンプルメモ",
        content: "これは過去のバージョンのメモ内容です。\n\n複数行の内容も表示されます。",
        commitMessage: "内容を更新",
        branchName: "main"
    )
    
    let memo = Memo(title: "現在のメモ", content: "現在の内容")
    
    MemoCommitPreviewView(
        commit: commit,
        memo: memo,
        gitService: MemoGitService(modelContext: ModelContext(try! ModelContainer(for: Memo.self)))
    )
} 