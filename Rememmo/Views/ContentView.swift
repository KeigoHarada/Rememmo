import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var memos: [Memo]
    @State private var showingAddSheet = false
    @State private var searchText = ""

    var filteredMemos: [Memo] {
        if searchText.isEmpty {
            return memos
        } else {
            return memos.filter { memo in
                memo.title.localizedStandardContains(searchText) || memo.content.localizedStandardContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 検索バー
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("メモを検索...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(8)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.all)

                List {
                    ForEach(filteredMemos) { memo in
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
                modelContext.delete(filteredMemos[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Memo.self, inMemory: true)
}
