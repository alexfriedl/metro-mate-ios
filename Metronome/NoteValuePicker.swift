import SwiftUI

struct NoteValuePicker: View {
    @ObservedObject var metronome: MetronomeManager
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Fixed header
            VStack {
                Text("PATTERN")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.textPrimary)
                    .padding(.vertical, 20)
            }
            .frame(maxWidth: .infinity)
            .background(Color.ground)
            
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
                        .foregroundColor(Color.textSecondary)
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
            .background(Color.ground)
        }
        .background(Color.ground)
        .presentationDetents([.fraction(0.6)])
        .presentationDragIndicator(.visible)
        .sheetCornerRadius(20)
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
                    .foregroundColor(isSelected ? Color.signal : Color.textPrimary)
                
                Text(noteValue.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.textSecondary)
                
                // Visual representation
                HStack(spacing: 2) {
                    ForEach(0..<getVisualBeats(), id: \.self) { _ in
                        Circle()
                            .fill(isSelected ? Color.signal : Color.surfaceRaised)
                            .frame(width: 4, height: 4)
                    }
                }
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color.surfaceRaised : Color.surface)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.signal : Color.clear, lineWidth: 2)
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
    let title: LocalizedStringResource
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
                Text(String(localized: title).uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.textPrimary)
                
                Text("\(bpm)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.textPrimary)
                
                Text(noteValue.displayName)
                    .font(.system(size: 12))
                    .foregroundColor(Color.textSecondary)
            }
            .frame(width: 80, height: 80)
            .background(Color.surface)
            .cornerRadius(12)
        }
    }
}

private extension View {
    /// `presentationCornerRadius` needs iOS 16.4; older systems keep the default sheet radius.
    @ViewBuilder
    func sheetCornerRadius(_ radius: CGFloat) -> some View {
        if #available(iOS 16.4, *) {
            presentationCornerRadius(radius)
        } else {
            self
        }
    }
}
