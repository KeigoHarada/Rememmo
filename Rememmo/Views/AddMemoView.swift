import SwiftUI
import SwiftData

struct AddMemoView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var title = ""
    @State private var content = ""
    
    private var gitService: MemoGitService {
        MemoGitService(modelContext: modelContext)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // タイトル入力
                TextField("タイトル", text: $title)
                    .font(.title2)
                    .padding()
                    .background(Color(.systemGray6))
                
                // 内容入力
                TextEditor(text: $content)
                    .padding()
                    .background(Color(.systemBackground))
            }
            .navigationTitle("新規メモ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveMemo()
                    }
                    .disabled(title.isEmpty && content.isEmpty)
                }
            }
        }
    }
    
    private func saveMemo() {
        let newMemo = Memo(title: title, content: content)
        modelContext.insert(newMemo)
        
        // 初回コミットを作成
        let commit = gitService.commit(memo: newMemo, message: "初回コミット")
        print("初回コミット作成: \(commit.commitMessage)")
        
        dismiss()
    }
}

#Preview {
    AddMemoView()
        .modelContainer(for: Memo.self, inMemory: true)
} 