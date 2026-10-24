import AVFoundation
import QuartzCore

// One step of the beat grid, stamped with the moment it reaches the listener's ears
struct BeatEvent {
    let hostTime: CFTimeInterval
    let index: Int
    let beats: Int
    let serial: Int
    let quarters: Double
    let quarterLength: Double
    let accent: Bool
    let audible: Bool
    let interval: CFTimeInterval
    let isTap: Bool
}

// Thread-safe store of recent and upcoming beats, read by the render loop every frame
final class BeatTimeline {
    private let lock = NSLock()
    private var events: [BeatEvent] = []
    private let capacity = 32

    func append(_ event: BeatEvent) {
        lock.lock()
        events.append(event)
        if events.count > capacity { events.removeFirst(events.count - capacity) }
        lock.unlock()
    }

    func clear() {
        lock.lock()
        events.removeAll(keepingCapacity: true)
        lock.unlock()
    }

    // Most recent events that have already sounded at `time`, newest first
    func recent(at time: CFTimeInterval, limit: Int) -> [BeatEvent] {
        lock.lock()
        defer { lock.unlock() }
        var result: [BeatEvent] = []
        for event in events.reversed() where event.hostTime <= time {
            result.append(event)
            if result.count == limit { break }
        }
        return result
    }
}

struct ClickPattern {
    var bpm: Double
    var subdivision: Double
    var beats: Int
    var grid: [Bool]
    var accents: [Bool]

    var interval: Double { 60.0 / bpm / subdivision }
}

// Sample-accurate click scheduler: buffers are queued on the audio timeline ahead of time,
// so timing never depends on the main thread
final class ClickEngine {
    let timeline = BeatTimeline()
    var onBeat: ((BeatEvent) -> Void)?
    // Called on the main queue when the audio engine cannot start, so the UI can fall back to stopped
    var onStartFailed: (() -> Void)?

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let tapPlayer = AVAudioPlayerNode()
    private let queue = DispatchQueue(label: "metromate.clicks", qos: .userInteractive)
    private let format: AVAudioFormat
    private var accentBuffer: AVAudioPCMBuffer
    private var normalBuffer: AVAudioPCMBuffer

    private let lookahead: Double = 0.12
    private let startLead: Double = 0.04

    // Scheduler state, only touched on `queue`
    private var pattern: ClickPattern
    private var timer: DispatchSourceTimer?
    private var nextBeatSample: Double = 0
    private var nextBeatIndex = 0
    private var audibleSerial = 0
    private var generation = 0
    private var isRunning = false
    private var lastSoundAt: CFTimeInterval = 0
    private var trimCache: [Bool: AVAudioPCMBuffer] = [:]

    init(pattern: ClickPattern, sound: ClickSound) {
        self.pattern = pattern
        format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        let voices = sound.buffers(format: format)
        accentBuffer = voices.accent
        normalBuffer = voices.normal

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }

        engine.attach(player)
        engine.attach(tapPlayer)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.connect(tapPlayer, to: engine.mainMixerNode, format: format)
        engine.prepare()

        NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange, object: engine, queue: nil
        ) { [weak self] _ in
            self?.queue.async { self?.handleConfigurationChange() }
        }
    }

    // MARK: - Transport

    func start(_ pattern: ClickPattern) {
        queue.async { [self] in
            self.pattern = pattern
            trimCache.removeAll()
            startTransport()
        }
    }

    func stop() {
        queue.async { [self] in
            isRunning = false
            generation += 1
            timer?.cancel()
            timer = nil
            player.stop()
            timeline.clear()
            lastSoundAt = CACurrentMediaTime()
            scheduleIdlePause()
        }
    }

    // Tempo and grid edits apply from the next unscheduled beat without breaking the groove
    func update(_ pattern: ClickPattern) {
        queue.async { [self] in
            if Int(pattern.interval * format.sampleRate) != Int(self.pattern.interval * format.sampleRate) {
                trimCache.removeAll()
            }
            self.pattern = pattern
        }
    }

    func setSound(_ sound: ClickSound) {
        let voices = sound.buffers(format: format)
        queue.async { [self] in
            accentBuffer = voices.accent
            normalBuffer = voices.normal
            trimCache.removeAll()
        }
    }

    func setVolume(_ volume: Float) {
        engine.mainMixerNode.outputVolume = volume
    }

    // Lets the user hear a voice in settings without starting the metronome
    func preview() {
        queue.async { [self] in
            guard !isRunning, ensureEngineRunning() else { return }
            tapPlayer.scheduleBuffer(accentBuffer, at: nil, options: .interrupts, completionHandler: nil)
            if !tapPlayer.isPlaying { tapPlayer.play() }
            lastSoundAt = CACurrentMediaTime()
            scheduleIdlePause()
        }
    }

    func tap() {
        let touchTime = CACurrentMediaTime()
        timeline.append(BeatEvent(hostTime: touchTime, index: 0, beats: 0, serial: 0, quarters: 0, quarterLength: 0.5, accent: false, audible: true, interval: 0.5, isTap: true))
        queue.async { [self] in
            guard ensureEngineRunning() else { return }
            tapPlayer.scheduleBuffer(normalBuffer, at: nil, options: .interrupts, completionHandler: nil)
            if !tapPlayer.isPlaying { tapPlayer.play() }
            lastSoundAt = CACurrentMediaTime()
            scheduleIdlePause()
        }
    }

    private func startTransport() {
        guard ensureEngineRunning() else {
            isRunning = false
            generation += 1
            timer?.cancel()
            timer = nil
            DispatchQueue.main.async { [weak self] in self?.onStartFailed?() }
            return
        }
        generation += 1
        isRunning = true
        timer?.cancel()
        player.stop()
        player.play()
        timeline.clear()
        nextBeatSample = startLead * format.sampleRate
        nextBeatIndex = 0
        audibleSerial = 0
        scheduleAhead()

        let source = DispatchSource.makeTimerSource(queue: queue)
        source.schedule(deadline: .now() + .milliseconds(20), repeating: .milliseconds(20), leeway: .milliseconds(5))
        source.setEventHandler { [weak self] in self?.scheduleAhead() }
        source.resume()
        timer = source
    }

    // MARK: - Scheduling

    private func scheduleAhead() {
        guard isRunning else { return }
        let sampleRate = format.sampleRate
        let now = CACurrentMediaTime()
        let current = currentPlayerSample()
        let horizon = Double(current) + lookahead * sampleRate
        let latency = engine.outputNode.presentationLatency

        // If we were starved (app stalled), skip the beats that are already gone instead of bursting
        while nextBeatSample < Double(current) {
            nextBeatSample += pattern.interval * sampleRate
            nextBeatIndex += 1
        }

        while nextBeatSample < horizon {
            let step = nextBeatIndex % max(pattern.beats, 1)
            let audible = step < pattern.grid.count && pattern.grid[step]
            let accent = step < pattern.accents.count && pattern.accents[step]
            let sampleTime = AVAudioFramePosition(nextBeatSample.rounded())
            let when = AVAudioTime(sampleTime: sampleTime, atRate: sampleRate)

            if audible {
                audibleSerial += 1
                player.scheduleBuffer(clickBuffer(accent: accent), at: when, options: [], completionHandler: nil)
            }

            let renderHost: CFTimeInterval
            if let nodeTime = player.nodeTime(forPlayerTime: when), nodeTime.isHostTimeValid {
                renderHost = AVAudioTime.seconds(forHostTime: nodeTime.hostTime)
            } else {
                renderHost = now + (nextBeatSample - Double(current)) / sampleRate
            }
            let event = BeatEvent(
                hostTime: renderHost + latency,
                index: step,
                beats: pattern.beats,
                serial: audibleSerial,
                quarters: Double(nextBeatIndex) / pattern.subdivision,
                quarterLength: 60.0 / pattern.bpm,
                accent: accent,
                audible: audible,
                interval: pattern.interval,
                isTap: false
            )
            timeline.append(event)
            dispatchBeatCallback(event)

            nextBeatSample += pattern.interval * sampleRate
            nextBeatIndex += 1
        }
        lastSoundAt = now
    }

    private func currentPlayerSample() -> AVAudioFramePosition {
        guard let nodeTime = player.lastRenderTime, nodeTime.isSampleTimeValid,
              let playerTime = player.playerTime(forNodeTime: nodeTime) else { return 0 }
        return max(playerTime.sampleTime, 0)
    }

    private func dispatchBeatCallback(_ event: BeatEvent) {
        let token = generation
        let delay = max(0, event.hostTime - CACurrentMediaTime())
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            // Generation is only written on `queue`, a stale read here just drops one highlight
            if token == self.generation { self.onBeat?(event) }
        }
    }

    // Clicks longer than the beat interval would queue up behind each other and drift late
    private func clickBuffer(accent: Bool) -> AVAudioPCMBuffer {
        let source = accent ? accentBuffer : normalBuffer
        let limit = AVAudioFrameCount(max(256, pattern.interval * format.sampleRate * 0.92))
        if source.frameLength <= limit { return source }
        if let cached = trimCache[accent] { return cached }

        guard let trimmed = AVAudioPCMBuffer(pcmFormat: source.format, frameCapacity: limit),
              let src = source.floatChannelData, let dst = trimmed.floatChannelData else { return source }
        trimmed.frameLength = limit
        let fade = min(Int(limit), 256)
        for channel in 0..<Int(source.format.channelCount) {
            for frame in 0..<Int(limit) {
                let tail = Int(limit) - frame
                let gain: Float = tail < fade ? Float(tail) / Float(fade) : 1
                dst[channel][frame] = src[channel][frame] * gain
            }
        }
        trimCache[accent] = trimmed
        return trimmed
    }

    // MARK: - Engine lifecycle

    @discardableResult
    private func ensureEngineRunning() -> Bool {
        if engine.isRunning { return true }
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
            return true
        } catch {
            print("Failed to start audio engine: \(error)")
            return false
        }
    }

    // An idle audio engine still wakes the CPU every few milliseconds, so pause it when silent
    private func scheduleIdlePause() {
        queue.asyncAfter(deadline: .now() + 3) { [self] in
            guard !isRunning, CACurrentMediaTime() - lastSoundAt >= 2.5, engine.isRunning else { return }
            tapPlayer.stop()
            engine.pause()
        }
    }

    private func handleConfigurationChange() {
        // Route changes (headphones, AirPlay) stop the engine and change the output latency
        if isRunning { startTransport() }
    }
}
