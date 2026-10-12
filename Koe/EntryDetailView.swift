import SwiftUI
import AVFoundation

struct EntryDetailView: View {
    @Bindable var entry: JournalEntry
    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false

    var body: some View {
        Form {
            Section {
                HStack {
                    Text(moodEmojis[entry.mood - 1]).font(.largeTitle)
                    Text(entry.createdAt.formatted(date: .complete, time: .shortened))
                        .font(.footnote).foregroundStyle(.secondary)
                }
                if let prompt = entry.prompt {
                    Label(prompt, systemImage: "text.bubble").font(.subheadline.bold())
                }
                if entry.audioFileName != nil {
                    Button(isPlaying ? "停止" : "声を聞く", systemImage: isPlaying ? "stop.fill" : "play.fill") {
                        togglePlayback()
                    }
                }
            }
            .themedRow()
            Section("文字起こし（聞きながら直せます）") {
                TextEditor(text: $entry.transcript)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 240)
            }
            .themedRow()
        }
        .scrollContentBackground(.hidden)
        .themedBackground()
        .navigationTitle("記録")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { player?.stop() }
    }

    private func togglePlayback() {
        if isPlaying {
            player?.stop()
            isPlaying = false
            return
        }
        guard let name = entry.audioFileName else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        player = try? AVAudioPlayer(contentsOf: AudioStore.url(for: name))
        player?.play()
        isPlaying = player != nil
    }
}
