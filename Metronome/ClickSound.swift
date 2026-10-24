import AVFoundation

// Click voices, synthesized at launch so they stay tight, royalty free and tiny
enum ClickSound: String, CaseIterable, Identifiable, Codable {
    case clean
    case classic
    case claves
    case pocket
    case cowbell
    case punch
    case deep

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clean: return "Clean"
        case .classic: return "Classic"
        case .claves: return "Claves"
        case .pocket: return "Pocket"
        case .cowbell: return "Cowbell"
        case .punch: return "Punch"
        case .deep: return "Deep"
        }
    }

    var subtitle: String {
        switch self {
        case .clean: return "Pure tone, high on accents"
        case .classic: return "Wooden block, the classic metronome knock"
        case .claves: return "Bright hardwood claves"
        case .pocket: return "Snare on accents, hi-hat in between"
        case .cowbell: return "Open bell on accents, muted in between"
        case .punch: return "Bass drum on accents, hi-hat in between"
        case .deep: return "Bass drum on accents, soft shaker in between"
        }
    }

    // Accent and normal voices, recorded samples except the clean tone
    func buffers(format: AVAudioFormat) -> (accent: AVAudioPCMBuffer, normal: AVAudioPCMBuffer) {
        let voices: (accent: AVAudioPCMBuffer?, normal: AVAudioPCMBuffer?)
        switch self {
        case .clean:
            return (Synth.beep(frequency: 1760, gain: 0.95, format: format),
                    Synth.beep(frequency: 1320, gain: 0.7, format: format))
        case .classic: voices = (Synth.sample("woodblock-accent", gain: 1, format: format), Synth.sample("woodblock", gain: 0.75, format: format))
        case .claves: voices = (Synth.sample("claves-accent", gain: 1, format: format), Synth.sample("claves", gain: 0.7, format: format))
        case .pocket: voices = (Synth.sample("snare-accent", gain: 0.9, format: format), Synth.sample("hihat", gain: 0.6, format: format))
        case .cowbell: voices = (Synth.sample("cowbell-accent", gain: 0.85, format: format), Synth.sample("cowbell", gain: 0.7, format: format))
        case .punch: voices = (Synth.sample("kick", gain: 1, format: format), Synth.sample("hihat-accent", gain: 0.6, format: format))
        case .deep: voices = (Synth.sample("kick", gain: 1, format: format), Synth.sample("shaker", gain: 0.7, format: format))
        }
        guard let accent = voices.accent, let normal = voices.normal else { return ClickSound.clean.buffers(format: format) }
        return (accent, normal)
    }
}

// Samples in Sounds/ come from the Versilian Community Sample Library (CC0, public domain)
enum Synth {
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

    static func sample(_ name: String, gain: Float, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let url = Bundle.main.url(forResource: name, withExtension: "wav")
            ?? Bundle.main.url(forResource: name, withExtension: "wav", subdirectory: "Sounds")
        guard let url, let file = try? AVAudioFile(forReading: url),
              file.processingFormat.sampleRate == format.sampleRate,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(file.length)),
              (try? file.read(into: buffer)) != nil else {
            assertionFailure("Sample \(name) could not be loaded")
            return nil
        }
        for channel in 0..<Int(format.channelCount) {
            guard let data = buffer.floatChannelData?[channel] else { continue }
            for frame in 0..<Int(buffer.frameLength) { data[frame] *= gain }
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
}
