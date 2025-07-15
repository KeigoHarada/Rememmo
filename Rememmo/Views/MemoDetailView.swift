import SwiftUI
import SwiftData

struct MemoDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var memo: Memo
    @State private var isEditing = false
    @State private var editedTitle = ""
    @State private var editedContent = ""
    @State private var showingCommitHistory = false
    
    private var gitService: GitService {
        GitService(modelContext: modelContext)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isEditing {
                // 編集モード
                VStack(spacing: 0) {
                    TextField("タイトル", text: $editedTitle)
                        .font(.title2)
                        .padding()
                        .background(Color(.systemGray6))
                    
                    TextEditor(text: $editedContent)
                        .padding()
                        .background(Color(.systemBackground))
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("キャンセル") {
                            cancelEdit()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("保存") {
                            saveEdit()
                        }
                    }
                }
            } else {
                // 表示モード
                ScrollView {
                    VStack(spacing: 16) {
                        // メインコンテンツ（左寄せ）
                        VStack(alignment: .leading, spacing: 16) {
                            Text(memo.title.isEmpty ? "無題" : memo.title)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text(memo.content)
                                .font(.body)
                                .lineSpacing(4)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Spacer()
                        
                        // 日付情報（中央配置）
                        VStack(alignment: .center, spacing: 4) {
                            Text("作成日: \(memo.createdAt, format: .dateTime.day().month().year().hour().minute())")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("更新日: \(memo.updatedAt, format: .dateTime.day().month().year().hour().minute())")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                }
                .padding()
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button("編集") {
                                startEdit()
                            }
                            Button("コミット履歴") {
                                showingCommitHistory = true
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
        }
        .navigationTitle("メモ詳細")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func startEdit() {
        editedTitle = memo.title
        editedContent = memo.content
        isEditing = true
    }
    
    private func cancelEdit() {
        isEditing = false
    }
    
    private func saveEdit() {
        let oldTitle = memo.title
        let oldContent = memo.content
        
        memo.title = editedTitle
        memo.content = editedContent
        
        // 自動コミット
        let message = gitService.generateCommitMessage(
            oldTitle: oldTitle,
            oldContent: oldContent,
            newTitle: editedTitle,
            newContent: editedContent
        )
        
        try! gitService.commit(memo: memo, message: message)
        print("コミット作成")
        
        isEditing = false
    }
}

#Preview {
    NavigationView {
        MemoDetailView(memo: Memo(title: "サンプルメモ", content: "これはサンプルのメモ内容です。"))
    }
    .modelContainer(for: Memo.self, inMemory: true)
} 
