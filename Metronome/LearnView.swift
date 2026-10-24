import SwiftUI

struct LearnView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var player = GroovePlayer()

    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(Groove.library) { groove in
                        NavigationLink {
                            GrooveDetailView(groove: groove, player: player)
                        } label: {
                            HStack(spacing: 12) {
                                LevelBadge(level: groove.level)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(groove.title)
                                        .foregroundColor(Color(hex: "#DDDDDD"))
                                    Text(groove.focus)
                                        .font(.caption)
                                        .foregroundColor(Color(hex: "#DDDDDD").opacity(0.6))
                                        .lineLimit(2)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color(hex: "#242424"))
                    }
                } footer: {
                    Text("Funk grooves for building pocket, ghost notes and linear coordination. Start slow, speed up only when it feels effortless.")
                        .foregroundColor(Color(hex: "#DDDDDD").opacity(0.5))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(hex: "#1C1C1B"))
            .navigationTitle("Learn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "#DDDDDD"))
                }
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
        .onDisappear { player.stop() }
    }
}

private struct LevelBadge: View {
    let level: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(index <= level ? Color(hex: "#F54206") : Color(hex: "#DDDDDD").opacity(0.2))
                    .frame(width: 4, height: 6 + CGFloat(index) * 4)
            }
        }
        .frame(width: 20, height: 20, alignment: .bottom)
        .accessibilityLabel("Level \(level) of 3")
    }
}

struct GrooveDetailView: View {
    let groove: Groove
    @ObservedObject var player: GroovePlayer

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Text(groove.focus)
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "#DDDDDD").opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                DrumGrid(groove: groove, currentStep: player.isPlaying ? player.currentStep : -1)

                BPMControl(bpm: $player.tempo, range: 40...160)

                Picker("Click", selection: $player.clickInBackground) {
                    Text("Click in background").tag(true)
                    Text("Click off").tag(false)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    player.isPlaying ? player.stop() : player.play(groove)
                } label: {
                    Image(systemName: player.isPlaying ? "stop.fill" : "play.fill")
                        .font(.system(size: 30))
                        .foregroundColor(Color(hex: "#DDDDDD"))
                        .frame(width: 88, height: 88)
                        .background(Circle().fill(player.isPlaying ? Color(hex: "#F54206") : Color(hex: "#303030")))
                }
                .accessibilityLabel(player.isPlaying ? "Stop groove" : "Play groove")

                Legend()
            }
            .padding(.vertical, 24)
        }
        .background(Color(hex: "#1C1C1B").ignoresSafeArea())
        .navigationTitle(groove.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { player.tempo = Double(groove.tempo) }
        .onDisappear { player.stop() }
    }
}

// Drum notation as a grid: one row per voice, one column per sixteenth, counted 1 e & a
private struct DrumGrid: View {
    let groove: Groove
    let currentStep: Int

    private let counts = ["1", "e", "&", "a", "2", "e", "&", "a", "3", "e", "&", "a", "4", "e", "&", "a"]

    var body: some View {
        VStack(spacing: 6) {
            row(label: "") { step in
                Text(counts[step])
                    .font(.system(size: 11, weight: step % 4 == 0 ? .bold : .regular, design: .monospaced))
                    .foregroundColor(Color(hex: "#DDDDDD").opacity(step % 4 == 0 ? 0.9 : 0.45))
            }
            ForEach(DrumVoice.allCases, id: \.self) { voice in
                row(label: voice.label) { step in
                    NoteCell(hit: groove.hit(voice, at: step), voice: voice, isCurrent: step == currentStep)
                }
            }
        }
        .padding(.horizontal, 12)
    }

    private func row<Cell: View>(label: String, @ViewBuilder cell: @escaping (Int) -> Cell) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(Color(hex: "#DDDDDD").opacity(0.5))
                .frame(width: 26, alignment: .leading)
            ForEach(0..<Groove.steps, id: \.self) { step in
                cell(step)
                    .frame(maxWidth: .infinity)
                    .padding(.leading, step % 4 == 0 && step > 0 ? 4 : 0)
            }
        }
    }
}

private struct NoteCell: View {
    let hit: DrumHit?
    let voice: DrumVoice
    let isCurrent: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(isCurrent ? Color(hex: "#F54206").opacity(0.25) : Color(hex: "#242424"))
            symbol
        }
        .frame(height: 30)
        .padding(1)
    }

    @ViewBuilder
    private var symbol: some View {
        switch hit {
        case .none:
            EmptyView()
        case .ghost:
            Circle()
                .stroke(Color(hex: "#DDDDDD").opacity(0.7), lineWidth: 1)
                .frame(width: 8, height: 8)
        case .open:
            Circle()
                .stroke(Color(hex: "#F54206"), lineWidth: 1.5)
                .frame(width: 11, height: 11)
        case .accent:
            Circle()
                .fill(Color(hex: "#F54206"))
                .frame(width: 13, height: 13)
        case .normal:
            if voice == .hiHat {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(hex: "#DDDDDD"))
            } else {
                Circle()
                    .fill(Color(hex: "#DDDDDD"))
                    .frame(width: 11, height: 11)
            }
        }
    }
}

private struct Legend: View {
    var body: some View {
        HStack(spacing: 16) {
            item(Image(systemName: "xmark").font(.system(size: 9, weight: .bold)).foregroundColor(Color(hex: "#DDDDDD")), "Hit")
            item(Circle().fill(Color(hex: "#F54206")).frame(width: 10, height: 10), "Accent")
            item(Circle().stroke(Color(hex: "#DDDDDD").opacity(0.7), lineWidth: 1).frame(width: 8, height: 8), "Ghost")
            item(Circle().stroke(Color(hex: "#F54206"), lineWidth: 1.5).frame(width: 10, height: 10), "Open hat")
        }
        .font(.caption)
        .foregroundColor(Color(hex: "#DDDDDD").opacity(0.6))
    }

    private func item<Mark: View>(_ mark: Mark, _ text: String) -> some View {
        HStack(spacing: 6) {
            mark
            Text(text)
        }
    }
}
