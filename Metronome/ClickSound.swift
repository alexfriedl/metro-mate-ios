import AVFoundation

// Click voices, synthesized at launch so they stay tight, royalty free and tiny
enum ClickSound: String, CaseIterable, Identifiable, Codable {
    case cowbell
    case classic
    case clean
    case claves
    case pocket
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
        case .clean: return String(localized: "Pure tone, high on accents")
        case .classic: return String(localized: "Wooden block, the classic metronome knock")
        case .claves: return String(localized: "Bright hardwood claves")
        case .pocket: return String(localized: "Snare on accents, hi-hat in between")
        case .cowbell: return String(localized: "Open bell on accents, muted in between")
        case .punch: return String(localized: "Bass drum on accents, hi-hat in between")
        case .deep: return String(localized: "Bass drum on accents, soft shaker in between")
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

    // Bundled samples by name, imported ones as "user/<file>" from the app's own sound folder
    static func url(for name: String) -> URL? {
        if name.hasPrefix(UserSounds.prefix) {
            return UserSounds.directory.appendingPathComponent(String(name.dropFirst(UserSounds.prefix.count)))
        }
        return Bundle.main.url(forResource: name, withExtension: "wav")
            ?? Bundle.main.url(forResource: name, withExtension: "wav", subdirectory: "Sounds")
    }

    static func sample(_ name: String, gain: Float, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard let url = url(for: name), let buffer = decode(url, to: format) else {
            if !name.hasPrefix(UserSounds.prefix) { assertionFailure("Sample \(name) could not be loaded") }
            return nil
        }
        // Imported files come at any level, bring them to the same peak as the bundled samples
        var scale = gain
        if name.hasPrefix(UserSounds.prefix) {
            var peak: Float = 0
            for channel in 0..<Int(format.channelCount) {
                guard let data = buffer.floatChannelData?[channel] else { continue }
                for frame in 0..<Int(buffer.frameLength) { peak = max(peak, abs(data[frame])) }
            }
            if peak > 0.001 { scale *= 0.9 / peak }
        }
        for channel in 0..<Int(format.channelCount) {
            guard let data = buffer.floatChannelData?[channel] else { continue }
            for frame in 0..<Int(buffer.frameLength) { data[frame] *= scale }
        }
        return buffer
    }

    // Reads any audio file iOS can decode and converts it to the engine format
    static func decode(_ url: URL, to format: AVAudioFormat, maxSeconds: Double = 2) -> AVAudioPCMBuffer? {
        guard let file = try? AVAudioFile(forReading: url) else { return nil }
        let frames = AVAudioFrameCount(min(Double(file.length), maxSeconds * file.processingFormat.sampleRate))
        guard frames > 0, let source = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: frames),
              (try? file.read(into: source, frameCount: frames)) != nil else { return nil }
        if source.format == format { return source }
        guard let converter = AVAudioConverter(from: source.format, to: format) else { return nil }
        let capacity = AVAudioFrameCount(Double(source.frameLength) * format.sampleRate / source.format.sampleRate) + 1024
        guard let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else { return nil }
        var fed = false
        var error: NSError?
        converter.convert(to: output, error: &error) { _, status in
            if fed {
                status.pointee = .endOfStream
                return nil
            }
            fed = true
            status.pointee = .haveData
            return source
        }
        return error == nil ? output : nil
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
