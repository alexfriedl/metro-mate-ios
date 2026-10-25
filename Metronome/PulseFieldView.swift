import SwiftUI
import CoreMotion
import UIKit
import QuartzCore

enum PulseClock {
    // A frame drawn now reaches the display roughly one refresh later
    static let displayLead: CFTimeInterval = 1.0 / 60.0

    static func now(for date: Date) -> CFTimeInterval {
        CACurrentMediaTime() + max(0, date.timeIntervalSinceNow) + displayLead
    }

    static let accent = Color(hex: "#F54206")
    static let light = Color(hex: "#DDDDDD")

    // Accents carry the groove, subdivisions get quieter the denser they are
    static func weight(of event: BeatEvent) -> Double {
        if event.isTap { return 0.8 }
        let density = min(1, max(0.35, event.interval / 0.22))
        return event.accent ? 1.0 : 0.3 * density
    }

    // Instant attack, decay scaled to the beat so fast tempos never smear into a blur
    static func punch(of event: BeatEvent, at time: CFTimeInterval) -> Double {
        let age = time - event.hostTime
        guard age >= 0 else { return 0 }
        let tau = min(0.11, max(0.035, event.interval * 0.3))
        return exp(-age / tau)
    }
}

// How the phone is held: the field behaves like a place behind the screen, its horizon stays level with the real world
final class DeviceTilt: ObservableObject {
    static let shared = DeviceTilt()

    // True while the phone is being moved, wakes the field up even when nothing plays
    @Published private(set) var isMoving = false

    // Sideways lean in radians, 0 when the phone is held upright
    private(set) var roll: Double = 0
    // Forward and back tilt relative to how the phone is usually held
    private(set) var pitch: Double = 0

    private let motion = CMMotionManager()
    private var basePitch: Double?
    private var lastMove: TimeInterval = 0
    private var running = false

    func start() {
        guard !running, motion.isDeviceMotionAvailable, !UIAccessibility.isReduceMotionEnabled else { return }
        running = true
        motion.deviceMotionUpdateInterval = 1.0 / 60.0
        motion.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let self, let gravity = data?.gravity else { return }
            let rawRoll = atan2(gravity.x, -gravity.y)
            let rawPitch = asin(max(-1, min(1, gravity.z)))
            if self.basePitch == nil { self.basePitch = rawPitch }
            // Only the forward tilt adapts to the grip, very slowly; the sideways lean stays absolute
            self.basePitch! += (rawPitch - self.basePitch!) * 0.0008
            let previousRoll = self.roll, previousPitch = self.pitch
            self.roll += (rawRoll - self.roll) * 0.35
            self.pitch += ((rawPitch - self.basePitch!) - self.pitch) * 0.35
            let now = ProcessInfo.processInfo.systemUptime
            if abs(self.roll - previousRoll) + abs(self.pitch - previousPitch) > 0.002 {
                self.lastMove = now
                if !self.isMoving { self.isMoving = true }
            } else if self.isMoving && now - self.lastMove > 0.6 {
                self.isMoving = false
            }
        }
    }

    func stop() {
        guard running else { return }
        running = false
        motion.stopDeviceMotionUpdates()
        basePitch = nil
        roll = 0
        pitch = 0
        isMoving = false
    }
}

// Remembers where the flowing surface stopped, so it freezes in place instead of jumping back
final class FlowMemory {
    var offset: Double = 0
    var base: Double = 0
    var lastQuarters: Double = 0
}

struct PulseFieldView: View {
    let timeline: BeatTimeline
    let isPlaying: Bool
    let tapCount: Int

    @State private var lingering = false
    @State private var lingerTask: Task<Void, Never>?
    @State private var flow = FlowMemory()
    @ObservedObject private var tilt = DeviceTilt.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        // Paused whenever nothing moves, so an idle screen costs no frames at all
        // Also wakes up while the phone is tilted, at a lower frame rate when nothing plays
        TimelineView(.animation(minimumInterval: isPlaying || lingering ? nil : 1.0 / 30.0,
                                paused: !(isPlaying || lingering || tilt.isMoving))) { context in
            let time = PulseClock.now(for: context.date)
            Canvas { canvas, size in
                WaveMesh(timeline: timeline, time: time, flow: flow).draw(in: &canvas, size: size)
            }
            .drawingGroup()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onChange(of: isPlaying) { playing in
            if !playing { linger() }
        }
        // The motion sensor runs while the app is in front, so tilting moves the field at any time
        .onAppear { DeviceTilt.shared.start() }
        .onDisappear { DeviceTilt.shared.stop() }
        .onChange(of: scenePhase) { phase in
            phase == .active ? DeviceTilt.shared.start() : DeviceTilt.shared.stop()
        }
        .onChange(of: tapCount) { count in
            if count > 0 { linger() }
        }
    }

    // Keep rendering briefly after the last beat or tap so the waves can settle
    private func linger() {
        lingerTask?.cancel()
        lingering = true
        lingerTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            if !Task.isCancelled { lingering = false }
        }
    }
}

// A perspective surface of connected dots that flows toward the viewer one row per quarter note,
// every played note sends a wave through it
struct WaveMesh {
    private struct Wave {
        let front: Double
        let strength: Double
        let accent: Bool
    }

    private static let columns = 57
    private static let rows = 40
    private static let spacing: Double = 0.32
    private static let nearZ: Double = 0.9
    private static let cameraHeight: Double = 1.35
    private static let waveOrigin: (x: Double, z: Double) = (0, 3.2)
    private static let waveSpeed: Double = 5.5
    private static let alphaLevels = 8

    let time: CFTimeInterval
    private let flowRows: Double
    private let waves: [Wave]
    private let bounce: Double
    private let accentHit: Double

    init(timeline: BeatTimeline, time: CFTimeInterval, flow: FlowMemory) {
        self.time = time
        let events = timeline.recent(at: time, limit: 8)

        if let step = events.first(where: { !$0.isTap }) {
            if step.quarters + 1 < flow.lastQuarters { flow.base = flow.offset - step.quarters * 0.5 }
            flow.lastQuarters = step.quarters
            let within = min(1.5, (time - step.hostTime) / step.quarterLength)
            flow.offset = flow.base + (step.quarters + within) * 0.5
        }
        flowRows = flow.offset

        var waves: [Wave] = []
        for event in events where event.audible && waves.count < 5 {
            let age = time - event.hostTime
            guard age < 2.2 else { continue }
            waves.append(Wave(front: age * Self.waveSpeed, strength: PulseClock.weight(of: event) * exp(-age / 0.45), accent: event.accent))
        }
        self.waves = waves

        if let hit = events.first(where: { $0.audible }) {
            bounce = PulseClock.weight(of: hit) * PulseClock.punch(of: hit, at: time)
            accentHit = hit.accent ? PulseClock.punch(of: hit, at: time) : 0
        } else {
            bounce = 0
            accentHit = 0
        }
    }

    private func height(x: Double, z: Double, worldZ: Double) -> (height: Double, crest: Double, accent: Double) {
        let t = time.truncatingRemainder(dividingBy: 3600)
        var h = 0.08 * sin(x * 0.55 + worldZ * 0.32 + t * 0.35)
            + 0.05 * sin(worldZ * 0.8 - x * 0.25 - t * 0.45)

        var crest = 0.0
        var accent = 0.0
        let dx = x - Self.waveOrigin.x
        let dz = z - Self.waveOrigin.z
        let distance = sqrt(dx * dx + dz * dz)
        for wave in waves {
            let offset = distance - wave.front
            guard abs(offset) < 3 else { continue }
            let envelope = exp(-offset * offset / 0.9)
            h += wave.strength * 0.85 * cos(offset * 2.4) * envelope
            let peak = wave.strength * envelope
            crest = max(crest, peak)
            if wave.accent { accent = max(accent, peak) }
        }

        // The whole surface jumps on the hit, sharp attack, fast settle
        h += bounce * 0.38 * exp(-z * 0.08)
        return (h, min(crest, 1), min(accent, 1))
    }

    func draw(in canvas: inout GraphicsContext, size: CGSize) {
        let focal = size.width * 0.95
        // The horizon counter-rotates against the lean, damped, and moves with the forward tilt
        let tilt = DeviceTilt.shared
        let counterRotation = max(-0.4, min(0.4, -tilt.roll * 0.55))
        let horizon = size.height * (0.30 + max(-0.12, min(0.12, tilt.pitch * 0.35)))
        let cameraX = tilt.roll * 0.35
        let cameraHeight = Self.cameraHeight
        canvas.translateBy(x: size.width / 2, y: size.height * 0.45)
        canvas.rotate(by: .radians(counterRotation))
        canvas.translateBy(x: -size.width / 2, y: -size.height * 0.45)
        let centerX = size.width / 2
        let fraction = flowRows - floor(flowRows)
        let columns = Self.columns
        let rows = Self.rows

        var points = [CGPoint](repeating: .zero, count: columns * rows)
        var alphas = [Double](repeating: 0, count: columns * rows)
        var accents = [Double](repeating: 0, count: columns * rows)
        var radii = [CGFloat](repeating: 0, count: columns * rows)

        for row in 0..<rows {
            let z = Self.nearZ + (Double(row) - fraction * 2) * Self.spacing
            let worldZ = z + flowRows * Self.spacing * 2
            // Fade in at the horizon, fade out as rows slide past the viewer
            let fog = exp(-max(z, 0.1) * 0.13)
            let entry = min(1, max(0, (z - Self.nearZ + 0.4) / 0.9))
            for column in 0..<columns {
                let x = (Double(column) - Double(columns - 1) / 2) * Self.spacing
                let index = row * columns + column
                guard z > 0.25 else { continue }
                let sample = height(x: x, z: z, worldZ: worldZ)
                let screen = CGPoint(
                    x: centerX + (x - cameraX) / z * focal,
                    y: horizon + (cameraHeight - sample.height) / z * focal
                )
                points[index] = screen
                alphas[index] = fog * entry * min(1, (0.5 + 0.8 * sample.crest) * (1 + 0.9 * bounce))
                accents[index] = max(sample.accent, accentHit * exp(-z * 0.25))
                radii[index] = CGFloat(min(2.2, max(0.7, 1.6 / z))) * CGFloat(1 + 0.8 * sample.crest + 0.5 * bounce)
            }
        }

        let bounds = CGRect(origin: .zero, size: size).insetBy(dx: -size.width * 0.35, dy: -size.height * 0.15)
        let levels = Self.alphaLevels
        var lightLines = [Path](repeating: Path(), count: levels)
        var accentLines = [Path](repeating: Path(), count: levels)
        var lightDots = [Path](repeating: Path(), count: levels)
        var accentDots = [Path](repeating: Path(), count: levels)
        var glow = Path()
        var accentGlow = Path()

        func level(_ alpha: Double) -> Int { min(levels - 1, Int(alpha * Double(levels))) }

        for row in 0..<rows {
            for column in 0..<columns {
                let index = row * columns + column
                let alpha = alphas[index]
                guard alpha > 0.02 else { continue }
                let point = points[index]
                guard bounds.contains(point) else { continue }
                let isAccent = accents[index] > 0.35

                // Mesh lines to the right and to the next row, they light up with the wave
                for neighbor in [column + 1 < columns ? index + 1 : -1, row + 1 < rows ? index + columns : -1] where neighbor >= 0 {
                    let other = alphas[neighbor]
                    guard other > 0.02 else { continue }
                    let lineAlpha = min(alpha, other) * 0.3
                    if isAccent || accents[neighbor] > 0.35 {
                        accentLines[level(lineAlpha)].move(to: point)
                        accentLines[level(lineAlpha)].addLine(to: points[neighbor])
                    } else {
                        lightLines[level(lineAlpha)].move(to: point)
                        lightLines[level(lineAlpha)].addLine(to: points[neighbor])
                    }
                }

                let radius = radii[index]
                let dot = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
                // Sub-pixel dots look identical as squares and are far cheaper to fill
                if isAccent {
                    if radius < 1.1 { accentDots[level(alpha)].addRect(dot) } else { accentDots[level(alpha)].addEllipse(in: dot) }
                } else {
                    if radius < 1.1 { lightDots[level(alpha)].addRect(dot) } else { lightDots[level(alpha)].addEllipse(in: dot) }
                }
                if alpha > 0.6 {
                    let halo = dot.insetBy(dx: -radius * 2.2, dy: -radius * 2.2)
                    if isAccent { accentGlow.addEllipse(in: halo) } else { glow.addEllipse(in: halo) }
                }
            }
        }

        canvas.blendMode = .plusLighter
        canvas.fill(glow, with: .color(PulseClock.light.opacity(0.07)))
        canvas.fill(accentGlow, with: .color(PulseClock.accent.opacity(0.16)))
        canvas.blendMode = .normal

        for index in 0..<levels {
            let opacity = (Double(index) + 0.5) / Double(levels)
            canvas.stroke(lightLines[index], with: .color(PulseClock.light.opacity(opacity)), lineWidth: 0.6)
            canvas.stroke(accentLines[index], with: .color(PulseClock.accent.opacity(opacity)), lineWidth: 0.7)
            canvas.fill(lightDots[index], with: .color(PulseClock.light.opacity(opacity)))
            canvas.fill(accentDots[index], with: .color(PulseClock.accent.opacity(opacity)))
        }
    }
}
