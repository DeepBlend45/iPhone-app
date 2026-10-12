import SwiftUI
import SwiftData

struct RecordView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// 記録する日。カレンダーの日付から開いたときは、その日付で保存する
    var day: Date = .now

    @Query(sort: \PromptTemplate.createdAt) private var prompts: [PromptTemplate]
    @State private var currentPrompt: String?
    @State private var usePrompt = true

    @State private var session = RecordingSession()
    @State private var mood = 3

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                moodPicker
                promptCard
                Spacer()
                content
                Spacer()
            }
            .padding()
            .themedBackground()
            .onAppear(perform: shufflePrompt)
            .onChange(of: prompts.count) { if currentPrompt == nil { shufflePrompt() } }
            .navigationTitle(isToday ? "いまの気持ち" : day.formatted(date: .abbreviated, time: .omitted) + "の記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        PromptListView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("お題の設定")
                }
            }
        }
    }

    /// 何を話すか迷ったときのお題。使わずに自由に話してもよい
    @ViewBuilder
    private var promptCard: some View {
        if usePrompt {
            VStack(spacing: 8) {
                HStack {
                    Label("お題", systemImage: "text.bubble").font(.caption.bold())
                    Spacer()
                    Button("お題を使わない", systemImage: "xmark") { usePrompt = false }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.plain)
                }
                Text(currentPrompt ?? "お題がありません。右上の歯車から追加できます")
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                if session.phase == .idle {
                    Button("別のお題", systemImage: "shuffle", action: shufflePrompt)
                        .font(.footnote.bold())
                        .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.18), in: .rect(cornerRadius: 16))
        } else {
            Button("お題を表示", systemImage: "text.bubble") { usePrompt = true }
                .font(.footnote)
                .buttonStyle(.plain)
        }
    }

    private func shufflePrompt() {
        let candidates = prompts.map(\.text).filter { $0 != currentPrompt }
        currentPrompt = candidates.randomElement() ?? prompts.first?.text
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

    private var isToday: Bool { Calendar.current.isDateInToday(day) }

    /// 今日なら現在時刻、過去の日なら「その日の、いまと同じ時刻」にする
    private var createdAt: Date {
        guard !isToday else { return .now }
        let cal = Calendar.current
        let time = cal.dateComponents([.hour, .minute, .second], from: .now)
        return cal.date(bySettingHour: time.hour ?? 12, minute: time.minute ?? 0, second: time.second ?? 0, of: day) ?? day
    }

    private func save() {
        context.insert(JournalEntry(createdAt: createdAt, mood: mood, transcript: session.transcript, audioFileName: session.audioFileName,
                                    prompt: usePrompt ? currentPrompt : nil))
        dismiss()
    }
}
