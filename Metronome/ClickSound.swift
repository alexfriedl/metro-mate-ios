import AVFoundation

// Click voices, synthesized at launch so they stay tight, royalty free and tiny
enum ClickSound: String, CaseIterable, Identifiable, Codable {
    case clean
    case classic
    case woodblock
    case pocket
    case punch
    case deep

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clean: return "Clean"
        case .woodblock: return "Woodblock"
        case .pocket: return "Pocket"
        case .classic: return "Classic"
        case .punch: return "Punch"
        case .deep: return "Deep"
        }
    }

    var subtitle: String {
        switch self {
        case .clean: return "Short, neutral beep"
        case .woodblock: return "Warm wooden knock"
        case .pocket: return "Cross-stick on accents, hi-hat in between"
        case .classic: return "Mechanical pendulum, bell on the one"
        case .punch: return "Tight kick on accents, bright ride in between"
        case .deep: return "Round low kick on accents, soft shaker in between"
        }
    }

    // Returns accent and normal buffers in the given format
    func buffers(format: AVAudioFormat) -> (accent: AVAudioPCMBuffer, normal: AVAudioPCMBuffer) {
        switch self {
        case .clean:
            return (Synth.beep(frequency: 1760, gain: 0.95, format: format),
                    Synth.beep(frequency: 1320, gain: 0.7, format: format))
        case .woodblock:
            return (Synth.woodblock(low: 1050, high: 2700, gain: 0.75, format: format),
                    Synth.woodblock(low: 820, high: 2100, gain: 0.55, format: format))
        case .pocket:
            return (Synth.crossStick(gain: 0.75, format: format),
                    Synth.hiHat(gain: 0.45, format: format))
        case .classic:
            return (Synth.pendulum(bell: true, gain: 0.65, format: format),
                    Synth.pendulum(bell: false, gain: 0.6, format: format))
        case .punch:
            return (Synth.kick(start: 260, end: 60, pitchDecay: 0.025, decay: 0.06, drive: 1.6, gain: 0.85, format: format),
                    Synth.ride(gain: 0.4, format: format))
        case .deep:
            return (Synth.kick(start: 150, end: 50, pitchDecay: 0.04, decay: 0.12, drive: 1.3, gain: 0.8, format: format),
                    Synth.shaker(gain: 0.6, format: format))
        }
    }
}

private enum Synth {
    static func render(seconds: Double, format: AVAudioFormat, sample: (Double, Int) -> Double) -> AVAudioPCMBuffer {
        let frames = AVAudioFrameCount(format.sampleRate * seconds)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
        buffer.frameLength = frames
        var mono = [Float](repeating: 0, count: Int(frames))
        for frame in 0..<Int(frames) {
            mono[frame] = Float(sample(Double(frame) / format.sampleRate, frame))
        }
        // Tiny fade at the end so no buffer ever ends on a click
        let fade = min(64, mono.count)
        for i in 0..<fade { mono[mono.count - 1 - i] *= Float(i) / Float(fade) }
        for channel in 0..<Int(format.channelCount) {
            guard let data = buffer.floatChannelData?[channel] else { continue }
            mono.withUnsafeBufferPointer { data.update(from: $0.baseAddress!, count: mono.count) }
        }
        return buffer
    }

    static func attack(_ t: Double, _ seconds: Double = 0.0008) -> Double {
        min(1, t / seconds)
    }

    static func beep(frequency: Double, gain: Double, format: AVAudioFormat) -> AVAudioPCMBuffer {
        render(seconds: 0.06, format: format) { t, _ in
            let tone = sin(2 * .pi * frequency * t) + 0.12 * sin(4 * .pi * frequency * t)
            return tone * attack(t) * exp(-t / 0.010) * gain * 0.8
        }
    }

    static func woodblock(low: Double, high: Double, gain: Double, format: AVAudioFormat) -> AVAudioPCMBuffer {
        var noise = Noise()
        return render(seconds: 0.09, format: format) { t, _ in
            let body = sin(2 * .pi * low * t) * exp(-t / 0.02)
            let ring = 0.45 * sin(2 * .pi * high * t) * exp(-t / 0.010)
            let knock = 0.15 * noise.next() * exp(-t / 0.0012)
            return (body + ring + knock) * attack(t) * gain * 0.8
        }
    }

    static func crossStick(gain: Double, format: AVAudioFormat) -> AVAudioPCMBuffer {
        var noise = Noise()
        var lowpass = 0.0
        return render(seconds: 0.11, format: format) { t, _ in
            let raw = noise.next()
            lowpass += 0.35 * (raw - lowpass)
            let snap = (raw - lowpass) * exp(-t / 0.0025) * 0.5
            let shell = sin(2 * .pi * 470 * t) * exp(-t / 0.022) * 0.75
            let rim = sin(2 * .pi * 1720 * t + 0.6) * exp(-t / 0.012) * 0.45
            return (snap + shell + rim) * attack(t, 0.0004) * gain * 0.75
        }
    }

    static func hiHat(gain: Double, format: AVAudioFormat) -> AVAudioPCMBuffer {
        var noise = Noise()
        let partials: [Double] = [205.3, 304.4, 369.6, 522.7, 540.0, 800.0].map { $0 * 6.2 }
        var previous = 0.0
        var previousOut = 0.0
        return render(seconds: 0.07, format: format) { t, _ in
            // Metallic square cluster plus noise, high-passed so only the sizzle remains
            var metal = 0.0
            for partial in partials { metal += sin(2 * .pi * partial * t) >= 0 ? 1 : -1 }
            let raw = metal / 6 * 0.6 + noise.next() * 0.7
            let highpassed = 0.86 * (previousOut + raw - previous)
            previous = raw
            previousOut = highpassed
            return highpassed * attack(t, 0.0003) * exp(-t / 0.012) * gain
        }
    }

    // Wooden escapement tick of a mechanical metronome, the accent rings the bell
    static func pendulum(bell: Bool, gain: Double, format: AVAudioFormat) -> AVAudioPCMBuffer {
        var noise = Noise()
        var previous = 0.0
        return render(seconds: bell ? 0.45 : 0.05, format: format) { t, _ in
            let raw = noise.next()
            let click = (raw - previous) * exp(-t / 0.0008) * 0.35
            previous = raw
            let wood = (sin(2 * .pi * 2450 * t) + 0.6 * sin(2 * .pi * 3900 * t)) * exp(-t / 0.006) * 0.5
            var ring = 0.0
            if bell {
                ring = (sin(2 * .pi * 2093 * t) + 0.5 * sin(2 * .pi * 5233 * t) + 0.25 * sin(2 * .pi * 7680 * t))
                    * exp(-t / 0.12) * 0.35
            }
            return (click + wood + ring) * attack(t, 0.0003) * gain
        }
    }

    // Pitch swept sine with a transient, soft clipped for punch on small speakers
    static func kick(start: Double, end: Double, pitchDecay: Double, decay: Double, drive: Double,
                     gain: Double, format: AVAudioFormat) -> AVAudioPCMBuffer {
        var phase = 0.0
        var noise = Noise()
        let step = 1 / format.sampleRate
        return render(seconds: decay * 4, format: format) { t, _ in
            let frequency = end + (start - end) * exp(-t / pitchDecay)
            phase += 2 * .pi * frequency * step
            let body = (sin(phase) + 0.2 * sin(phase * 2)) * exp(-t / decay)
            let click = (noise.next() * 0.15 + sin(2 * .pi * 1400 * t) * 0.5) * exp(-t / 0.0025)
            return tanh((body + click) * drive) / tanh(drive) * attack(t, 0.0005) * gain
        }
    }

    static func ride(gain: Double, format: AVAudioFormat) -> AVAudioPCMBuffer {
        var noise = Noise()
        var previous = 0.0
        var previousOut = 0.0
        return render(seconds: 0.12, format: format) { t, _ in
            let raw = noise.next()
            let sizzle = 0.9 * (previousOut + raw - previous)
            previous = raw
            previousOut = sizzle
            let ping = (sin(2 * .pi * 3150 * t) + 0.7 * sin(2 * .pi * 4870 * t)) * exp(-t / 0.03) * 0.5
            return (sizzle * exp(-t / 0.008) * 0.45 + ping) * attack(t, 0.0003) * gain
        }
    }

    static func shaker(gain: Double, format: AVAudioFormat) -> AVAudioPCMBuffer {
        var noise = Noise()
        var previous = 0.0
        var previousOut = 0.0
        return render(seconds: 0.11, format: format) { t, _ in
            let raw = noise.next()
            let highpassed = 0.9 * (previousOut + raw - previous)
            previous = raw
            previousOut = highpassed
            // Soft swell then fade, like beads hitting the shell
            let envelope = min(1, t / 0.006) * exp(-t / 0.024)
            return highpassed * envelope * gain
        }
    }

    // Deterministic white noise so every hit sounds identical
    struct Noise {
        private var state: UInt32 = 0x9E3779B9
        mutating func next() -> Double {
            state ^= state << 13
            state ^= state >> 17
            state ^= state << 5
            return Double(state) / Double(UInt32.max) * 2 - 1
        }
    }
}
