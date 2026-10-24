import SwiftUI
import UIKit

// Tempo wheel: drag the number like a detented dial, one BPM per notch, with stepper buttons either side
struct BPMControl: View {
    @Binding var bpm: Double
    var range: ClosedRange<Int> = 1...300
    // Compact is a slim single row for secondary places like the learn player
    var compact = false

    @State private var dragStart: Double?
    @State private var dragValue: Double?
    @State private var repeatTask: Task<Void, Never>?

    private let notch: CGFloat = 14
    private let rowHeight: CGFloat = 58
    private let haptics = TempoHaptics()

    private var shownValue: Double { dragValue ?? bpm }

    var body: some View {
        if compact {
            HStack(spacing: 4) {
                StepperKey(symbol: "minus", size: 44) { pressing in
                    pressing ? beginRepeat(-1) : endRepeat()
                }
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int(shownValue.rounded()))")
                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.textPrimary)
                    Text("BPM")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color.textSecondary)
                }
                .frame(minWidth: 84, minHeight: 44)
                .contentShape(Rectangle())
                .gesture(dragGesture)
                .accessibilityElement()
                .accessibilityLabel("Tempo")
                .accessibilityValue("\(Int(bpm)) BPM")
                .accessibilityAdjustableAction(adjust)
                StepperKey(symbol: "plus", size: 44) { pressing in
                    pressing ? beginRepeat(1) : endRepeat()
                }
            }
            .padding(2)
            .background(Capsule().fill(Color.surface))
        } else {
            HStack(spacing: 12) {
                StepperKey(symbol: "minus") { pressing in
                    pressing ? beginRepeat(-1) : endRepeat()
                }

                wheel

                StepperKey(symbol: "plus") { pressing in
                    pressing ? beginRepeat(1) : endRepeat()
                }
            }
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { gesture in
                let start = dragStart ?? bpm
                if dragStart == nil {
                    dragStart = bpm
                    haptics.prepare()
                }
                // Fixed mapping from finger travel to tempo, measured from where the drag began
                let raw = start - Double(gesture.translation.height / notch)
                let clamped = min(max(raw, Double(range.lowerBound)), Double(range.upperBound))
                dragValue = clamped
                commit(Int(clamped.rounded()), hitLimit: raw != clamped)
            }
            .onEnded { _ in
                withAnimation(.interpolatingSpring(stiffness: 420, damping: 30)) {
                    dragValue = nil
                }
                dragStart = nil
            }
    }

    private func adjust(_ direction: AccessibilityAdjustmentDirection) {
        switch direction {
        case .increment: commit(Int(bpm) + 1, hitLimit: false)
        case .decrement: commit(Int(bpm) - 1, hitLimit: false)
        @unknown default: break
        }
    }

    private var wheel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.surfaceRaised)
                .frame(width: 132, height: rowHeight)

            // Neighbours roll past continuously while dragging, the wheel follows the finger exactly
            ForEach(-2...2, id: \.self) { slot in
                let base = Int(shownValue.rounded(.down))
                let number = base + slot
                let offset = (Double(number) - shownValue) * Double(rowHeight)
                if range.contains(number) {
                    Text("\(number)")
                        .font(.system(size: 48, weight: .light, design: .monospaced))
                        .monospacedDigit()
                        .foregroundColor(Color.textPrimary)
                        .opacity(max(0, 1 - abs(offset) / Double(rowHeight) * 0.8))
                        .scaleEffect(max(0.7, 1 - abs(offset) / Double(rowHeight) * 0.15))
                        .offset(y: offset)
                }
            }
        }
        .frame(width: 140, height: rowHeight * 3)
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.3),
                    .init(color: .black, location: 0.7),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .contentShape(Rectangle())
        .gesture(dragGesture)
        .accessibilityElement()
        .accessibilityLabel("Tempo")
        .accessibilityValue("\(Int(bpm)) BPM")
        .accessibilityAdjustableAction(adjust)
    }

    private func commit(_ value: Int, hitLimit: Bool) {
        let target = min(max(value, range.lowerBound), range.upperBound)
        guard target != Int(bpm) else {
            if hitLimit { haptics.limit() }
            return
        }
        bpm = Double(target)
        haptics.notch(at: target, limit: target == range.lowerBound || target == range.upperBound)
    }

    // Tap steps once, holding repeats and speeds up the longer the finger stays down
    private func beginRepeat(_ direction: Int) {
        haptics.prepare()
        commit(Int(bpm) + direction, hitLimit: true)
        repeatTask?.cancel()
        repeatTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 380_000_000)
            var held = 0
            while !Task.isCancelled {
                let step = held > 24 ? 5 : 1
                let current = Int(bpm)
                let snapped = step == 1 ? current + direction : (direction > 0 ? (current / 5 + 1) * 5 : ((current - 1) / 5) * 5)
                commit(snapped, hitLimit: true)
                held += 1
                let interval = held > 24 ? 140_000_000 : max(45_000_000, 110_000_000 - UInt64(held) * 4_000_000)
                try? await Task.sleep(nanoseconds: UInt64(interval))
            }
        }
    }

    private func endRepeat() {
        repeatTask?.cancel()
        repeatTask = nil
    }
}

// Large round key that reports press and release itself, so tap and hold never fight each other
private struct StepperKey: View {
    let symbol: String
    var size: CGFloat = 60
    let onPress: (Bool) -> Void

    @State private var pressed = false

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size > 50 ? 22 : 15, weight: .semibold))
            .foregroundColor(Color.textPrimary)
            .frame(width: size, height: size)
            .background(
                Circle().fill(pressed ? Color.surfacePressed : Color.surface)
            )
            .scaleEffect(pressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.08), value: pressed)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !pressed else { return }
                        pressed = true
                        onPress(true)
                    }
                    .onEnded { _ in
                        pressed = false
                        onPress(false)
                    }
            )
            .accessibilityLabel(symbol == "plus" ? "Increase tempo" : "Decrease tempo")
            .accessibilityAddTraits(.isButton)
    }
}

// Detent feel: a light tick per BPM, a firmer click on every tenth, a hard bump at the end stops
private final class TempoHaptics {
    private let tick = UISelectionFeedbackGenerator()
    private let ten = UIImpactFeedbackGenerator(style: .rigid)
    private let stop = UIImpactFeedbackGenerator(style: .heavy)
    private var lastLimitBump: CFTimeInterval = 0

    func prepare() {
        tick.prepare()
        ten.prepare()
        stop.prepare()
    }

    func notch(at value: Int, limit: Bool) {
        if limit {
            stop.impactOccurred(intensity: 0.9)
        } else if value % 10 == 0 {
            ten.impactOccurred(intensity: 0.8)
        } else {
            tick.selectionChanged()
        }
        tick.prepare()
    }

    func limit() {
        let now = CACurrentMediaTime()
        guard now - lastLimitBump > 0.25 else { return }
        lastLimitBump = now
        stop.impactOccurred(intensity: 0.6)
    }
}
