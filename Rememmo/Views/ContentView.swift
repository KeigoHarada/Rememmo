import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var memos: [Memo]
    @State private var showingAddSheet = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                List {
                    ForEach(memos) { memo in
                        NavigationLink(destination: MemoDetailView(memo: memo)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(memo.title.isEmpty ? "無題" : memo.title)
                                    .font(.headline)
                                    .lineLimit(1)
                                Text(memo.content)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                                Text(memo.updatedAt, format: .dateTime.day().month().year())
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete(perform: deleteMemos)
                }
            }
            .navigationTitle("メモ")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddMemoView()
            }
        }
    }

    private func deleteMemos(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(memos[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Memo.self, inMemory: true)
}
