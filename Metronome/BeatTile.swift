import SwiftUI

struct BeatTile: View {
    let beat: Int
    @ObservedObject var metronome: MetronomeManager
    let isActive: Bool
    let isCurrent: Bool
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            metronome.toggleGridCell(row: 0, col: beat)
        }) {
            ZStack {
                Rectangle()
                    .fill(tileColor)
                    .frame(width: 40, height: 40)
                    .cornerRadius(4)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                    .animation(.easeOut(duration: 0.1), value: isPressed)
                
                if isActive {
                    Text(metronome.gridDisplayMode.getLabel(for: beat, noteValue: metronome.noteValue))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "#DDDDDD"))
                } else {
                    Image(systemName: "minus")
                        .font(.caption)
                        .foregroundColor(Color(hex: "#DDDDDD"))
                        .opacity(0.3)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.easeOut(duration: 0.1)) {
                    isPressed = pressing
                }
            },
            perform: { }
        )
    }
    
    private var tileColor: Color {
        if isCurrent {
            return Color(hex: "#F54206")
        } else if isActive {
            return Color(hex: "#303030")
        } else {
            return Color(hex: "#242424").opacity(0.5)
        }
    }
}