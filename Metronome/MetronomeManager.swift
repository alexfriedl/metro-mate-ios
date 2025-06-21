import Foundation
import AVFoundation

enum NoteValue: String, CaseIterable {
    case quarter = "1/4"
    case eighth = "1/8"
    case sixteenth = "1/16"
    case quarterTriplet = "1/4T"
    case eighthTriplet = "1/8T"
    case sixteenthTriplet = "1/16T"
    
    var multiplier: Double {
        switch self {
        case .quarter: return 1.0
        case .eighth: return 2.0
        case .sixteenth: return 4.0
        case .quarterTriplet: return 3.0/2.0
        case .eighthTriplet: return 3.0
        case .sixteenthTriplet: return 6.0
        }
    }
    
    var displayName: String {
        switch self {
        case .quarter: return "Viertel"
        case .eighth: return "Achtel"
        case .sixteenth: return "Sechzehntel"
        case .quarterTriplet: return "Viertel-Triolen"
        case .eighthTriplet: return "Achtel-Triolen"
        case .sixteenthTriplet: return "Sechzehntel-Triolen"
        }
    }
    
    var isTriplet: Bool {
        switch self {
        case .quarterTriplet, .eighthTriplet, .sixteenthTriplet:
            return true
        default:
            return false
        }
    }
    
    var beatsPerMeasure: Int {
        return isTriplet ? 6 : 4
    }
}

class MetronomeManager: ObservableObject {
    @Published var isPlaying = false
    @Published var bpm: Double = 120
    @Published var beatsPerMeasure = 4
    @Published var currentBeat = -1
    @Published var shouldBlink = false
    @Published var gridPattern: [[Bool]] = Array(repeating: Array(repeating: false, count: 16), count: 4)
    @Published var gridSize = 4
    @Published var noteValue: NoteValue = .quarter
    
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var timer: Timer?
    private var accentClickFile: AVAudioFile?
    private var normalClickFile: AVAudioFile?
    
    init() {
        setupAudio()
        setupDefaultPattern()
    }
    
    private func setupAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
        
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        
        guard let audioEngine = audioEngine, let playerNode = playerNode else { return }
        
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: nil)
        
        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
        
        loadSoundFiles()
    }
    
    private func loadSoundFiles() {
        if let accentURL = Bundle.main.url(forResource: "accent_click", withExtension: "wav") {
            do {
                accentClickFile = try AVAudioFile(forReading: accentURL)
            } catch {
                print("Failed to load accent click file: \(error)")
            }
        }
        
        if let normalURL = Bundle.main.url(forResource: "normal_click", withExtension: "wav") {
            do {
                normalClickFile = try AVAudioFile(forReading: normalURL)
            } catch {
                print("Failed to load normal click file: \(error)")
            }
        }
    }
    
    private func createClickBuffer() -> AVAudioPCMBuffer? {
        let sampleRate = 44100.0
        let duration = 0.1
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        guard let audioFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return nil }
        guard let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else { return nil }
        
        audioBuffer.frameLength = frameCount
        
        let shouldAccent: Bool
        if noteValue.isTriplet {
            shouldAccent = (currentBeat == 0 || currentBeat == 3)
        } else {
            shouldAccent = (currentBeat == 0)
        }
        let frequency: Float = shouldAccent ? 800 : 400
        
        guard let channelData = audioBuffer.floatChannelData?[0] else { return nil }
        
        for frame in 0..<Int(frameCount) {
            let value = sin(2.0 * Float.pi * frequency * Float(frame) / Float(sampleRate)) * 0.5
            channelData[frame] = value * Float(1.0 - Double(frame) / Double(frameCount))
        }
        
        return audioBuffer
    }
    
    private func setupDefaultPattern() {
        // Clear all patterns first
        for i in 0..<gridPattern.count {
            for j in 0..<gridPattern[i].count {
                gridPattern[i][j] = false
            }
        }
        
        if noteValue.isTriplet {
            // Triplet pattern: 6 beats (2 groups of 3)
            for i in 0..<6 {
                gridPattern[0][i] = true
            }
        } else {
            // Regular pattern: 4 beats
            for i in 0..<4 {
                gridPattern[0][i] = true
            }
        }
    }
    
    func togglePlayback() {
        if isPlaying {
            stop()
        } else {
            start()
        }
    }
    
    private func start() {
        isPlaying = true
        currentBeat = -1  // Start at -1 so first increment makes it 0 (beat 1)
        
        // Immediate first tick for beat 1
        tick()
        
        let interval = (60.0 / bpm) / noteValue.multiplier
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            self.tick()
        }
    }
    
    private func stop() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
        currentBeat = -1
        shouldBlink = false
    }
    
    private func tick() {
        // Update beat counter BEFORE playing sound and visual update
        currentBeat = (currentBeat + 1) % beatsPerMeasure
        
        // Update visual immediately
        DispatchQueue.main.async {
            self.triggerVisualBlink()
        }
        
        // Check if this beat should play based on grid pattern
        let shouldPlayBeat = currentBeat < gridPattern[0].count && gridPattern[0][currentBeat]
        
        if shouldPlayBeat {
            playClick()
        }
    }
    
    private func playClick() {
        guard let playerNode = playerNode else { return }
        
        let shouldAccent: Bool
        if noteValue.isTriplet {
            // Triplet accent pattern: beats 0, 3 are accented (1st beat of each triplet group)
            shouldAccent = (currentBeat == 0 || currentBeat == 3)
        } else {
            // Regular pattern: only first beat is accented
            shouldAccent = (currentBeat == 0)
        }
        
        let audioFile = shouldAccent ? accentClickFile : normalClickFile
        
        if let audioFile = audioFile {
            playerNode.scheduleFile(audioFile, at: nil)
        } else {
            guard let audioBuffer = createClickBuffer() else { return }
            playerNode.scheduleBuffer(audioBuffer, at: nil, options: [], completionHandler: nil)
        }
        
        if !playerNode.isPlaying {
            playerNode.play()
        }
    }
    
    private func triggerVisualBlink() {
        shouldBlink = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.shouldBlink = false
        }
    }
    
    func updateBPM(_ newBPM: Double) {
        bpm = newBPM
        if isPlaying {
            timer?.invalidate()
            let interval = (60.0 / bpm) / noteValue.multiplier
            timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                self.tick()
            }
        }
    }
    
    func updateNoteValue(_ newNoteValue: NoteValue) {
        noteValue = newNoteValue
        beatsPerMeasure = newNoteValue.beatsPerMeasure
        currentBeat = -1
        
        // Reset grid pattern for new beat count
        if gridPattern.count > 0 && gridPattern[0].count < beatsPerMeasure {
            for i in 0..<gridPattern.count {
                while gridPattern[i].count < beatsPerMeasure {
                    gridPattern[i].append(false)
                }
            }
        }
        setupDefaultPattern()
        
        if isPlaying {
            timer?.invalidate()
            let interval = (60.0 / bpm) / noteValue.multiplier
            timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                self.tick()
            }
        }
    }
    
    func updateBeatsPerMeasure(_ beats: Int) {
        beatsPerMeasure = beats
        currentBeat = -1
        
        // Ensure grid pattern accommodates new beat count
        if gridPattern.count > 0 && gridPattern[0].count < beats {
            for i in 0..<gridPattern.count {
                while gridPattern[i].count < beats {
                    gridPattern[i].append(false)
                }
            }
        }
        setupDefaultPattern()
    }
    
    func toggleGridCell(row: Int, col: Int) {
        gridPattern[row][col].toggle()
    }
    
    func updateGridSize(_ size: Int) {
        gridSize = size
        gridPattern = Array(repeating: Array(repeating: false, count: max(16, beatsPerMeasure)), count: size)
        setupDefaultPattern()
    }
}