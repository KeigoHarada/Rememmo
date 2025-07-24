import SwiftUI

struct MemoEditView: View {
    let memo: Memo?
    let onSave: (Memo) -> Void
    
    @State private var title: String = ""
    @State private var content: String = ""
    @Environment(\.dismiss) private var dismiss
    
    init(memo: Memo?, onSave: @escaping (Memo) -> Void) {
        self.memo = memo
        self.onSave = onSave
        
        if let memo = memo {
            _title = State(initialValue: memo.title)
            _content = State(initialValue: memo.content)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("タイトル")
                        .font(.headline)
                    TextField("タイトルを入力", text: $title)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("内容")
                        .font(.headline)
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                        .padding(4)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle(memo == nil ? "新規メモ" : "メモ編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if !trimmedTitle.isEmpty {
                            let newMemo = Memo(
                                title: trimmedTitle,
                                content: trimmedContent,
                                createdAt: memo?.createdAt ?? Date()
                            )
                            onSave(newMemo)
                            dismiss()
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct MemoEditView_Previews: PreviewProvider {
    static var previews: some View {
        MemoEditView(memo: nil) { _ in }
    }
} 