import SwiftUI
import SwiftData

struct AddMemoView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var title = ""
    @State private var content = ""
    
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
        dismiss()
    }
}

#Preview {
    AddMemoView()
        .modelContainer(for: Memo.self, inMemory: true)
} 