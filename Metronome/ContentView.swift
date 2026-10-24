//
//  ContentView.swift
//  Metronome
//
//  Created by Alexander Friedl on 21.06.25.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var metronome = MetronomeManager.shared
    @State private var showSettings = false
    @State private var showLearn = false
    @State private var showHistory = false
    @State private var showQuickNoteValuePicker = false
    @State private var showBeatPresets = false
    @State private var showUndo = false
    @State private var undoTask: Task<Void, Never>?
    
    var body: some View {
        ZStack {
            // Background with animated stars
            Color.ground
                .ignoresSafeArea()
            
            PulseFieldView(
                timeline: metronome.beatTimeline,
                isPlaying: metronome.isPlaying,
                tapCount: metronome.tapCount
            )
            
            // Main content
            GeometryReader { geometry in
                content
            }
        }
        .sheet(isPresented: $showHistory) {
            HistoryView()
        }
        .sheet(isPresented: $showLearn) {
            LearnView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(metronome: metronome)
        }
        .sheet(isPresented: $showBeatPresets) {
            BeatPresetsView(metronome: metronome)
        }
        .sheet(isPresented: $showQuickNoteValuePicker) {
            NoteValuePicker(metronome: metronome, isPresented: $showQuickNoteValuePicker)
        }
    }
    
    private var content: some View {
        VStack(spacing: 12) {
                // Header with settings
                HStack {
                    Button(action: { 
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        showBeatPresets = true 
                    }) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("PRESET")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Color.textSecondary)
                            
                            Text(metronome.currentBeatName.localizedForDisplay.uppercased())
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color.textPrimary)
                        }
                    }
                    
                    Spacer()
                    
                    HeaderIconButton(symbol: "clock.arrow.circlepath", label: "History") {
                        showHistory = true
                    }
                    
                    HeaderIconButton(symbol: "graduationcap", label: "Learn") {
                        showLearn = true
                    }

                    HeaderIconButton(symbol: "speaker.wave.2", label: "Sound") {
                        showSettings = true
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // BPM Display
                BPMControl(bpm: Binding(
                    get: { metronome.bpm },
                    set: { metronome.updateBPM($0) }
                ))
                
                Spacer()
                    .frame(height: 20)
                
                // Undo sits beside the pattern pill so it never covers the new pattern, the pill stays centered
                HStack(spacing: 8) {
                    Color.clear.frame(maxWidth: .infinity, maxHeight: 1)
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        showQuickNoteValuePicker = true
                    }) {
                        HStack(spacing: 8) {
                            Text("PATTERN")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color.textSecondary)
                        
                            Text(metronome.noteValue.displayName)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(Color.textPrimary)
                        
                            Image(systemName: "chevron.down.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color.textSecondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.surface)
                        .cornerRadius(20)
                    }
                    .fixedSize()
                    ZStack(alignment: .leading) {
                        Color.clear.frame(maxWidth: .infinity, maxHeight: 1)
                        if showUndo {
                            UndoChip(action: undoShuffle)
                                .fixedSize()
                                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        }
                    }
                }

                // Beat Pattern Grid
                GridView(metronome: metronome)
                
                Spacer()
                    .frame(maxHeight: 20)
                
                // Play and Tap Tempo Buttons
                HStack(spacing: 20) {
                    // Tap Tempo Button
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        metronome.tapTempo()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.surface)
                                .frame(width: 64, height: 64)
                            
                            VStack(spacing: 2) {
                                Text("TAP")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Color.textPrimary)
                                
                                // Show tap count
                                if metronome.tapCount > 0 {
                                    Text("\(metronome.tapCount)")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(Color.signal)
                                        .transition(.opacity)
                                }
                            }
                        }
                    }
                    
                    // Central Play Button
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        metronome.togglePlayback()
                    } label: {
                        Image(systemName: metronome.isPlaying ? "stop.fill" : "play.fill")
                            .font(.system(size: 32))
                            .foregroundColor(metronome.isPlaying ? Color.onSignal : Color.textPrimary)
                    }
                    .buttonStyle(PlayKeyStyle(isPlaying: metronome.isPlaying, punch: playButtonPunch))
                    .accessibilityLabel(metronome.isPlaying ? "Stop" : "Start")
                    
                    // Randomize Beat Button
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        metronome.randomizeBeat()
                        offerUndo()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.surface)
                                .frame(width: 64, height: 64)
                            
                            Image(systemName: "shuffle")
                                .font(.system(size: 19))
                                .foregroundColor(Color.textPrimary)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
    }
    
    // The chip stays for five seconds after each roll, a new roll restarts the countdown
    private func offerUndo() {
        undoTask?.cancel()
        withAnimation(.easeOut(duration: 0.2)) { showUndo = true }
        undoTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.2)) { showUndo = false }
        }
    }

    private func undoShuffle() {
        undoTask?.cancel()
        metronome.undoRandomize()
        withAnimation(.easeOut(duration: 0.2)) { showUndo = false }
    }

    private func playButtonPunch(at date: Date) -> CGFloat {
        guard metronome.isPlaying else { return 1 }
        let time = PulseClock.now(for: date)
        guard let hit = metronome.beatTimeline.recent(at: time, limit: 4).first(where: { $0.audible }) else { return 1 }
        return 1 + 0.07 * CGFloat(PulseClock.weight(of: hit) * PulseClock.punch(of: hit, at: time))
    }
}

private struct UndoChip: View {
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 12, weight: .semibold))
                Text("Undo")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(Color.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.surfaceRaised))
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("Undo shuffle")
    }
}

// Round play key: pressed state from the button itself, beat punch read from the audio clock every frame
private struct PlayKeyStyle: ButtonStyle {
    let isPlaying: Bool
    let punch: (Date) -> CGFloat

    func makeBody(configuration: Configuration) -> some View {
        let pressScale: CGFloat = configuration.isPressed ? 0.95 : 1.0
        return ZStack {
            TimelineView(.animation(minimumInterval: nil, paused: !isPlaying)) { context in
                Circle()
                    .fill(isPlaying ? Color.signal : Color.surface)
                    .frame(width: 96, height: 96)
                    .scaleEffect(pressScale * punch(context.date))
            }
            configuration.label
                .scaleEffect(pressScale)
        }
        .frame(width: 96, height: 96)
        .contentShape(Circle())
        .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct GridView: View {
    @ObservedObject var metronome: MetronomeManager
    
    var body: some View {
        VStack(spacing: 6) {
            // Main grid tiles
            ForEach(0..<numberOfRows(), id: \.self) { row in
                VStack(spacing: 3) {
                    HStack(spacing: 6) {
                        ForEach(0..<tilesInRow(row), id: \.self) { col in
                            let beat = row * tilesPerRow() + col
                            BeatTile(
                                beat: beat,
                                metronome: metronome,
                                isActive: beat < metronome.gridPattern[0].count && metronome.gridPattern[0][beat],
                                isCurrent: beat == metronome.currentBeat && metronome.isPlaying
                            )
                        }
                    }
                    
                    // Accent dots row
                    HStack(spacing: 6) {
                        ForEach(0..<tilesInRow(row), id: \.self) { col in
                            let beat = row * tilesPerRow() + col
                            Button(action: {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                metronome.toggleAccentCell(col: beat)
                            }) {
                                AccentDot(isOn: isAccent(beat), isCurrent: beat == metronome.currentBeat && metronome.isPlaying)
                                    .frame(width: BeatTile.size, height: 24)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Accent on step \(beat + 1)")
                            .accessibilityValue(isAccent(beat) ? "On" : "Off")
                        }
                    }
                }
            }
        }
    }
    
    private func numberOfRows() -> Int {
        let tilesPerRow = self.tilesPerRow()
        return (metronome.beatsPerMeasure + tilesPerRow - 1) / tilesPerRow
    }
    
    private func tilesInRow(_ row: Int) -> Int {
        let remainingBeats = metronome.beatsPerMeasure - (row * tilesPerRow())
        return min(tilesPerRow(), remainingBeats)
    }
    
    private func tilesPerRow() -> Int {
        return metronome.noteValue.isTriplet ? 3 : 4
    }
    
    
    
    private func isAccent(_ beat: Int) -> Bool {
        beat < metronome.accentPattern.count && metronome.accentPattern[beat]
    }
}

// Filled when the step is accented, an outline shows where an accent can go
private struct AccentDot: View {
    let isOn: Bool
    let isCurrent: Bool

    var body: some View {
        if isOn {
            Circle()
                .fill(isCurrent ? Color.signal : Color.textSecondary)
                .frame(width: 10, height: 10)
        } else {
            Circle()
                .stroke(Color.textSecondary, lineWidth: 1)
                .frame(width: 10, height: 10)
        }
    }
}

struct SettingsView: View {
    @ObservedObject var metronome: MetronomeManager
    @ObservedObject private var kit = DrumKit.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Volume") {
                    VolumeSlider(volume: $metronome.volume)
                        .listRowBackground(Color.surface)
                }

                Section("Metronome") {
                    NavigationLink {
                        ClickSoundList(metronome: metronome)
                    } label: {
                        SettingRow(title: "Click", value: metronome.clickSound.title)
                    }
                    .listRowBackground(Color.surface)
                }

                Section {
                    ForEach(KitVoice.allCases) { voice in
                        NavigationLink {
                            KitSoundList(voice: voice)
                        } label: {
                            SettingRow(title: voice.title, value: kit.sound(for: voice).name)
                        }
                        .listRowBackground(Color.surface)
                    }
                } header: {
                    Text("Learn drum kit")
                } footer: {
                    Text("Used for the grooves and exercises in Learn.")
                        .foregroundColor(Color.textSecondary)
                }

                Section("Pattern") {
                    Stepper("Beats per bar: \(metronome.beatsPerMeasure)", 
                           value: $metronome.beatsPerMeasure, 
                           in: 1...16)
                    .onChange(of: metronome.beatsPerMeasure) { newValue in
                        metronome.updateBeatsPerMeasure(newValue)
                    }
                    .foregroundColor(Color.textPrimary)
                    .accentColor(Color.signal)
                    .listRowBackground(Color.surface)
                }
            }
            .background(Color.ground)
            .scrollContentBackground(.hidden)
            .foregroundColor(Color.textPrimary)
            .navigationTitle("Sound")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        dismiss()
                    }
                    .foregroundColor(Color.textPrimary)
                }
            }
        }
        .background(Color.ground)
        .preferredColorScheme(.dark)
    }
}

struct BeatPresetsView: View {
    @ObservedObject var metronome: MetronomeManager
    @Environment(\.dismiss) var dismiss
    @State private var showSaveDialog = false
    @State private var showResetConfirmation = false
    @State private var newBeatName = ""

    var body: some View {
        NavigationView {
            List {
                Section("Current") {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(metronome.currentBeatName.localizedForDisplay)
                                .font(.headline)
                                .foregroundColor(Color.textPrimary)
                            Text("\(metronome.noteValue.displayName) · \(Int(metronome.bpm)) BPM · \(metronome.beatsPerMeasure) beats")
                                .font(.caption)
                                .foregroundColor(Color.textSecondary)
                        }

                        Spacer()

                        Button("Save") {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            newBeatName = metronome.currentBeatName.localizedForDisplay
                            showSaveDialog = true
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(Color.signal)
                    }
                    .listRowBackground(Color.surface)
                }

                Section("Built-in") {
                    ForEach(defaultPresets(), id: \.noteValue) { preset in
                        PresetRow(preset: preset, isActive: metronome.isLoaded(preset)) { load(preset) }
                    }
                }

                Section("Saved presets") {
                    if metronome.savedBeats.isEmpty {
                        Text("No saved presets yet. Tap Save to keep the current pattern and tempo.")
                            .font(.subheadline)
                            .foregroundColor(Color.textSecondary)
                            .listRowBackground(Color.surface)
                    }
                    ForEach(metronome.savedBeats) { preset in
                        PresetRow(preset: preset, isActive: metronome.isLoaded(preset)) { load(preset) }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            metronome.deleteBeatPreset(metronome.savedBeats[index])
                        }
                    }
                }
            }
            .background(Color.ground)
            .scrollContentBackground(.hidden)
            .foregroundColor(Color.textPrimary)
            .navigationTitle("Presets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        showResetConfirmation = true
                    }
                    .foregroundColor(Color.textPrimary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        dismiss()
                    }
                    .foregroundColor(Color.textPrimary)
                }
            }
            .confirmationDialog("Reset to the basic pattern?", isPresented: $showResetConfirmation, titleVisibility: .visible) {
                Button("Reset", role: .destructive) {
                    metronome.resetToBasicBeat()
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Eighth notes at 80 BPM. Your saved presets stay.")
            }
        }
        .background(Color.ground)
        .preferredColorScheme(.dark)
        .alert("Save Preset", isPresented: $showSaveDialog) {
            TextField("Preset name", text: $newBeatName)
            Button("Save") {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                if !newBeatName.isEmpty {
                    metronome.saveBeatPreset(name: newBeatName)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Saves the current pattern, accents and tempo")
        }
    }

    private func load(_ preset: BeatPreset) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        metronome.loadBeatPreset(preset)
        dismiss()
    }

    func defaultPresets() -> [BeatPreset] {
        let presets: [(NoteValue, String)] = [
            (.quarter, "Quarter"),
            (.eighth, "Eighth"),
            (.sixteenth, "Sixteenth"),
            (.quarterTriplet, "Quarter Triplet"),
            (.eighthTriplet, "Eighth Triplet"),
            (.sixteenthTriplet, "Sixteenth Triplet")
        ]
        
        return presets.map { noteValue, name in
            let beatsPerMeasure = noteValue.beatsPerMeasure
            var gridPattern = Array(repeating: false, count: 16)
            var accentPattern = Array(repeating: false, count: 16)
            
            // Set all beats active for current beatsPerMeasure
            for i in 0..<beatsPerMeasure {
                gridPattern[i] = true
            }
            
            // Set accents on beats 1,2,3,4 for all preset beats
            switch noteValue {
            case .quarter:
                // Quarter: accent on beats 0,1,2,3 (positions 1,2,3,4)
                for i in 0..<min(4, beatsPerMeasure) {
                    accentPattern[i] = true
                }
            case .eighth:
                // Eighth: accent on beats 0,2,4,6 (positions 1,2,3,4)
                let accentPositions = [0, 2, 4, 6] // beats 1,2,3,4
                for position in accentPositions {
                    if position < beatsPerMeasure {
                        accentPattern[position] = true
                    }
                }
            case .sixteenth:
                // Sixteenth: accent on beats 0,4,8,12 (positions 1,2,3,4)
                let accentPositions = [0, 4, 8, 12] // beats 1,2,3,4
                for position in accentPositions {
                    if position < beatsPerMeasure {
                        accentPattern[position] = true
                    }
                }
            case .quarterTriplet:
                // Quarter triplet: accent on beats 0,1,2 (positions 1,2,3)
                for i in 0..<min(3, beatsPerMeasure) {
                    accentPattern[i] = true
                }
            case .eighthTriplet:
                // Eighth triplet: accent on beats 0,3 (positions 1,2)
                for i in stride(from: 0, to: min(6, beatsPerMeasure), by: 3) {
                    accentPattern[i] = true
                }
            case .sixteenthTriplet:
                // Sixteenth triplet: accent on beats 0,3,6,9 (positions 1,2,3,4)
                for i in stride(from: 0, to: min(12, beatsPerMeasure), by: 3) {
                    accentPattern[i] = true
                }
            }
            
            let displayMode: GridDisplayMode = {
                switch noteValue {
                case .sixteenth, .sixteenthTriplet:
                    return .subdivisionCounting
                default:
                    return .andCounting
                }
            }()
            
            return BeatPreset(
                name: name,
                noteValue: noteValue,
                bpm: 80,
                beatsPerMeasure: beatsPerMeasure,
                gridPattern: gridPattern,
                accentPattern: accentPattern,
                gridDisplayMode: displayMode
            )
        }
    }
}

// Whole row loads the preset, the checkmark shows which one matches what is set right now
private struct PresetRow: View {
    let preset: BeatPreset
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.name.localizedForDisplay)
                        .font(.headline)
                        .foregroundColor(Color.textPrimary)
                    Text("\(preset.noteValue.displayName) · \(Int(preset.bpm)) BPM · \(preset.beatsPerMeasure) beats")
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                }
                Spacer()
                if isActive {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.signal)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isActive ? .isSelected : [])
        .listRowBackground(Color.surface)
    }
}

#Preview {
    ContentView()
}

// Round header control used for history, learn and sound
struct HeaderIconButton: View {
    let symbol: String
    let label: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(Color.textPrimary)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.surface.opacity(0.8))
                        .overlay(Circle().stroke(Color.surfaceRaised, lineWidth: 1))
                )
        }
        .accessibilityLabel(label)
    }
}

// App volume with speaker icons at both ends, a tick of haptics every tenth
struct VolumeSlider: View {
    @Binding var volume: Double
    @State private var lastStep = -1

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "speaker.fill")
                .foregroundColor(Color.textSecondary)
            Slider(value: $volume, in: 0...1)
                .tint(Color.signal)
                .onChange(of: volume) { value in
                    let step = Int((value * 10).rounded())
                    if step != lastStep {
                        lastStep = step
                        UISelectionFeedbackGenerator().selectionChanged()
                    }
                }
            Image(systemName: "speaker.wave.3.fill")
                .foregroundColor(Color.textSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Volume")
        .accessibilityValue("\(Int(volume * 100)) percent")
    }
}

// Settings row with the current choice on the right
struct SettingRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(Color.textPrimary)
            Spacer()
            Text(value)
                .foregroundColor(Color.textSecondary)
        }
    }
}

// Second level for the metronome click: pick a voice, hear it once
struct ClickSoundList: View {
    @ObservedObject var metronome: MetronomeManager

    var body: some View {
        List {
            ForEach(ClickSound.allCases) { sound in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    metronome.clickSound = sound
                    metronome.previewSound()
                } label: {
                    SoundRow(title: sound.title, detail: sound.subtitle, isSelected: metronome.clickSound == sound)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.surface)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.ground)
        .navigationTitle("Click")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Second level for a kit voice: tapping a sound picks it and plays a short groove with it, no grid
struct KitSoundList: View {
    let voice: KitVoice
    @ObservedObject private var kit = DrumKit.shared
    @StateObject private var player = GroovePlayer(logsPractice: false)

    // A groove that shows off this voice
    private var example: Groove {
        let id: String
        switch voice {
        case .snare: id = "ghost-pocket"
        case .kick: id = "kick-syncopation"
        case .hiHat: id = "foundation"
        case .openHat: id = "open-lift"
        case .pad: id = "paradiddle"
        }
        return Groove.library.first { $0.id == id } ?? Groove.library[0]
    }

    var body: some View {
        List {
            Section {
                ForEach(voice.builtInOptions) { sound in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        kit.select(sound, for: voice)
                        // Tap plays the single hit, the example button below plays it in a groove
                        player.stop()
                        previewHit(sound)
                    } label: {
                        SoundRow(title: sound.name, detail: sound.detail, isSelected: kit.sound(for: voice) == sound)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.surface)
                }
            } footer: {
                Text("Tap a sound to hear it, play the example to hear it in \(example.title).")
                    .foregroundColor(Color.textSecondary)
            }

            // Imported sounds stay on this device; swipe to delete
            Section {
                ForEach(kit.importedSounds(for: voice)) { sound in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        kit.select(sound, for: voice)
                        player.stop()
                        previewHit(sound)
                    } label: {
                        SoundRow(title: sound.name, detail: sound.detail, isSelected: kit.sound(for: voice) == sound)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.surface)
                    .swipeActions {
                        Button(role: .destructive) { kit.remove(sound, for: voice) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showImporter = true
                } label: {
                    Label("Import sound", systemImage: "square.and.arrow.down")
                        .foregroundColor(Color.textPrimary)
                }
                .listRowBackground(Color.surface)
            } header: {
                Text("Your sounds")
            } footer: {
                Text(importMessage ?? String(localized: "Add a one-shot from Files, for example an export from your DAW. WAV, AIFF, M4A or MP3. It stays on this device."))
                    .foregroundColor(Color.textSecondary)
            }

            Section {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    player.isPlaying ? player.stop() : playExample()
                } label: {
                    Label(player.isPlaying ? "Stop example" : "Play example", systemImage: player.isPlaying ? "stop.fill" : "play.fill")
                        .foregroundColor(player.isPlaying ? Color.signal : Color.textPrimary)
                }
                .listRowBackground(Color.surface)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.ground)
        .navigationTitle(voice.title)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { player.stop() }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.audio], allowsMultipleSelection: true) { result in
            guard case .success(let urls) = result else { return }
            let added = kit.importSounds(urls, for: voice)
            importMessage = added == urls.count ? nil : String(localized: "\(urls.count - added) files could not be read as audio.")
            if let sound = kit.importedSounds(for: voice).last, added > 0 { previewHit(sound) }
        }
    }

    @State private var hitPlayer: AVAudioPlayer?
    @State private var showImporter = false
    @State private var importMessage: String?

    private func previewHit(_ sound: KitSound) {
        guard let url = Synth.url(for: sound.accent.file) else { return }
        try? AVAudioSession.sharedInstance().setActive(true)
        hitPlayer = try? AVAudioPlayer(contentsOf: url)
        hitPlayer?.volume = sound.accent.gain * Float(MetronomeManager.shared.volume)
        hitPlayer?.play()
    }

    private func playExample() {
        player.tempo = Double(example.tempo)
        // The kit reloads its buffers asynchronously, start right after so the new sound is in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            player.play(example)
        }
    }
}

struct SoundRow: View {
    let title: String
    let detail: String
    let isSelected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundColor(Color.textPrimary)
                Text(detail)
                    .font(.caption)
                    .foregroundColor(Color.textSecondary)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(Color.signal)
            }
        }
        .contentShape(Rectangle())
    }
}
