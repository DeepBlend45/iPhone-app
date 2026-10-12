import SwiftUI
import SwiftData

/// お題の追加・編集・削除
struct PromptListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \PromptTemplate.createdAt) private var prompts: [PromptTemplate]
    @State private var newText = ""

    var body: some View {
        List {
            Section("新しいお題") {
                HStack {
                    TextField("例：今日いちばん笑ったことは？", text: $newText)
                    Button("追加", action: add)
                        .disabled(newText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .themedRow()
            }
            Section("お題の一覧（文字をタップして編集、左スワイプで削除）") {
                ForEach(prompts) { prompt in
                    PromptRow(prompt: prompt)
                }
                .onDelete { offsets in
                    offsets.forEach { context.delete(prompts[$0]) }
                }
            }
            Section {
                Button("消した初期のお題を戻す", systemImage: "arrow.counterclockwise") {
                    PromptStore.restoreDefaults(context, existing: prompts)
                }
                .themedRow()
            }
        }
        .scrollContentBackground(.hidden)
        .themedBackground()
        .navigationTitle("お題")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func add() {
        let text = newText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        context.insert(PromptTemplate(text: text))
        newText = ""
    }
}

private struct PromptRow: View {
    @Bindable var prompt: PromptTemplate

    var body: some View {
        TextField("お題", text: $prompt.text, axis: .vertical)
            .themedRow()
    }
}
