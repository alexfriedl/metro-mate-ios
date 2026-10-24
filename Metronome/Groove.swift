import AVFoundation
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

// Original funk exercises written for Metro Mate, one bar of sixteenths each
struct Groove: Identifiable {
    let id: String
    let title: String
    let level: Int
    let focus: String
    let tempo: Int
    // One character per sixteenth: x hit, X accent, g ghost, o open hi-hat, - rest
    let hiHat: String
    let snare: String
    let kick: String

    static let steps = 16

    func hit(_ voice: DrumVoice, at step: Int) -> DrumHit? {
        let line: String
        switch voice {
        case .hiHat: line = hiHat
        case .snare: line = snare
        case .kick: line = kick
        }
        let index = line.index(line.startIndex, offsetBy: step)
        switch line[index] {
        case "x": return .normal
        case "X": return .accent
        case "g": return .ghost
        case "o": return .open
        default: return nil
        }
    }

    static let library: [Groove] = [
        Groove(id: "foundation", title: "Sixteenth Foundation", level: 1,
               focus: "Even sixteenths on the hat, backbeat on 2 and 4",
               tempo: 84,
               hiHat: "xxxxxxxxxxxxxxxx",
               snare: "----X-------X---",
               kick:  "x-----x---x-----"),
        Groove(id: "ghost-pocket", title: "Ghost Note Pocket", level: 1,
               focus: "Quiet ghost notes around a solid backbeat",
               tempo: 88,
               hiHat: "x-x-x-x-x-x-x-x-",
               snare: "--g-X--g-g-gX--g",
               kick:  "x-----x-x-----x-"),
        Groove(id: "open-lift", title: "Open Hat Lift", level: 2,
               focus: "Open the hat on the & of 2 and the a of 4",
               tempo: 92,
               hiHat: "xxxxxxoxxxxxxxox",
               snare: "----X-------X---",
               kick:  "x-x------xx-----"),
        Groove(id: "kick-syncopation", title: "Kick Syncopation", level: 2,
               focus: "Sixteenth note kicks between the hats",
               tempo: 86,
               hiHat: "x-x-x-x-x-x-x-x-",
               snare: "----X--g-g--X--g",
               kick:  "x--x-xx---x-x--x"),
        Groove(id: "linear-one", title: "Linear Sixteenths", level: 3,
               focus: "Never two limbs at once, every note on its own",
               tempo: 80,
               hiHat: "-x-x-x--x-x--x--",
               snare: "--g-X--g---gX--g",
               kick:  "x-----x--x----x-"),
        Groove(id: "displaced", title: "Displaced Backbeat", level: 3,
               focus: "Snare moves off 4 to the a of 3, the bar leans forward",
               tempo: 90,
               hiHat: "xxxxxxxxxxxxxxxx",
               snare: "-g--X-g---gX--g-",
               kick:  "x--x--x---x--x--")
    ]
}

// Plays a groove sample accurately, with the metronome click quietly underneath or muted
final class GroovePlayer: ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var currentStep = -1
    @Published var tempo: Double = 88 { didSet { queue.async { [self] in pendingTempo = tempo } } }
    @Published var clickInBackground = true { didSet { queue.async { [self] in pendingClick = clickInBackground } } }

    private let engine = AVAudioEngine()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
    private var players: [AVAudioPlayerNode] = []
    private let queue = DispatchQueue(label: "metromate.groove", qos: .userInteractive)
    private var buffers: [String: AVAudioPCMBuffer] = [:]

    // Scheduler state, only touched on `queue`
    private var groove: Groove?
    private var pendingTempo: Double = 88
    private var pendingClick = true
    private var timer: DispatchSourceTimer?
    private var nextSample: Double = 0
    private var step = 0
    private var generation = 0

    init() {
        buffers = [
            "hat": Synth.hiHat(gain: 0.5, format: format),
            "hatAccent": Synth.hiHat(gain: 0.75, format: format),
            "open": Synth.openHat(gain: 0.5, format: format),
            "snare": Synth.snare(gain: 0.8, format: format),
            "snareAccent": Synth.snare(gain: 1.0, format: format),
            "ghost": Synth.snare(gain: 0.18, format: format),
            "kick": Synth.kick(start: 150, end: 50, pitchDecay: 0.04, decay: 0.12, drive: 1.3, gain: 0.85, format: format),
            "click": Synth.beep(frequency: 1320, gain: 0.22, format: format),
            "clickOne": Synth.beep(frequency: 1760, gain: 0.3, format: format)
        ]
        // One node per voice so overlapping hits never queue behind each other
        for _ in 0..<4 {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            players.append(player)
        }
        engine.prepare()
    }

    func play(_ groove: Groove) {
        MetronomeManager.shared.stopIfPlaying()
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
        let interval = 60.0 / pendingTempo / 4
        let latency = engine.outputNode.presentationLatency
        while nextSample < current {
            nextSample += interval * rate
            step += 1
        }
        while nextSample < current + 0.12 * rate {
            let index = step % Groove.steps
            let when = AVAudioTime(sampleTime: AVAudioFramePosition(nextSample.rounded()), atRate: rate)

            switch groove.hit(.hiHat, at: index) {
            case .open: schedule("open", on: 0, at: when)
            case .accent: schedule("hatAccent", on: 0, at: when)
            case .some: schedule("hat", on: 0, at: when)
            case nil: break
            }
            switch groove.hit(.snare, at: index) {
            case .ghost: schedule("ghost", on: 1, at: when)
            case .accent: schedule("snareAccent", on: 1, at: when)
            case .some: schedule("snare", on: 1, at: when)
            case nil: break
            }
            if groove.hit(.kick, at: index) != nil { schedule("kick", on: 2, at: when) }
            if pendingClick && index % 4 == 0 { schedule(index == 0 ? "clickOne" : "click", on: 3, at: when) }

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

    // A hit longer than the step would push every later hit on that voice late, so cut it to fit
    private func schedule(_ name: String, on node: Int, at when: AVAudioTime) {
        guard let source = buffers[name] else { return }
        let limit = AVAudioFrameCount(60.0 / pendingTempo / 4 * format.sampleRate * 0.95)
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
