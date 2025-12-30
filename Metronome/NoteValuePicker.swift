import SwiftUI

struct NoteValuePicker: View {
    @ObservedObject var metronome: MetronomeManager
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Fixed header
            VStack {
                Text("BEAT PATTERN")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "#DDDDDD"))
                    .padding(.vertical, 20)
            }
            .frame(maxWidth: .infinity)
            .background(Color(hex: "#1C1C1B"))
            
            // Scrollable content
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(NoteValue.allCases, id: \.self) { noteValue in
                        NoteValueButton(
                            noteValue: noteValue,
                            isSelected: metronome.noteValue == noteValue,
                            action: {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()
                                    metronome.updateNoteValue(noteValue)
                                    
                                    // Close sheet after selection
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        isPresented = false
                                    }
                                }
                            }
                        )
                    }
                }
                .padding()
                
                // Presets Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("QUICK PRESETS")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "#DDDDDD").opacity(0.6))
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            PresetButton(title: "Basic", bpm: 120, noteValue: .quarter, metronome: metronome, isPresented: $isPresented)
                            PresetButton(title: "Rock", bpm: 110, noteValue: .eighth, metronome: metronome, isPresented: $isPresented)
                            PresetButton(title: "Jazz", bpm: 140, noteValue: .quarterTriplet, metronome: metronome, isPresented: $isPresented)
                            PresetButton(title: "Fast", bpm: 160, noteValue: .sixteenth, metronome: metronome, isPresented: $isPresented)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .background(Color(hex: "#1C1C1B"))
        }
        .background(Color(hex: "#1C1C1B"))
        .presentationDetents([.fraction(0.6)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(20)
    }
}

struct NoteValueButton: View {
    let noteValue: NoteValue
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(noteValue.displayName)
                    .font(.system(size: 36))
                    .foregroundColor(isSelected ? Color(hex: "#F54206") : Color(hex: "#DDDDDD"))
                
                Text(noteValue.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#DDDDDD").opacity(0.6))
                
                // Visual representation
                HStack(spacing: 2) {
                    ForEach(0..<getVisualBeats(), id: \.self) { _ in
                        Circle()
                            .fill(isSelected ? Color(hex: "#F54206") : Color(hex: "#303030"))
                            .frame(width: 4, height: 4)
                    }
                }
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color(hex: "#303030") : Color(hex: "#242424"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color(hex: "#F54206") : Color.clear, lineWidth: 2)
            )
        }
    }
    
    private func getVisualBeats() -> Int {
        switch noteValue {
        case .quarter: return 4
        case .eighth: return 8
        case .sixteenth: return 8
        case .quarterTriplet: return 3
        case .eighthTriplet: return 6
        case .sixteenthTriplet: return 6
        }
    }
}

struct PresetButton: View {
    let title: String
    let bpm: Int
    let noteValue: NoteValue
    @ObservedObject var metronome: MetronomeManager
    @Binding var isPresented: Bool
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            metronome.bpm = Double(bpm)
            metronome.updateBPM(Double(bpm))
            metronome.updateNoteValue(noteValue)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isPresented = false
            }
        }) {
            VStack(spacing: 6) {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "#DDDDDD"))
                
                Text("\(bpm)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "#F54206"))
                
                Text(noteValue.displayName)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#DDDDDD").opacity(0.6))
            }
            .frame(width: 80, height: 80)
            .background(Color(hex: "#242424"))
            .cornerRadius(12)
        }
    }
}