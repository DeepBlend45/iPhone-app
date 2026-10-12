import SwiftUI
import SwiftData

struct RecordView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var session = RecordingSession()
    @State private var mood = 3

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                moodPicker
                Spacer()
                content
                Spacer()
            }
            .padding()
            .themedBackground()
            .navigationTitle("いまの気持ち")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    private var moodPicker: some View {
        HStack(spacing: 12) {
            ForEach(1...5, id: \.self) { value in
                Button {
                    mood = value
                } label: {
                    Text(moodEmojis[value - 1])
                        .font(.system(size: 36))
                        .padding(8)
                        .background(Color.white.opacity(mood == value ? 0.35 : 0.12), in: .circle)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch session.phase {
        case .idle:
            bigButton("mic.fill", "話しはじめる") { Task { await session.start() } }
        case .recording:
            bigButton("stop.fill", "止めて文字にする") { Task { await session.stop() } }
        case .transcribing:
            ProgressView("文字に起こしています…")
        case .finished:
            VStack(spacing: 16) {
                Text("あとで履歴から修正できます").font(.footnote).foregroundStyle(.secondary)
                TextEditor(text: $session.transcript)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 160)
                    .padding(8)
                    .background(Color.white.opacity(0.18), in: .rect(cornerRadius: 12))
                bigButton("checkmark", "保存", action: save)
            }
        case .failed(let message):
            VStack(spacing: 16) {
                Text(message).foregroundStyle(.red)
                if session.audioFileName != nil {
                    bigButton("checkmark", "このまま保存", action: save)
                }
            }
        }
    }

    private func bigButton(_ icon: String, _ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.title2.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 24).padding(.vertical, 16)
                .background(Color.white.opacity(0.22), in: .rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private func save() {
        context.insert(JournalEntry(mood: mood, transcript: session.transcript, audioFileName: session.audioFileName))
        dismiss()
    }
}
