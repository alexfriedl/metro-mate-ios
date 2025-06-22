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
    @State private var showGridDisplayPicker = false
    
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
                    
                    Button(action: { showGridDisplayPicker = true }) {
                        Text(metronome.gridDisplayMode.displayName)
                            .font(.caption)
                            .foregroundColor(Color(hex: "#F54206"))
                            .underline()
                    }
                    
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
                    Text("\(Int(metronome.bpm))")
                        .font(.system(size: 60, weight: .light, design: .monospaced))
                        .foregroundColor(Color(hex: "#DDDDDD"))
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
                
                Spacer()
            }
            .padding()
        }
        .background(Color(hex: "#242424"))
        .sheet(isPresented: $showSettings) {
            SettingsView(metronome: metronome)
        }
        .confirmationDialog("Notenwert wählen", isPresented: $showQuickNoteValuePicker) {
            ForEach(NoteValue.allCases, id: \.self) { noteValue in
                Button(noteValue.displayName) {
                    metronome.updateNoteValue(noteValue)
                }
            }
            Button("Abbrechen", role: .cancel) { }
        }
        .confirmationDialog("Zählweise wählen", isPresented: $showGridDisplayPicker) {
            ForEach(GridDisplayMode.allCases, id: \.self) { displayMode in
                Button(displayMode.displayName) {
                    metronome.gridDisplayMode = displayMode
                }
            }
            Button("Abbrechen", role: .cancel) { }
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
                                        getGridContent(for: beat)
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
    
    private func getGridContent(for beat: Int) -> some View {
        if isActiveBeat(beat) {
            return AnyView(
                Text(metronome.gridDisplayMode.getLabel(for: beat, noteValue: metronome.noteValue))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "#DDDDDD"))
            )
        } else {
            return AnyView(
                Image(systemName: "minus")
                    .font(.title2)
                    .foregroundColor(Color(hex: "#DDDDDD"))
            )
        }
    }
    
    private func getAccentColor(for beat: Int) -> Color {
        if beat < metronome.accentPattern.count && metronome.accentPattern[beat] {
            return Color(hex: "#575554") // Same as inactive beat tiles
        } else {
            return Color.clear
        }
    }
}

struct SettingsView: View {
    @ObservedObject var metronome: MetronomeManager
    @Environment(\.dismiss) var dismiss
    @State private var showNoteValuePicker = false
    
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
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notenwerte")
                            .foregroundColor(Color(hex: "#DDDDDD"))
                        
                        Button(action: { 
                            showNoteValuePicker = true 
                        }) {
                            HStack {
                                Text(metronome.noteValue.displayName)
                                    .foregroundColor(Color(hex: "#DDDDDD"))
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(Color(hex: "#DDDDDD").opacity(0.7))
                            }
                            .padding()
                            .background(Color(hex: "#303030"))
                            .cornerRadius(8)
                        }
                    }
                }
                
                Section("Grid Configuration") {
                    Stepper("Grid Size: \(metronome.gridSize)x\(metronome.gridSize)", 
                           value: $metronome.gridSize, 
                           in: 2...8)
                    .onChange(of: metronome.gridSize) { oldValue, newValue in
                        metronome.updateGridSize(newValue)
                    }
                    .foregroundColor(Color(hex: "#DDDDDD"))
                    .accentColor(Color(hex: "#F54206"))
                }
            }
            .background(Color(hex: "#242424"))
            .scrollContentBackground(.hidden)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
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
        .confirmationDialog("Notenwert wählen", isPresented: $showNoteValuePicker) {
            ForEach(NoteValue.allCases, id: \.self) { noteValue in
                Button(noteValue.displayName) {
                    metronome.updateNoteValue(noteValue)
                }
            }
            Button("Abbrechen", role: .cancel) { }
        }
    }
}

#Preview {
    ContentView()
}
