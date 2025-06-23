//
//  ContentView.swift
//  Metronome
//
//  Created by Alexander Friedl on 21.06.25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var metronome = MetronomeManager()
    @State private var showSettings = false
    @State private var showQuickNoteValuePicker = false
    @State private var showGridSettings = false
    @State private var showBeatPresets = false
    @State private var repeatTimer: Timer?
    
    var body: some View {
        GeometryReader { geometry in
            content
        }
        .background(Color(hex: "#1C1C1B"))
        .sheet(isPresented: $showSettings) {
            SettingsView(metronome: metronome)
        }
        .sheet(isPresented: $showGridSettings) {
            GridSettingsView(metronome: metronome)
        }
        .sheet(isPresented: $showBeatPresets) {
            BeatPresetsView(metronome: metronome)
        }
        .confirmationDialog("Choose Note Value", isPresented: $showQuickNoteValuePicker) {
            ForEach(NoteValue.allCases, id: \.self) { noteValue in
                Button(noteValue.displayName) {
                    metronome.updateNoteValue(noteValue)
                }
            }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    private var content: some View {
        VStack(spacing: 12) {
                // Header with settings
                HStack {
                    Button(action: { showBeatPresets = true }) {
                        Text(metronome.currentBeatName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "#DDDDDD"))
                            .underline()
                    }
                    
                    Spacer()
                    
                    Button(action: { showSettings.toggle() }) {
                        Image(systemName: "gear")
                            .font(.title2)
                            .foregroundColor(Color(hex: "#DDDDDD"))
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // BPM Display
                VStack {
                    HStack(spacing: 20) {
                        Button(action: { 
                            let newBPM = max(metronome.bpm - 1, 40)
                            metronome.bpm = newBPM
                            metronome.updateBPM(newBPM)
                        }) {
                            Image(systemName: "minus")
                                .font(.title2)
                                .foregroundColor(Color(hex: "#DDDDDD"))
                        }
                        .onLongPressGesture(minimumDuration: 0.5, maximumDistance: 50) {
                            // Long press action
                        } onPressingChanged: { pressing in
                            if pressing {
                                startRepeatingDecrease()
                            } else {
                                stopRepeating()
                            }
                        }
                        
                        // Custom BPM Picker
                        VStack(spacing: 0) {
                            // Upper value (only show if not at minimum)
                            if Int(metronome.bpm) > 40 {
                                Text("\(Int(metronome.bpm) - 1)")
                                    .font(.system(size: 48, weight: .light, design: .monospaced))
                                    .foregroundColor(Color(hex: "#DDDDDD").opacity(0.2))
                                    .frame(height: 60)
                            } else {
                                Spacer()
                                    .frame(height: 60)
                            }
                            
                            // Current value with background
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: "#303030"))
                                    .frame(width: 120, height: 60)
                                
                                Text("\(Int(metronome.bpm))")
                                    .font(.system(size: 48, weight: .light, design: .monospaced))
                                    .foregroundColor(Color(hex: "#DDDDDD"))
                            }
                            .frame(height: 60)
                            
                            // Lower value (only show if not at maximum)
                            if Int(metronome.bpm) < 200 {
                                Text("\(Int(metronome.bpm) + 1)")
                                    .font(.system(size: 48, weight: .light, design: .monospaced))
                                    .foregroundColor(Color(hex: "#DDDDDD").opacity(0.2))
                                    .frame(height: 60)
                            } else {
                                Spacer()
                                    .frame(height: 60)
                            }
                        }
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    let sensitivity: Double = 0.02
                                    let change = -Double(gesture.translation.height) * sensitivity
                                    let newBPM = max(40, min(200, metronome.bpm + change))
                                    
                                    // Haptic feedback on BPM change
                                    if Int(newBPM) != Int(metronome.bpm) {
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                        impactFeedback.impactOccurred()
                                    }
                                    
                                    metronome.bpm = newBPM
                                    metronome.updateBPM(newBPM)
                                }
                        )
                        
                        Button(action: { 
                            let newBPM = min(metronome.bpm + 1, 200)
                            metronome.bpm = newBPM
                            metronome.updateBPM(newBPM)
                        }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(Color(hex: "#DDDDDD"))
                        }
                        .onLongPressGesture(minimumDuration: 0.5, maximumDistance: 50) {
                            // Long press action
                        } onPressingChanged: { pressing in
                            if pressing {
                                startRepeatingIncrease()
                            } else {
                                stopRepeating()
                            }
                        }
                    }
                }
                
                Spacer()
                    .frame(height: 20)
                
                HStack(spacing: 12) {
                    Text("BPM")
                        .font(.title2)
                        .foregroundColor(Color(hex: "#DDDDDD").opacity(0.7))
                    
                    Button(action: { showQuickNoteValuePicker = true }) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#242424"))
                                .frame(width: 40, height: 40)
                            
                            Text(metronome.noteValue.displayName)
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(Color(hex: "#DDDDDD"))
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
                        metronome.tapTempo()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#242424"))
                                .frame(width: 64, height: 64)
                            
                            Text("TAP")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(hex: "#DDDDDD"))
                        }
                    }
                    
                    // Central Play Button
                    Button(action: {
                        metronome.togglePlayback()
                    }) {
                        ZStack {
                            Circle()
                                .fill(metronome.isPlaying ? Color(hex: "#F54206") : Color(hex: "#242424"))
                                .frame(width: 96, height: 96)
                                .scaleEffect(metronome.shouldBlink ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.1), value: metronome.shouldBlink)
                            
                            Image(systemName: metronome.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 32))
                                .foregroundColor(Color(hex: "#DDDDDD"))
                        }
                    }
                    
                    // Randomize Beat Button
                    Button(action: {
                        metronome.randomizeBeat()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#242424"))
                                .frame(width: 64, height: 64)
                            
                            Image(systemName: "shuffle")
                                .font(.system(size: 19))
                                .foregroundColor(Color(hex: "#DDDDDD"))
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
    }
    
    private func startRepeatingIncrease() {
        repeatTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            let newBPM = min(metronome.bpm + 1, 200)
            metronome.bpm = newBPM
            metronome.updateBPM(newBPM)
            
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }
    
    private func startRepeatingDecrease() {
        repeatTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            let newBPM = max(metronome.bpm - 1, 40)
            metronome.bpm = newBPM
            metronome.updateBPM(newBPM)
            
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }
    
    private func stopRepeating() {
        repeatTimer?.invalidate()
        repeatTimer = nil
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
                            Button(action: {
                                metronome.toggleGridCell(row: 0, col: beat)
                            }) {
                                Rectangle()
                                    .fill(getGridColor(for: beat))
                                    .frame(width: 40, height: 40)
                                    .cornerRadius(4)
                                    .opacity(getGridOpacity(for: beat))
                                    .overlay(
                                        Group {
                                            if isActiveBeat(beat) {
                                                Text(metronome.gridDisplayMode.getLabel(for: beat, noteValue: metronome.noteValue))
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(Color(hex: "#DDDDDD"))
                                            } else {
                                                Image(systemName: "minus")
                                                    .font(.caption)
                                                    .foregroundColor(Color(hex: "#DDDDDD"))
                                            }
                                        }
                                        .id("\(beat)-\(metronome.gridDisplayMode.rawValue)-\(metronome.noteValue.rawValue)")
                                    )
                            }
                        }
                    }
                    
                    // Accent dots row
                    HStack(spacing: 6) {
                        ForEach(0..<tilesInRow(row), id: \.self) { col in
                            let beat = row * tilesPerRow() + col
                            Button(action: {
                                metronome.toggleAccentCell(col: beat)
                            }) {
                                Circle()
                                    .fill(getAccentColor(for: beat))
                                    .frame(width: 10, height: 10)
                                    .frame(width: 40, height: 16) // Same width as tiles
                            }
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
    
    private func isActiveBeat(_ beat: Int) -> Bool {
        return beat < metronome.gridPattern[0].count && metronome.gridPattern[0][beat]
    }
    
    private func isCurrentBeat(_ beat: Int) -> Bool {
        return beat == metronome.currentBeat && metronome.isPlaying
    }
    
    private func getGridColor(for beat: Int) -> Color {
        if isCurrentBeat(beat) {
            return Color(hex: "#F54206") // Orange für aktuellen Beat
        } else if isActiveBeat(beat) {
            return Color(hex: "#303030") // Aktive Beats
        } else {
            return Color.clear // Inaktive Beats transparent
        }
    }
    
    private func getGridOpacity(for beat: Int) -> Double {
        return isActiveBeat(beat) ? 1.0 : 0.5
    }
    
    
    private func getAccentColor(for beat: Int) -> Color {
        if beat < metronome.accentPattern.count && metronome.accentPattern[beat] {
            if beat == metronome.currentBeat && metronome.isPlaying {
                return Color(hex: "#F54206") // Orange when playing accent
            } else {
                return Color(hex: "#303030") // Gray accent dots
            }
        } else {
            return Color.clear
        }
    }
}

struct SettingsView: View {
    @ObservedObject var metronome: MetronomeManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Beat Configuration") {
                    Stepper("Beats per Measure: \(metronome.beatsPerMeasure)", 
                           value: $metronome.beatsPerMeasure, 
                           in: 1...16)
                    .onChange(of: metronome.beatsPerMeasure) { oldValue, newValue in
                        metronome.updateBeatsPerMeasure(newValue)
                    }
                    .foregroundColor(Color(hex: "#DDDDDD"))
                    .accentColor(Color(hex: "#F54206"))
                }
            }
            .background(Color(hex: "#1C1C1B"))
            .scrollContentBackground(.hidden)
            .foregroundColor(Color(hex: "#DDDDDD"))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#DDDDDD"))
                }
            }
        }
        .background(Color(hex: "#1C1C1B"))
        .preferredColorScheme(.dark)
    }
}

struct GridSettingsView: View {
    @ObservedObject var metronome: MetronomeManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Grid Configuration") {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Number of Beats: \(metronome.beatsPerMeasure)")
                            .foregroundColor(Color(hex: "#DDDDDD"))
                        
                        let maxBeats = metronome.noteValue.isTriplet ? 12 : 16
                        Slider(value: Binding(
                            get: { Double(metronome.beatsPerMeasure) },
                            set: { metronome.updateGridBeats(Int($0)) }
                        ), in: 1...Double(maxBeats), step: 1)
                        .accentColor(Color(hex: "#F54206"))
                        
                        HStack {
                            Text("1")
                                .font(.caption)
                                .foregroundColor(Color(hex: "#DDDDDD").opacity(0.7))
                            Spacer()
                            Text("\(maxBeats)")
                                .font(.caption)
                                .foregroundColor(Color(hex: "#DDDDDD").opacity(0.7))
                        }
                        
                        Text("Note: Triplets are limited to 12 beats max")
                            .font(.caption)
                            .foregroundColor(Color(hex: "#DDDDDD").opacity(0.7))
                    }
                    .padding(.vertical, 8)
                }
            }
            .background(Color(hex: "#1C1C1B"))
            .scrollContentBackground(.hidden)
            .foregroundColor(Color(hex: "#DDDDDD"))
            .navigationTitle("Grid Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#DDDDDD"))
                }
            }
        }
        .background(Color(hex: "#1C1C1B"))
        .preferredColorScheme(.dark)
    }
}

struct BeatPresetsView: View {
    @ObservedObject var metronome: MetronomeManager
    @Environment(\.dismiss) var dismiss
    @State private var showSaveDialog = false
    @State private var newBeatName = ""
    
    var body: some View {
        NavigationView {
            List {
                Section("Current Beat") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(metronome.currentBeatName)
                                .font(.headline)
                                .foregroundColor(Color(hex: "#DDDDDD"))
                            Text("\(metronome.noteValue.displayName) • \(Int(metronome.bpm)) BPM • \(metronome.beatsPerMeasure) beats")
                                .font(.caption)
                                .foregroundColor(Color(hex: "#DDDDDD").opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Button("Save As...") {
                            newBeatName = metronome.currentBeatName
                            showSaveDialog = true
                        }
                        .foregroundColor(Color(hex: "#F54206"))
                    }
                    .listRowBackground(Color(hex: "#303030"))
                }
                
                Section("Presets") {
                    ForEach(defaultPresets(), id: \.noteValue) { preset in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(preset.name)
                                    .font(.headline)
                                    .foregroundColor(Color(hex: "#DDDDDD"))
                                Text("\(preset.noteValue.displayName) • \(Int(preset.bpm)) BPM • \(preset.beatsPerMeasure) beats")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "#DDDDDD").opacity(0.7))
                            }
                            
                            Spacer()
                            
                            Button("Load") {
                                metronome.loadBeatPreset(preset)
                                dismiss()
                            }
                            .foregroundColor(Color(hex: "#F54206"))
                        }
                        .listRowBackground(Color(hex: "#303030"))
                    }
                }
                
                Section("Saved Beats") {
                    ForEach(metronome.savedBeats) { preset in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(preset.name)
                                    .font(.headline)
                                    .foregroundColor(Color(hex: "#DDDDDD"))
                                Text("\(preset.noteValue.displayName) • \(Int(preset.bpm)) BPM • \(preset.beatsPerMeasure) beats")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "#DDDDDD").opacity(0.7))
                            }
                            
                            Spacer()
                            
                            Button("Load") {
                                metronome.loadBeatPreset(preset)
                                dismiss()
                            }
                            .foregroundColor(Color(hex: "#F54206"))
                        }
                        .listRowBackground(Color(hex: "#303030"))
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            metronome.deleteBeatPreset(metronome.savedBeats[index])
                        }
                    }
                }
            }
            .background(Color(hex: "#1C1C1B"))
            .scrollContentBackground(.hidden)
            .foregroundColor(Color(hex: "#DDDDDD"))
            .navigationTitle("Beat Presets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        metronome.resetToBasicBeat()
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#DDDDDD"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#DDDDDD"))
                }
            }
        }
        .background(Color(hex: "#1C1C1B"))
        .preferredColorScheme(.dark)
        .alert("Save Beat Preset", isPresented: $showSaveDialog) {
            TextField("Beat Name", text: $newBeatName)
                .foregroundColor(.black)
            Button("Save") {
                if !newBeatName.isEmpty {
                    metronome.saveBeatPreset(name: newBeatName)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter a name for this beat configuration")
        }
    }
    
    func defaultPresets() -> [BeatPreset] {
        let presets: [(NoteValue, String)] = [
            (.quarter, "Default"),
            (.eighth, "Eighth"),
            (.sixteenth, "Sixteenth"),
            (.quarterTriplet, "Triplet (quarter)"),
            (.eighthTriplet, "Triplet (eight)"),
            (.sixteenthTriplet, "Triplet (sixteenth)")
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

#Preview {
    ContentView()
}
