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
    @State private var showBPMInput = false
    @State private var bpmInputText = ""
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 30) {
                // Header with settings
                HStack {
                    Text("Metronome")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "#DDDDDD"))
                    
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
                    Button(action: { 
                        bpmInputText = String(Int(metronome.bpm))
                        showBPMInput = true 
                    }) {
                        Text("\(Int(metronome.bpm))")
                            .font(.system(size: 60, weight: .light, design: .monospaced))
                            .foregroundColor(Color(hex: "#DDDDDD"))
                    }
                    HStack {
                        Text("BPM")
                            .font(.title2)
                            .foregroundColor(Color(hex: "#DDDDDD").opacity(0.7))
                        
                        Button(action: { showQuickNoteValuePicker = true }) {
                            Text("(\(metronome.noteValue.displayName))")
                                .font(.caption)
                                .foregroundColor(Color(hex: "#F54206"))
                                .underline()
                        }
                    }
                }
                
                // BPM Slider
                VStack {
                    Slider(value: $metronome.bpm, in: 40...200, step: 1)
                        .accentColor(Color(hex: "#F54206"))
                        .onChange(of: metronome.bpm) { oldValue, newValue in
                            metronome.updateBPM(newValue)
                        }
                    
                    HStack {
                        Text("40")
                            .font(.caption)
                            .foregroundColor(Color(hex: "#DDDDDD").opacity(0.7))
                        Spacer()
                        Text("200")
                            .font(.caption)
                            .foregroundColor(Color(hex: "#DDDDDD").opacity(0.7))
                    }
                }
                .padding(.horizontal)
                
                // Beat Pattern Grid
                GridView(metronome: metronome)
                
                Spacer()
                
                // Play and Tap Tempo Buttons
                HStack(spacing: 20) {
                    // Tap Tempo Button
                    Button(action: {
                        metronome.tapTempo()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#303030"))
                                .frame(width: 80, height: 80)
                            
                            Text("TAP")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(hex: "#DDDDDD"))
                        }
                    }
                    
                    // Central Play Button
                    Button(action: {
                        metronome.togglePlayback()
                    }) {
                        ZStack {
                            Circle()
                                .fill(metronome.isPlaying ? Color(hex: "#F54206") : Color(hex: "#303030"))
                                .frame(width: 120, height: 120)
                                .scaleEffect(metronome.shouldBlink ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.1), value: metronome.shouldBlink)
                            
                            Image(systemName: metronome.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Color(hex: "#DDDDDD"))
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .background(Color(hex: "#242424"))
        .sheet(isPresented: $showSettings) {
            SettingsView(metronome: metronome)
        }
        .sheet(isPresented: $showGridSettings) {
            GridSettingsView(metronome: metronome)
        }
        .confirmationDialog("Choose Note Value", isPresented: $showQuickNoteValuePicker) {
            ForEach(NoteValue.allCases, id: \.self) { noteValue in
                Button(noteValue.displayName) {
                    metronome.updateNoteValue(noteValue)
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .alert("Enter BPM", isPresented: $showBPMInput) {
            TextField("BPM", text: $bpmInputText)
                .keyboardType(.numberPad)
            Button("Set") {
                if let newBPM = Double(bpmInputText) {
                    metronome.bpm = min(max(newBPM, 40), 200)
                    metronome.updateBPM(metronome.bpm)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter a BPM value between 40 and 200")
        }
    }
}

struct GridView: View {
    @ObservedObject var metronome: MetronomeManager
    
    var body: some View {
        VStack(spacing: 8) {
            // Main grid tiles
            ForEach(0..<numberOfRows(), id: \.self) { row in
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        ForEach(0..<tilesInRow(row), id: \.self) { col in
                            let beat = row * tilesPerRow() + col
                            Button(action: {
                                metronome.toggleGridCell(row: 0, col: beat)
                            }) {
                                Rectangle()
                                    .fill(getGridColor(for: beat))
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(6)
                                    .opacity(getGridOpacity(for: beat))
                                    .overlay(
                                        Group {
                                            if isActiveBeat(beat) {
                                                Text(metronome.gridDisplayMode.getLabel(for: beat, noteValue: metronome.noteValue))
                                                    .font(.title2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(Color(hex: "#DDDDDD"))
                                            } else {
                                                Image(systemName: "minus")
                                                    .font(.title2)
                                                    .foregroundColor(Color(hex: "#DDDDDD"))
                                            }
                                        }
                                        .id("\(beat)-\(metronome.gridDisplayMode.rawValue)-\(metronome.noteValue.rawValue)")
                                    )
                            }
                        }
                    }
                    
                    // Accent dots row
                    HStack(spacing: 8) {
                        ForEach(0..<tilesInRow(row), id: \.self) { col in
                            let beat = row * tilesPerRow() + col
                            Button(action: {
                                metronome.toggleAccentCell(col: beat)
                            }) {
                                Circle()
                                    .fill(getAccentColor(for: beat))
                                    .frame(width: 12, height: 12)
                                    .frame(width: 50, height: 20) // Same width as tiles
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
            return Color(hex: "#575554") // Inaktive Beats
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
            .background(Color(hex: "#242424"))
            .scrollContentBackground(.hidden)
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
        .background(Color(hex: "#242424"))
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
                        
                        Text("Note: Triplets are limited to 6 beats max")
                            .font(.caption)
                            .foregroundColor(Color(hex: "#DDDDDD").opacity(0.7))
                    }
                    .padding(.vertical, 8)
                }
            }
            .background(Color(hex: "#242424"))
            .scrollContentBackground(.hidden)
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
        .background(Color(hex: "#242424"))
    }
}

#Preview {
    ContentView()
}
