import SwiftUI

struct MemoDetailView: View {
    let memo: Memo
    let onUpdate: (Memo) -> Void
    
    @State private var showingEditView = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(memo.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(memo.content)
                    .font(.body)
                    .lineSpacing(4)
                
                Spacer()
                
                HStack {
                    Spacer()
                    Text("作成日: \(memo.createdAt, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("メモ詳細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("編集") {
                    showingEditView = true
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            MemoEditView(memo: memo) { updatedMemo in
                onUpdate(updatedMemo)
            }
        }
    }
}

struct MemoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MemoDetailView(
                memo: Memo(
                    title: "サンプルメモ",
                    content: "これはサンプルのメモ内容です。\n\n詳細画面で表示される内容を確認できます。",
                    createdAt: Date()
                ),
                onUpdate: { _ in }
            )
        }
    }
}
