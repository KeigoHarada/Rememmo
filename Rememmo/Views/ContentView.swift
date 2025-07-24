import SwiftUI

struct Memo: Identifiable {
    let id = UUID()
    var title: String
    var content: String
    var createdAt: Date
}

struct ContentView: View {
    @State private var memos: [Memo] = []
    @State private var showingNewMemo = false
    @State private var selectedMemo: Memo?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(memos) { memo in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(memo.title)
                            .font(.headline)
                        Text(memo.content)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                        Text(memo.createdAt, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    .onTapGesture {
                        selectedMemo = memo
                    }
                }
                .onDelete { indexSet in
                    memos.remove(atOffsets: indexSet)
                }
            }
            .navigationTitle("メモ一覧")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("新規作成") {
                        showingNewMemo = true
                    }
                }
            }
            .sheet(isPresented: $showingNewMemo) {
                MemoEditView(memo: nil) { newMemo in
                    memos.append(newMemo)
                }
            }
            .sheet(item: $selectedMemo) { memo in
                MemoEditView(memo: memo) { updatedMemo in
                    if let index = memos.firstIndex(where: { $0.id == updatedMemo.id }) {
                        memos[index] = updatedMemo
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
