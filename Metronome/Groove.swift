import AVFoundation
import Combine
import QuartzCore

enum DrumVoice: CaseIterable {
    case hiHat, snare, kick

    var label: String {
        switch self {
        case .hiHat: return "HH"
        case .snare: return "SN"
        case .kick: return "BD"
        }
    }
}

enum DrumHit {
    case normal, accent, ghost, open
}

enum GrooveCategory: String, CaseIterable, Identifiable {
    case classics, foundations, funk, linear, hiHat, kick, shuffle, hands, chops

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classics: return "All-Time Classics"
        case .foundations: return "Foundations"
        case .funk: return "Funk & Ghost Notes"
        case .linear: return "Linear Grooves"
        case .hiHat: return "Hi-Hat Work"
        case .kick: return "Kick Independence"
        case .shuffle: return "Shuffle & Triplets"
        case .hands: return "Accent Studies"
        case .chops: return "Chops"
        }
    }

    var subtitle: String {
        switch self {
        case .classics: return "Famous grooves in their best known form, one bar"
        case .foundations: return "Rock, pop and four on the floor"
        case .funk: return "Sixteenth feels with quiet ghost notes"
        case .linear: return "One limb at a time, never two together"
        case .hiHat: return "Accents and open hats on the right hand"
        case .kick: return "Kick patterns against a steady top"
        case .shuffle: return "Triplet grid, swing and half-time shuffle"
        case .hands: return "Snare accent exercises over a feathered kick"
        case .chops: return "Rudiments and hand-foot combinations with sticking"
        }
    }

    var symbol: String {
        switch self {
        case .classics: return "star"
        case .foundations: return "square.stack.3d.up"
        case .funk: return "waveform"
        case .linear: return "arrow.right"
        case .hiHat: return "sparkles"
        case .kick: return "circle.circle"
        case .shuffle: return "music.note"
        case .hands: return "hand.raised"
        case .chops: return "bolt"
        }
    }

    var grooves: [Groove] { Groove.library.filter { $0.category == self } }
}

// Original grooves and exercises written for Metro Mate, one bar each
struct Groove: Identifiable {
    let id: String
    let category: GrooveCategory
    let title: String
    let level: Int
    let focus: String
    let tempo: Int
    // One character per step: x hit, X accent, g ghost, o open hi-hat, - rest; 16 steps for sixteenths, 12 for triplets
    let hiHat: String
    let snare: String
    let kick: String
    // Optional sticking line, one letter per step: R right, L left, K kick
    let sticking: String

    var steps: Int { snare.count }
    var stepsPerBeat: Int { steps / 4 }
    var isTriplet: Bool { stepsPerBeat == 3 }

    init(_ id: String, _ category: GrooveCategory, _ title: String, level: Int, tempo: Int, focus: String,
         hiHat: String, snare: String, kick: String, sticking: String = "") {
        self.id = id
        self.category = category
        self.title = title
        self.level = level
        self.tempo = tempo
        self.focus = focus
        self.hiHat = hiHat
        self.snare = snare
        self.kick = kick
        self.sticking = sticking
    }

    // Linear grooves read better as one sequence: K kick, H hat, O open hat, S snare, A accent, G ghost, - rest
    static func linear(_ id: String, _ title: String, level: Int, tempo: Int, focus: String, sequence: String) -> Groove {
        func line(_ map: [Character: Character]) -> String {
            String(sequence.map { map[$0] ?? "-" })
        }
        return Groove(id, .linear, title, level: level, tempo: tempo, focus: focus,
                      hiHat: line(["H": "x", "O": "o"]),
                      snare: line(["S": "x", "A": "X", "G": "g"]),
                      kick: line(["K": "x"]))
    }

    func line(for voice: DrumVoice) -> String {
        switch voice {
        case .hiHat: return hiHat
        case .snare: return snare
        case .kick: return kick
        }
    }

    // R or L when the step is played by a hand in a sticking exercise
    func hand(at step: Int) -> Character? {
        guard !sticking.isEmpty, step < sticking.count else { return nil }
        let letter = Array(sticking)[step]
        return letter == "R" || letter == "L" ? letter : nil
    }

    func uses(_ voice: DrumVoice) -> Bool {
        line(for: voice).contains { $0 != "-" }
    }

    func hit(_ voice: DrumVoice, at step: Int) -> DrumHit? {
        let line = line(for: voice)
        guard step < line.count else { return nil }
        switch line[line.index(line.startIndex, offsetBy: step)] {
        case "x": return .normal
        case "X": return .accent
        case "g": return .ghost
        case "o": return .open
        default: return nil
        }
    }
}

// Plays a groove sample accurately, drums only
final class GroovePlayer: ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var currentStep = -1
    @Published var tempo: Double = 88 {
        didSet {
            queue.async { [self] in pendingTempo = tempo }
            if isPlaying { PracticeLog.shared.updateTempo(Int(tempo)) }
        }
    }
    private let engine = AVAudioEngine()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
    private var players: [AVAudioPlayerNode] = []
    private let queue = DispatchQueue(label: "metromate.groove", qos: .userInteractive)
    private var buffers: [String: AVAudioPCMBuffer] = [:]

    // Scheduler state, only touched on `queue`
    private var groove: Groove?
    private var pendingTempo: Double = 88
    private var timer: DispatchSourceTimer?
    private var nextSample: Double = 0
    private var step = 0
    private var generation = 0

    init() {
        let sampled: [String: AVAudioPCMBuffer?] = [
            // Each dynamic is its own recorded stroke, so accents sound harder, not just louder
            "hat": Synth.sample("hihat", gain: 0.45, format: format),
            "hatAccent": Synth.sample("hihat-accent", gain: 0.8, format: format),
            "open": Synth.sample("hihat-open", gain: 0.55, format: format),
            "snare": Synth.sample("snare", gain: 0.55, format: format),
            "snareAccent": Synth.sample("snare-accent", gain: 1.0, format: format),
            "ghost": Synth.sample("snare-ghost", gain: 0.3, format: format),
            "kick": Synth.sample("kick", gain: 1.0, format: format),
            "kickFeather": Synth.sample("kick-soft", gain: 0.45, format: format),
            // Hand exercises sound like a practice pad, the left hand a touch lower so both hands are told apart
            "right": Synth.sample("pad-right", gain: 0.42, format: format),
            "rightAccent": Synth.sample("pad-right-accent", gain: 0.9, format: format),
            "left": Synth.sample("pad-left", gain: 0.42, format: format),
            "leftAccent": Synth.sample("pad-left-accent", gain: 0.9, format: format),
            "kickTight": Synth.sample("kick-tight", gain: 0.9, format: format)
        ]
        buffers = sampled.compactMapValues { $0 }
        // One node per voice so overlapping hits never queue behind each other
        for _ in 0..<4 {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            players.append(player)
        }
        engine.prepare()
        volumeObserver = MetronomeManager.shared.$volume.sink { [weak self] volume in
            self?.engine.mainMixerNode.outputVolume = Float(volume)
        }
    }

    func play(_ groove: Groove) {
        MetronomeManager.shared.stopIfPlaying()
        PracticeLog.shared.begin(.groove, title: groove.title, detail: groove.category.title, bpm: Int(tempo))
        isPlaying = true
        currentStep = -1
        queue.async { [self] in
            self.groove = groove
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                if !engine.isRunning { try engine.start() }
            } catch {
                print("Failed to start groove engine: \(error)")
                return
            }
            generation += 1
            players.forEach { $0.stop(); $0.play() }
            nextSample = 0.05 * format.sampleRate
            step = 0
            scheduleAhead()
            let source = DispatchSource.makeTimerSource(queue: queue)
            source.schedule(deadline: .now() + .milliseconds(20), repeating: .milliseconds(20), leeway: .milliseconds(5))
            source.setEventHandler { [weak self] in self?.scheduleAhead() }
            source.resume()
            timer?.cancel()
            timer = source
        }
    }

    func stop() {
        if isPlaying { PracticeLog.shared.end() }
        isPlaying = false
        currentStep = -1
        queue.async { [self] in
            generation += 1
            timer?.cancel()
            timer = nil
            players.forEach { $0.stop() }
            engine.pause()
        }
    }

    private func scheduleAhead() {
        guard let groove, let reference = players.first else { return }
        let rate = format.sampleRate
        var current: Double = 0
        if let nodeTime = reference.lastRenderTime, nodeTime.isSampleTimeValid,
           let playerTime = reference.playerTime(forNodeTime: nodeTime) {
            current = Double(playerTime.sampleTime)
        }
        let interval = 60.0 / pendingTempo / Double(groove.stepsPerBeat)
        let latency = engine.outputNode.presentationLatency
        while nextSample < current {
            nextSample += interval * rate
            step += 1
        }
        while nextSample < current + 0.12 * rate {
            let index = step % groove.steps
            let when = AVAudioTime(sampleTime: AVAudioFramePosition(nextSample.rounded()), atRate: rate)

            switch groove.hit(.hiHat, at: index) {
            case .open: schedule("open", on: 0, at: when)
            case .accent: schedule("hatAccent", on: 0, at: when)
            case .some: schedule("hat", on: 0, at: when)
            case nil: break
            }
            if let hand = groove.hand(at: index) {
                let accented = groove.hit(.snare, at: index) == .accent
                schedule(hand == "R" ? (accented ? "rightAccent" : "right") : (accented ? "leftAccent" : "left"), on: 1, at: when)
            } else {
            switch groove.hit(.snare, at: index) {
            case .ghost: schedule("ghost", on: 1, at: when)
            case .accent: schedule("snareAccent", on: 1, at: when)
            case .some: schedule("snare", on: 1, at: when)
            case nil: break
            }
            }
            if groove.hit(.kick, at: index) != nil {
                let kick = groove.category == .hands ? "kickFeather" : (groove.sticking.isEmpty ? "kick" : "kickTight")
                schedule(kick, on: 2, at: when)
            }

            let host: CFTimeInterval
            if let nodeTime = reference.nodeTime(forPlayerTime: when), nodeTime.isHostTimeValid {
                host = AVAudioTime.seconds(forHostTime: nodeTime.hostTime) + latency
            } else {
                host = CACurrentMediaTime() + (nextSample - current) / rate + latency
            }
            let token = generation
            DispatchQueue.main.asyncAfter(deadline: .now() + max(0, host - CACurrentMediaTime())) { [weak self] in
                guard let self, self.isPlaying, token == self.generation else { return }
                self.currentStep = index
            }

            nextSample += interval * rate
            step += 1
        }
    }

    private var trimmed: [String: AVAudioPCMBuffer] = [:]
    private var volumeObserver: AnyCancellable?

    // A hit longer than the step would push every later hit on that voice late, so cut it to fit
    private func schedule(_ name: String, on node: Int, at when: AVAudioTime) {
        guard let source = buffers[name] else { return }
        let limit = AVAudioFrameCount(60.0 / pendingTempo / Double(groove?.stepsPerBeat ?? 4) * format.sampleRate * 0.95)
        var buffer = source
        if source.frameLength > limit {
            let key = "\(name)-\(limit)"
            if let cached = trimmed[key] {
                buffer = cached
            } else if let copy = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: limit),
                      let src = source.floatChannelData, let dst = copy.floatChannelData {
                copy.frameLength = limit
                let fade = min(Int(limit), 256)
                for channel in 0..<Int(format.channelCount) {
                    for frame in 0..<Int(limit) {
                        let tail = Int(limit) - frame
                        dst[channel][frame] = src[channel][frame] * (tail < fade ? Float(tail) / Float(fade) : 1)
                    }
                }
                trimmed[key] = copy
                buffer = copy
            }
        }
        players[node].scheduleBuffer(buffer, at: when, options: [], completionHandler: nil)
    }
}
