import SwiftUI

// Learn opens straight into the groove player at the last groove, the title opens the picker
struct LearnView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var player = GroovePlayer()

    var body: some View {
        let category = GroovePager.lastCategory
        NavigationView {
            GroovePager(category: category, player: player, index: GroovePager.lastIndex(in: category))
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { dismiss() }
                            .foregroundColor(Color.textPrimary)
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
                    .fill(index <= level ? Color.signal : Color.textPrimary.opacity(0.2))
                    .frame(width: 4, height: 6 + CGFloat(index) * 4)
            }
        }
        .frame(width: 20, height: 20, alignment: .bottom)
        .accessibilityLabel("Level \(level) of 3")
    }
}

// Level 2: one groove at a time, pick from the title menu, swipe or step through the category
struct GroovePager: View {
    @State var category: GrooveCategory
    @ObservedObject var player: GroovePlayer
    @State var index: Int
    @State private var direction = 1
    @State private var dragOffset: CGFloat = 0
    @State private var cursor: Int?
    @State private var isScrubbing = false
    @State private var resumeAfterScrub = false
    @State private var showPicker = false
    @State private var loopRange: ClosedRange<Int>?
    @State private var loopOn = false

    private var loop: ClosedRange<Int>? { loopOn ? loopRange : nil }

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
                    DrumGrid(
                        groove: groove,
                        currentStep: player.isPlaying ? player.currentStep : -1,
                        dynamic: player.dynamics,
                        cursor: cursor,
                        loop: loop,
                        onScrub: scrub,
                        onScrubEnd: endScrub
                    )

                    LoopControl(groove: groove, range: $loopRange, isOn: $loopOn, cursor: cursor,
                                onInteract: { active in
                                    if active { isScrubbing = true } else { DispatchQueue.main.async { isScrubbing = false } }
                                },
                                onCommit: commitLoop)
                        .padding(.horizontal, 12)
                }
                .frame(minHeight: 190, alignment: .top)
                .id(groove.id)
                .transition(.asymmetric(
                    insertion: .move(edge: direction > 0 ? .trailing : .leading).combined(with: .opacity),
                    removal: .move(edge: direction > 0 ? .leading : .trailing).combined(with: .opacity)
                ))
                .offset(x: dragOffset)

                Legend()

                // Tempo is secondary here, one slim row with the target chip beside it
                HStack(spacing: 12) {
                    BPMControl(bpm: $player.tempo, range: 10...240, compact: true)
                    TargetTempoChip(target: groove.tempo, current: Int(player.tempo.rounded())) {
                        player.tempo = Double(groove.tempo)
                    }
                }
                .padding(.horizontal, 20)

                HStack(spacing: 20) {
                    StepButton(symbol: "backward.end.fill", label: "Previous groove", enabled: index > 0) { step(-1) }

                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        player.isPlaying ? player.stop() : player.play(groove)
                    } label: {
                        Image(systemName: player.isPlaying ? "stop.fill" : "play.fill")
                            .font(.system(size: 32))
                            .foregroundColor(player.isPlaying ? Color.onSignal : Color.textPrimary)
                            .frame(width: 96, height: 96)
                            .background(Circle().fill(player.isPlaying ? Color.signal : Color.surfaceRaised))
                    }
                    .accessibilityLabel(player.isPlaying ? "Stop groove" : "Play groove")

                    StepButton(symbol: "forward.end.fill", label: "Next groove", enabled: index < grooves.count - 1) { step(1) }
                }


                Toggle(isOn: $player.dynamics) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Dynamics")
                            .foregroundColor(Color.textPrimary)
                        Text(player.dynamics ? "Accents and soft notes" : "Flat, every hit at one level")
                            .font(.caption)
                            .foregroundColor(Color.textSecondary)
                    }
                }
                .tint(Color.signal)
                .padding(.horizontal, 32)
                .onChange(of: player.dynamics) { _ in UISelectionFeedbackGenerator().selectionChanged() }
            }
            .padding(.vertical, 16)
        }
        .background(Color.ground.ignoresSafeArea())
        .clipped()
        // Swipe anywhere in the sheet, horizontal only so the tempo wheel and scrolling keep working
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    guard !isScrubbing else {
                        if dragOffset != 0 { dragOffset = 0 }
                        return
                    }
                    let horizontal = value.translation.width
                    guard abs(horizontal) > abs(value.translation.height) * 1.3 else { return }
                    let atEdge = (horizontal > 0 && index == 0) || (horizontal < 0 && index == grooves.count - 1)
                    dragOffset = atEdge ? horizontal * 0.25 : horizontal * 0.6
                }
                .onEnded { value in
                    guard !isScrubbing else {
                        dragOffset = 0
                        return
                    }
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
        .onAppear {
            player.tempo = savedTempo(for: groove)
            restoreLoop()
        }
        .onDisappear { player.stop() }
        .onChange(of: player.tempo) { tempo in
            GrooveTempos.save(tempo, for: groove)
        }
        .sheet(isPresented: $showPicker) {
            GroovePicker(category: category, groove: groove) { item, position in
                showPicker = false
                select(category: item, index: position)
            }
        }
        .onChange(of: index) { _ in
            rememberPosition()
            cursor = nil
            restoreLoop()
            UISelectionFeedbackGenerator().selectionChanged()
            player.tempo = savedTempo(for: groove)
            // Keep the music going, the next groove picks up straight away
            if player.isPlaying { player.play(groove) }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack {
                // Category and groove are picked in one sheet
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showPicker = true
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
                .accessibilityLabel("Category \(category.title), choose category and groove")
                Spacer()
                Text("\(index + 1) of \(grooves.count)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.textSecondary)
            }

            // Tapping the title opens the picker with every category and groove
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showPicker = true
            } label: {
                HStack(spacing: 8) {
                    Text(groove.title)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(Color.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.textSecondary)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .id(groove.id)
                .transition(.opacity)
            }
            .accessibilityLabel("\(groove.title), choose another groove")

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

    private func select(category item: GrooveCategory, index position: Int) {
        guard item != category || position != index else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let wasPlaying = player.isPlaying
        let sameCategory = item == category
        direction = position >= index || !sameCategory ? 1 : -1
        withAnimation(.easeOut(duration: 0.25)) {
            category = item
            index = position
        }
        if !sameCategory {
            // Index may not change when the category does, so do the groove change work here
            rememberPosition()
            cursor = nil
            restoreLoop()
            player.tempo = savedTempo(for: groove)
            if wasPlaying { player.play(groove) }
        }
    }

    // Loop part and switch are remembered per groove; a change restarts playback from the left edge of the loop
    private func commitLoop() {
        var ranges = UserDefaults.standard.dictionary(forKey: "grooveLoops") as? [String: [Int]] ?? [:]
        var switches = UserDefaults.standard.dictionary(forKey: "grooveLoopOn") as? [String: Bool] ?? [:]
        ranges[groove.id] = loopRange.map { [$0.lowerBound, $0.upperBound] }
        switches[groove.id] = loopOn
        UserDefaults.standard.set(ranges, forKey: "grooveLoops")
        UserDefaults.standard.set(switches, forKey: "grooveLoopOn")
        player.setLoop(loop)
        if player.isPlaying { player.play(groove) }
    }

    private func restoreLoop() {
        let ranges = UserDefaults.standard.dictionary(forKey: "grooveLoops") as? [String: [Int]] ?? [:]
        let switches = UserDefaults.standard.dictionary(forKey: "grooveLoopOn") as? [String: Bool] ?? [:]
        if let bounds = ranges[groove.id], bounds.count == 2, bounds[0] <= bounds[1], bounds[1] < groove.steps {
            loopRange = bounds[0]...bounds[1]
        } else {
            loopRange = nil
        }
        loopOn = loopRange != nil && (switches[groove.id] ?? false)
        player.setLoop(loop)
    }

    private func scrub(to step: Int) {
        if !isScrubbing {
            // Touching the grid freezes a running groove, releasing picks it up at that column
            isScrubbing = true
            resumeAfterScrub = player.isPlaying
            player.freeze()
            cursor = step
            UISelectionFeedbackGenerator().selectionChanged()
            player.audition(groove, step: step)
            return
        }
        guard step != cursor else { return }
        cursor = step
        UISelectionFeedbackGenerator().selectionChanged()
        player.audition(groove, step: step)
    }

    private func endScrub() {
        if let cursor {
            // Releasing always plays on from this column, a stopped groove starts here
            if resumeAfterScrub {
                player.resume(from: cursor)
            } else {
                player.play(groove, from: cursor)
            }
        }
        resumeAfterScrub = false
        DispatchQueue.main.async { isScrubbing = false }
    }

    private func savedTempo(for groove: Groove) -> Double {
        GrooveTempos.saved(for: groove) ?? Double(groove.tempo)
    }

    static var lastCategory: GrooveCategory {
        GrooveCategory(rawValue: UserDefaults.standard.string(forKey: "lastCategory") ?? "") ?? .classics
    }

    static func lastIndex(in category: GrooveCategory) -> Int {
        let last = UserDefaults.standard.dictionary(forKey: "lastGroove") as? [String: String] ?? [:]
        return category.grooves.firstIndex { $0.id == last[category.rawValue] } ?? 0
    }

    private func rememberPosition() {
        var last = UserDefaults.standard.dictionary(forKey: "lastGroove") as? [String: String] ?? [:]
        last[category.rawValue] = groove.id
        UserDefaults.standard.set(last, forKey: "lastGroove")
        UserDefaults.standard.set(category.rawValue, forKey: "lastCategory")
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

// Remembers the tempo you practise each groove at
enum GrooveTempos {
    private static let key = "grooveTempos"

    static func saved(for groove: Groove) -> Double? {
        let tempos = UserDefaults.standard.dictionary(forKey: key) as? [String: Double] ?? [:]
        return tempos[groove.id]
    }

    static func save(_ tempo: Double, for groove: Groove) {
        var tempos = UserDefaults.standard.dictionary(forKey: key) as? [String: Double] ?? [:]
        tempos[groove.id] = tempo
        UserDefaults.standard.set(tempos, forKey: key)
    }
}

// Tap to go back to the suggested tempo, quiet while you are already there
private struct TargetTempoChip: View {
    let target: Int
    let current: Int
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: current == target ? "checkmark" : "arrow.uturn.backward")
                    .font(.system(size: 11, weight: .semibold))
                Text("Target \(target) BPM")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
            }
            .foregroundColor(current == target ? Color.textSecondary : Color.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.surface))
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(current == target)
        .accessibilityLabel("Target \(target) BPM")
        .accessibilityHint(current == target ? "" : "Sets the tempo back to the target")
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
                .frame(width: 64, height: 64)
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
    let dynamic: Bool
    var cursor: Int? = nil
    var loop: ClosedRange<Int>? = nil
    var onScrub: ((Int) -> Void)? = nil
    var onScrubEnd: (() -> Void)? = nil

    static let labelWidth: CGFloat = 26
    static let beatGap: CGFloat = 4

    // Step under a horizontal position, the same layout math as the rows
    static func step(at x: CGFloat, width: CGFloat, groove: Groove) -> Int {
        let gaps = CGFloat(groove.steps / groove.stepsPerBeat - 1) * beatGap
        let cell = (width - labelWidth - gaps) / CGFloat(groove.steps)
        var position = labelWidth
        for step in 0..<groove.steps {
            if step % groove.stepsPerBeat == 0 && step > 0 { position += beatGap }
            if x < position + cell { return step }
            position += cell
        }
        return groove.steps - 1
    }

    static func center(of step: Int, width: CGFloat, groove: Groove) -> CGFloat {
        let gaps = CGFloat(groove.steps / groove.stepsPerBeat - 1) * beatGap
        let cell = (width - labelWidth - gaps) / CGFloat(groove.steps)
        return labelWidth + CGFloat(step) * cell + CGFloat(step / groove.stepsPerBeat) * beatGap + cell / 2
    }

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
                        NoteCell(hit: groove.played(voice, at: step, dynamic: dynamic), voice: voice, isCurrent: step == currentStep, isCursor: step == cursor, isOutsideLoop: isOutside(step))
                    }
                }
            } else {
                // Sticking exercises get one row per hand, so you see at a glance which hand plays
                ForEach(["R", "L"], id: \.self) { hand in
                    row(label: hand) { step in
                        NoteCell(hit: groove.hand(at: step) == Character(hand) ? groove.played(.snare, at: step, dynamic: dynamic) : nil,
                                 voice: .snare, isCurrent: step == currentStep, isCursor: step == cursor, isOutsideLoop: isOutside(step))
                    }
                }
                if groove.uses(.kick) {
                    row(label: "K") { step in
                        NoteCell(hit: groove.hit(.kick, at: step), voice: .kick, isCurrent: step == currentStep, isCursor: step == cursor, isOutsideLoop: isOutside(step))
                    }
                }
            }
        }
        // Drag across the grid to hear each step on its own
        .overlay(
            GeometryReader { proxy in
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                onScrub?(Self.step(at: value.location.x, width: proxy.size.width, groove: groove))
                            }
                            .onEnded { _ in onScrubEnd?() }
                    )
            }
        )
        .padding(.horizontal, 12)
    }

    private func isOutside(_ step: Int) -> Bool {
        guard let loop else { return false }
        return !loop.contains(step)
    }

    private func row<Cell: View>(label: String, @ViewBuilder cell: @escaping (Int) -> Cell) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(Color.textSecondary)
                .frame(width: Self.labelWidth, alignment: .leading)
            ForEach(0..<groove.steps, id: \.self) { step in
                cell(step)
                    .frame(maxWidth: .infinity)
                    .opacity(isOutside(step) ? 0.3 : 1)
                    .padding(.leading, step % groove.stepsPerBeat == 0 && step > 0 ? Self.beatGap : 0)
            }
        }
    }
}

private struct NoteCell: View {
    let hit: DrumHit?
    let voice: DrumVoice
    let isCurrent: Bool
    var isCursor = false
    var isOutsideLoop = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(isCurrent ? Color.signal.opacity(0.25) : Color.surface)
            if isCursor {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Color.signal, lineWidth: 1.5)
            }
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
            if voice == .hiHat {
                Image(systemName: "xmark")
                    .font(.system(size: 7, weight: .semibold))
                    .foregroundColor(Color.textSecondary)
            } else {
                Circle()
                    .stroke(Color.textSecondary, lineWidth: 1)
                    .frame(width: 8, height: 8)
            }
        case .open:
            Circle()
                .stroke(Color.signal, lineWidth: 1.5)
                .frame(width: 11, height: 11)
        case .accent:
            if voice == .hiHat {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(Color.signal)
            } else {
                Circle()
                    .fill(Color.signal)
                    .frame(width: 13, height: 13)
            }
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
            item(Circle().stroke(Color.textSecondary, lineWidth: 1).frame(width: 8, height: 8), "Soft")
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

// Loop a part of the bar: a switch, then two handles that snap to the grid columns
private struct LoopControl: View {
    let groove: Groove
    @Binding var range: ClosedRange<Int>?
    @Binding var isOn: Bool
    let cursor: Int?
    var onInteract: (Bool) -> Void = { _ in }
    var onCommit: () -> Void = {}

    @State private var dragging: Handle?

    private enum Handle { case start, end }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if range == nil {
                        // Start with the beat under the cursor, or the first two beats
                        let beat = groove.stepsPerBeat
                        let start = cursor.map { ($0 / beat) * beat } ?? 0
                        range = start...min(groove.steps - 1, start + (cursor == nil ? beat * 2 : beat) - 1)
                    }
                    isOn.toggle()
                    onCommit()
                } label: {
                    Label(range == nil ? "Loop a part" : (isOn ? "Loop on" : "Loop off"), systemImage: "repeat")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(isOn ? Color.onSignal : Color.textPrimary)
                        .padding(.horizontal, 14)
                        .frame(height: 36)
                        .background(Capsule().fill(isOn ? Color.signal : Color.surfaceRaised))
                }
                Spacer()
                if let loop = range {
                    Text("Steps \(loop.lowerBound + 1) to \(loop.upperBound + 1)")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(isOn ? Color.textSecondary : Color.textPrimary.opacity(0.4))
                }
            }

            if isOn, let loop = range {
                GeometryReader { proxy in
                    let width = proxy.size.width
                    let startX = DrumGrid.center(of: loop.lowerBound, width: width, groove: groove)
                    let endX = DrumGrid.center(of: loop.upperBound, width: width, groove: groove)
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.surfaceRaised)
                            .frame(height: 4)
                            .padding(.leading, DrumGrid.labelWidth)
                        Capsule()
                            .fill(Color.signal)
                            .frame(width: max(4, endX - startX), height: 4)
                            .offset(x: startX)
                        handle.offset(x: startX - 14)
                        handle.offset(x: endX - 14)
                    }
                    .frame(height: 44)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let step = DrumGrid.step(at: value.location.x, width: width, groove: groove)
                                if dragging == nil {
                                    onInteract(true)
                                    dragging = abs(value.startLocation.x - startX) <= abs(value.startLocation.x - endX) ? .start : .end
                                }
                                var updated = loop
                                if dragging == .start {
                                    updated = min(step, loop.upperBound)...loop.upperBound
                                } else {
                                    updated = loop.lowerBound...max(step, loop.lowerBound)
                                }
                                if updated != loop {
                                    UISelectionFeedbackGenerator().selectionChanged()
                                    range = updated
                                }
                            }
                            .onEnded { _ in
                                dragging = nil
                                onInteract(false)
                                onCommit()
                            }
                    )
                }
                .frame(height: 44)
                .accessibilityElement()
                .accessibilityLabel("Loop range")
                .accessibilityValue("Steps \(loop.lowerBound + 1) to \(loop.upperBound + 1)")
            }
        }
    }

    private var handle: some View {
        Circle()
            .fill(Color.textPrimary)
            .frame(width: 28, height: 28)
            .overlay(Circle().stroke(Color.signal, lineWidth: 2))
    }
}

// One list of every category and groove, opened from the player title, scrolled to the current groove
private struct GroovePicker: View {
    let category: GrooveCategory
    let groove: Groove
    let onSelect: (GrooveCategory, Int) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                List {
                    ForEach(GrooveCategory.allCases) { item in
                        Section {
                            ForEach(Array(item.grooves.enumerated()), id: \.element.id) { position, entry in
                                Button {
                                    onSelect(item, position)
                                } label: {
                                    HStack(spacing: 12) {
                                        LevelBadge(level: entry.level)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(entry.title)
                                                .foregroundColor(Color.textPrimary)
                                            Text(entry.focus)
                                                .font(.caption)
                                                .foregroundColor(Color.textSecondary)
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                        if entry.id == groove.id {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(Color.signal)
                                        } else {
                                            Text("\(entry.tempo) BPM")
                                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                                .foregroundColor(Color.textSecondary)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .listRowBackground(Color.surface)
                                .id(entry.id)
                            }
                        } header: {
                            Label(item.title, systemImage: item.symbol)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.ground)
                .onAppear { proxy.scrollTo(groove.id, anchor: .center) }
            }
            .navigationTitle("Choose a groove")
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
    }
}
