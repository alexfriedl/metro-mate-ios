import SwiftUI

// Level 1: categories, each opens its own sheet with the grooves
struct LearnView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var player = GroovePlayer()
    @State private var category: GrooveCategory?

    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(GrooveCategory.allCases) { item in
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            category = item
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: item.symbol)
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(Color.textPrimary)
                                    .frame(width: 36, height: 36)
                                    .background(Circle().fill(Color.surfaceRaised))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .foregroundColor(Color.textPrimary)
                                    Text(item.subtitle)
                                        .font(.caption)
                                        .foregroundColor(Color.textSecondary)
                                        .lineLimit(2)
                                }
                                Spacer()
                                Text("\(item.grooves.count)")
                                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                                    .foregroundColor(Color.textSecondary)
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.surface)
                    }
                } footer: {
                    Text("\(Groove.library.count) grooves and exercises. Start slow, speed up only when it feels effortless.")
                        .foregroundColor(Color.textSecondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.ground)
            .navigationTitle("Learn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color.textPrimary)
                }
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
        .sheet(item: $category) { item in
            GrooveListView(category: item, player: player)
        }
        .onDisappear { player.stop() }
    }
}

// Level 2: all grooves of one category grouped by level, each opens the player sheet
struct GrooveListView: View {
    let category: GrooveCategory
    @ObservedObject var player: GroovePlayer
    @Environment(\.dismiss) private var dismiss
    @State private var selected: Groove?

    var body: some View {
        NavigationView {
            List {
                ForEach(1...3, id: \.self) { level in
                    let grooves = category.grooves.filter { $0.level == level }
                    if !grooves.isEmpty {
                        Section(header: Text(["Beginner", "Intermediate", "Advanced"][level - 1])) {
                            ForEach(grooves) { groove in
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    selected = groove
                                } label: {
                                    HStack(spacing: 12) {
                                        LevelBadge(level: groove.level)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(groove.title)
                                                .foregroundColor(Color.textPrimary)
                                            Text(groove.focus)
                                                .font(.caption)
                                                .foregroundColor(Color.textSecondary)
                                                .lineLimit(2)
                                        }
                                        Spacer()
                                        Text("\(groove.tempo)")
                                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                                            .foregroundColor(Color.textSecondary)
                                    }
                                    .padding(.vertical, 4)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .listRowBackground(Color.surface)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.ground)
            .navigationTitle(category.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color.textPrimary)
                }
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
        .sheet(item: $selected, onDismiss: { player.stop() }) { groove in
            NavigationView {
                GroovePager(category: category, player: player,
                            index: category.grooves.firstIndex { $0.id == groove.id } ?? 0)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { selected = nil }
                                .foregroundColor(Color.textPrimary)
                        }
                    }
            }
            .navigationViewStyle(.stack)
            .preferredColorScheme(.dark)
        }
    }
}

private struct LevelBadge: View {
    let level: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(index <= level ? Color.signal : Color.textPrimary.opacity(0.2))
                    .frame(width: 4, height: 6 + CGFloat(index) * 4)
            }
        }
        .frame(width: 20, height: 20, alignment: .bottom)
        .accessibilityLabel("Level \(level) of 3")
    }
}

// Level 3: one groove at a time, swipe or step through the whole category without leaving the player
struct GroovePager: View {
    @State var category: GrooveCategory
    @ObservedObject var player: GroovePlayer
    @State var index: Int
    @State private var direction = 1
    @State private var dragOffset: CGFloat = 0

    private var grooves: [Groove] { category.grooves }
    private var groove: Groove { grooves[index] }
    private let levels = ["Beginner", "Intermediate", "Advanced"]

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                header

                // The notation follows the finger while swiping and slides out in the swipe direction
                VStack(spacing: 16) {
                    Text(groove.focus)
                        .font(.subheadline)
                        .foregroundColor(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 24)
                    DrumGrid(groove: groove, currentStep: player.isPlaying ? player.currentStep : -1)
                }
                .frame(minHeight: 190, alignment: .top)
                .id(groove.id)
                .transition(.asymmetric(
                    insertion: .move(edge: direction > 0 ? .trailing : .leading).combined(with: .opacity),
                    removal: .move(edge: direction > 0 ? .leading : .trailing).combined(with: .opacity)
                ))
                .offset(x: dragOffset)

                BPMControl(bpm: $player.tempo, range: 10...240)

                HStack(spacing: 28) {
                    StepButton(symbol: "backward.fill", label: "Previous groove", enabled: index > 0) { step(-1) }

                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        player.isPlaying ? player.stop() : player.play(groove)
                    } label: {
                        Image(systemName: player.isPlaying ? "stop.fill" : "play.fill")
                            .font(.system(size: 30))
                            .foregroundColor(player.isPlaying ? Color.onSignal : Color.textPrimary)
                            .frame(width: 88, height: 88)
                            .background(Circle().fill(player.isPlaying ? Color.signal : Color.surfaceRaised))
                    }
                    .accessibilityLabel(player.isPlaying ? "Stop groove" : "Play groove")

                    StepButton(symbol: "forward.fill", label: "Next groove", enabled: index < grooves.count - 1) { step(1) }
                }

                Legend()
            }
            .padding(.vertical, 16)
        }
        .background(Color.ground.ignoresSafeArea())
        .clipped()
        // Swipe anywhere in the sheet, horizontal only so the tempo wheel and scrolling keep working
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    let horizontal = value.translation.width
                    guard abs(horizontal) > abs(value.translation.height) * 1.3 else { return }
                    let atEdge = (horizontal > 0 && index == 0) || (horizontal < 0 && index == grooves.count - 1)
                    dragOffset = atEdge ? horizontal * 0.25 : horizontal * 0.6
                }
                .onEnded { value in
                    let horizontal = value.translation.width
                    let predicted = value.predictedEndTranslation.width
                    let isSwipe = abs(horizontal) > abs(value.translation.height) * 1.3 && (abs(horizontal) > 70 || abs(predicted) > 160)
                    if isSwipe {
                        dragOffset = 0
                        step(horizontal < 0 ? 1 : -1)
                    } else {
                        withAnimation(.interpolatingSpring(stiffness: 300, damping: 26)) { dragOffset = 0 }
                    }
                }
        )
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { player.tempo = savedTempo(for: groove) }
        .onDisappear { player.stop() }
        .onChange(of: player.tempo) { tempo in
            // Remember the tempo you practise each groove at
            var tempos = UserDefaults.standard.dictionary(forKey: "grooveTempos") as? [String: Double] ?? [:]
            tempos[groove.id] = tempo
            UserDefaults.standard.set(tempos, forKey: "grooveTempos")
        }
        .onChange(of: index) { _ in
            UISelectionFeedbackGenerator().selectionChanged()
            player.tempo = savedTempo(for: groove)
            // Keep the music going, the next groove picks up straight away
            if player.isPlaying { player.play(groove) }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack {
                // Jump to another category straight from the player
                Menu {
                    ForEach(GrooveCategory.allCases) { item in
                        Button {
                            switchCategory(to: item)
                        } label: {
                            Label(item.title, systemImage: item == category ? "checkmark" : item.symbol)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: category.symbol)
                            .foregroundColor(Color.signal)
                        Text(category.title.uppercased())
                            .foregroundColor(Color.textPrimary)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color.signal)
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.signal.opacity(0.12)))
                }
                .accessibilityLabel("Category \(category.title), change category")
                Spacer()
                Text("\(index + 1) of \(grooves.count)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.textSecondary)
            }

            Text(groove.title)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .id(groove.id)
                .transition(.opacity)

            HStack(spacing: 8) {
                LevelBadge(level: groove.level)
                Text("\(levels[groove.level - 1]) · \(groove.tempo) BPM · \(groove.isTriplet ? "Triplets" : "Sixteenths")")
                    .font(.caption)
                    .foregroundColor(Color.textSecondary)
                Spacer()
            }

            // Where you are in the category, tap a segment to jump there
            HStack(spacing: 3) {
                ForEach(grooves.indices, id: \.self) { position in
                    Capsule()
                        .fill(position == index ? Color.signal : (position < index ? Color.textSecondary : Color.textPrimary.opacity(0.15)))
                        .frame(height: 4)
                        .contentShape(Rectangle().inset(by: -10))
                        .onTapGesture {
                            direction = position > index ? 1 : -1
                            withAnimation(.easeOut(duration: 0.2)) { index = position }
                        }
                }
            }
            .accessibilityElement()
            .accessibilityLabel("Groove \(index + 1) of \(grooves.count)")
        }
        .padding(.horizontal, 20)
        .animation(.easeOut(duration: 0.15), value: index)
    }

    private func switchCategory(to item: GrooveCategory) {
        guard item != category else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let wasPlaying = player.isPlaying
        direction = 1
        withAnimation(.easeOut(duration: 0.25)) {
            category = item
            index = 0
        }
        player.tempo = savedTempo(for: groove)
        if wasPlaying { player.play(groove) }
    }

    private func savedTempo(for groove: Groove) -> Double {
        let tempos = UserDefaults.standard.dictionary(forKey: "grooveTempos") as? [String: Double] ?? [:]
        return tempos[groove.id] ?? Double(groove.tempo)
    }

    private func step(_ delta: Int) {
        let target = index + delta
        guard grooves.indices.contains(target) else {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.5)
            return
        }
        direction = delta
        withAnimation(.easeOut(duration: 0.25)) { index = target }
    }
}

private struct StepButton: View {
    let symbol: String
    let label: String
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color.textPrimary.opacity(enabled ? 1 : 0.25))
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.surface))
        }
        .disabled(!enabled)
        .accessibilityLabel(label)
    }
}

// Drum notation as a grid: one row per voice, one column per sixteenth, counted 1 e & a
private struct DrumGrid: View {
    let groove: Groove
    let currentStep: Int

    private var counts: [String] {
        let sub = groove.isTriplet ? ["&", "a"] : ["e", "&", "a"]
        return (1...4).flatMap { ["\($0)"] + sub }
    }

    var body: some View {
        VStack(spacing: 6) {
            row(label: "") { step in
                Text(counts[step])
                    .font(.system(size: 11, weight: step % groove.stepsPerBeat == 0 ? .bold : .regular, design: .monospaced))
                    .foregroundColor((step % groove.stepsPerBeat == 0 ? Color.textPrimary : Color.textSecondary))
            }
            if groove.sticking.isEmpty {
                ForEach(DrumVoice.allCases.filter { groove.uses($0) }, id: \.self) { voice in
                    row(label: voice.label) { step in
                        NoteCell(hit: groove.hit(voice, at: step), voice: voice, isCurrent: step == currentStep)
                    }
                }
            } else {
                // Sticking exercises get one row per hand, so you see at a glance which hand plays
                ForEach(["R", "L"], id: \.self) { hand in
                    row(label: hand) { step in
                        NoteCell(hit: groove.hand(at: step) == Character(hand) ? groove.hit(.snare, at: step) : nil,
                                 voice: .snare, isCurrent: step == currentStep)
                    }
                }
                if groove.uses(.kick) {
                    row(label: "K") { step in
                        NoteCell(hit: groove.hit(.kick, at: step), voice: .kick, isCurrent: step == currentStep)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
    }

    private func row<Cell: View>(label: String, @ViewBuilder cell: @escaping (Int) -> Cell) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(Color.textSecondary)
                .frame(width: 26, alignment: .leading)
            ForEach(0..<groove.steps, id: \.self) { step in
                cell(step)
                    .frame(maxWidth: .infinity)
                    .padding(.leading, step % groove.stepsPerBeat == 0 && step > 0 ? 4 : 0)
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
                .fill(isCurrent ? Color.signal.opacity(0.25) : Color.surface)
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
                .stroke(Color.textSecondary, lineWidth: 1)
                .frame(width: 8, height: 8)
        case .open:
            Circle()
                .stroke(Color.signal, lineWidth: 1.5)
                .frame(width: 11, height: 11)
        case .accent:
            Circle()
                .fill(Color.signal)
                .frame(width: 13, height: 13)
        case .normal:
            if voice == .hiHat {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color.textPrimary)
            } else {
                Circle()
                    .fill(Color.textPrimary)
                    .frame(width: 11, height: 11)
            }
        }
    }
}

private struct Legend: View {
    var body: some View {
        HStack(spacing: 16) {
            item(Image(systemName: "xmark").font(.system(size: 9, weight: .bold)).foregroundColor(Color.textPrimary), "Hit")
            item(Circle().fill(Color.signal).frame(width: 10, height: 10), "Accent")
            item(Circle().stroke(Color.textSecondary, lineWidth: 1).frame(width: 8, height: 8), "Ghost")
            item(Circle().stroke(Color.signal, lineWidth: 1.5).frame(width: 10, height: 10), "Open hat")
        }
        .font(.caption)
        .foregroundColor(Color.textSecondary)
    }

    private func item<Mark: View>(_ mark: Mark, _ text: String) -> some View {
        HStack(spacing: 6) {
            mark
            Text(text)
        }
    }
}
