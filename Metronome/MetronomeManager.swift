import Foundation
import AVFoundation
import SwiftUI

struct TapPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    var opacity: Double = 1.0
    var scale: Double = 1.0
}

enum NoteValue: String, CaseIterable, Codable {
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
        case .quarter: return "♩"
        case .eighth: return "♪"
        case .sixteenth: return "♬"
        case .quarterTriplet: return "♩₃"
        case .eighthTriplet: return "♪₃"
        case .sixteenthTriplet: return "♬₃"
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
        switch self {
        case .quarter: return 4
        case .eighth: return 8
        case .sixteenth: return 16
        case .quarterTriplet: return 3
        case .eighthTriplet: return 6
        case .sixteenthTriplet: return 12
        }
    }
}

enum GridDisplayMode: String, CaseIterable, Codable {
    case andCounting = "1&2&"
    case subdivisionCounting = "1e&a"
    
    var displayName: String {
        return self.rawValue
    }
    
    func getLabel(for position: Int, noteValue: NoteValue) -> String {
        switch self {
        case .andCounting:
            return getAndCountingLabel(for: position, noteValue: noteValue)
        case .subdivisionCounting:
            return getSubdivisionLabel(for: position, noteValue: noteValue)
        }
    }
    
    private func getAndCountingLabel(for position: Int, noteValue: NoteValue) -> String {
        if noteValue.isTriplet {
            // Triplet counting: 1 2 3 4 5 6
            return "\(position + 1)"
        } else {
            switch noteValue {
            case .quarter:
                return "\(position + 1)"
            case .eighth:
                let beat = (position / 2) + 1
                let subdivision = position % 2
                return subdivision == 0 ? "\(beat)" : "&"
            case .sixteenth:
                let beat = (position / 4) + 1
                let subdivision = position % 4
                switch subdivision {
                case 0: return "\(beat)"
                case 1: return "e"
                case 2: return "&"
                case 3: return "a"
                default: return "\(position + 1)"
                }
            default:
                return "\(position + 1)"
            }
        }
    }
    
    private func getSubdivisionLabel(for position: Int, noteValue: NoteValue) -> String {
        if noteValue.isTriplet {
            // Triplet counting: 1 trip let 2 trip let
            let tripletGroup = (position / 3) + 1
            let tripletPosition = position % 3
            switch tripletPosition {
            case 0: return "\(tripletGroup)"
            case 1: return "trip"
            case 2: return "let"
            default: return "\(position + 1)"
            }
        } else {
            switch noteValue {
            case .quarter:
                return "\(position + 1)"
            case .eighth:
                let beat = (position / 2) + 1
                let subdivision = position % 2
                return subdivision == 0 ? "\(beat)" : "&"
            case .sixteenth:
                let beat = (position / 4) + 1
                let subdivision = position % 4
                switch subdivision {
                case 0: return "\(beat)"
                case 1: return "e"
                case 2: return "&"
                case 3: return "a"
                default: return "\(position + 1)"
                }
            default:
                return "\(position + 1)"
            }
        }
    }
    
}

struct BeatPreset: Identifiable, Codable {
    var id = UUID()
    let name: String
    let noteValue: NoteValue
    let bpm: Double
    let beatsPerMeasure: Int
    let gridPattern: [Bool]
    let accentPattern: [Bool]
    let gridDisplayMode: GridDisplayMode
}

class MetronomeManager: ObservableObject {
    @Published var isPlaying = false
    @Published var bpm: Double = 80
    @Published var beatsPerMeasure = 4
    @Published var currentBeat = -1
    @Published var shouldBlink = false
    @Published var gridPattern: [[Bool]] = Array(repeating: Array(repeating: false, count: 16), count: 4)
    @Published var accentPattern: [Bool] = Array(repeating: false, count: 16)
    @Published var gridSize = 4
    @Published var noteValue: NoteValue = .quarter
    @Published var gridDisplayMode: GridDisplayMode = .andCounting
    @Published var currentBeatName: String = "Default Beat"
    @Published var savedBeats: [BeatPreset] = []
    @Published var tapPoints: [TapPoint] = []
    
    private var tapTimes: [Date] = []
    private let maxTapCount = 8
    private var tapPointTimer: Timer?
    
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var timer: DispatchSourceTimer?
    private var accentClickFile: AVAudioFile?
    private var normalClickFile: AVAudioFile?
    
    init() {
        setupAudio()
        setupDefaultPattern()
    }
    
    deinit {
        tapPointTimer?.invalidate()
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
    
    private func createClickBuffer(accent: Bool = false) -> AVAudioPCMBuffer? {
        let sampleRate = 44100.0
        let duration = 0.1
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        guard let audioFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return nil }
        guard let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else { return nil }
        
        audioBuffer.frameLength = frameCount
        
        let frequency: Float = accent ? 800 : 400
        
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
        
        // Clear accent pattern
        for i in 0..<accentPattern.count {
            accentPattern[i] = false
        }
        
        // Set all beats active for current beatsPerMeasure
        for i in 0..<beatsPerMeasure {
            gridPattern[0][i] = true
        }
        
        // Set accents on beats 1,2,3,4 for all default patterns
        switch noteValue {
        case .quarter:
            // Quarter: accent on beats 0,1,2,3 (positions 1,2,3,4)
            for i in 0..<min(4, beatsPerMeasure) {
                accentPattern[i] = true
            }
        case .eighth:
            // Eighth: accent on beats 0,2,4,6 (positions 1,2,3,4)
            let accentPositions = [0, 2, 4, 6] // beats 1,2,3,4
            for position in accentPositions {
                if position < beatsPerMeasure {
                    accentPattern[position] = true
                }
            }
        case .sixteenth:
            // Sixteenth: accent on beats 0,4,8,12 (positions 1,2,3,4)
            let accentPositions = [0, 4, 8, 12] // beats 1,2,3,4
            for position in accentPositions {
                if position < beatsPerMeasure {
                    accentPattern[position] = true
                }
            }
        case .quarterTriplet:
            // Quarter triplet: accent on beats 0,1,2 (positions 1,2,3)
            for i in 0..<min(3, beatsPerMeasure) {
                accentPattern[i] = true
            }
        case .eighthTriplet:
            // Eighth triplet: accent on beats 0,3 (positions 1,2)
            for i in stride(from: 0, to: min(6, beatsPerMeasure), by: 3) {
                accentPattern[i] = true
            }
        case .sixteenthTriplet:
            // Sixteenth triplet: accent on beats 0,3,6,9 (positions 1,2,3,4)
            for i in stride(from: 0, to: min(12, beatsPerMeasure), by: 3) {
                accentPattern[i] = true
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
        
        // Ensure audio engine is running and player is ready
        if let audioEngine = audioEngine, !audioEngine.isRunning {
            do {
                try audioEngine.start()
            } catch {
                print("Failed to restart audio engine: \(error)")
            }
        }
        
        // Ensure player node is ready
        if let playerNode = playerNode, !playerNode.isPlaying {
            playerNode.play()
        }
        
        // Small delay to ensure audio system is ready, then play first beat
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
            self?.tick()
            
            // Use DispatchSourceTimer for subsequent beats
            guard let self = self else { return }
            let interval = (60.0 / self.bpm) / self.noteValue.multiplier
            let queue = DispatchQueue(label: "metronome.timer", qos: .userInteractive)
            
            self.timer = DispatchSource.makeTimerSource(queue: queue)
            // Start after one interval, then repeat
            self.timer?.schedule(deadline: .now() + interval, repeating: interval)
            self.timer?.setEventHandler { [weak self] in
                DispatchQueue.main.async {
                    self?.tick()
                }
            }
            self.timer?.resume()
        }
    }
    
    private func stop() {
        isPlaying = false
        timer?.cancel()
        timer = nil
        currentBeat = -1
        shouldBlink = false
        
        // Stop the player node
        playerNode?.stop()
    }
    
    private func tick() {
        // Update beat counter BEFORE playing sound and visual update
        currentBeat = (currentBeat + 1) % beatsPerMeasure
        
        // Update visual immediately
        triggerVisualBlink()
        
        // Check if this beat should play based on grid pattern
        let shouldPlayBeat = currentBeat < gridPattern[0].count && gridPattern[0][currentBeat]
        
        if shouldPlayBeat {
            playClick()
        }
    }
    
    private func playClick() {
        guard let playerNode = playerNode else { return }
        
        let shouldAccent = currentBeat < accentPattern.count && accentPattern[currentBeat]
        let audioFile = shouldAccent ? accentClickFile : normalClickFile
        
        if let audioFile = audioFile {
            playerNode.scheduleFile(audioFile, at: nil)
        } else {
            guard let audioBuffer = createClickBuffer(accent: shouldAccent) else { return }
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
        let oldBPM = bpm
        bpm = newBPM
        
        if isPlaying {
            // Cancel old timer
            timer?.cancel()
            
            // Calculate new interval
            let newInterval = (60.0 / bpm) / noteValue.multiplier
            let queue = DispatchQueue(label: "metronome.timer", qos: .userInteractive)
            
            // Restart immediately with new interval to maintain beat continuity
            timer = DispatchSource.makeTimerSource(queue: queue)
            timer?.schedule(deadline: .now() + newInterval, repeating: newInterval)
            timer?.setEventHandler { [weak self] in
                DispatchQueue.main.async {
                    self?.tick()
                }
            }
            timer?.resume()
        }
    }
    
    func updateNoteValue(_ newNoteValue: NoteValue) {
        noteValue = newNoteValue
        beatsPerMeasure = newNoteValue.beatsPerMeasure
        
        // Set appropriate display mode based on note value
        switch newNoteValue {
        case .quarter, .quarterTriplet:
            gridDisplayMode = .andCounting
        case .eighth, .eighthTriplet:
            gridDisplayMode = .andCounting
        case .sixteenth, .sixteenthTriplet:
            gridDisplayMode = .subdivisionCounting
        }
        
        // Set beat name based on note value (only if not custom/random)
        if currentBeatName != "Custom Beat" && currentBeatName != "Random Beat" {
            switch newNoteValue {
            case .quarter:
                currentBeatName = "Default Beat"
            case .eighth:
                currentBeatName = "Eighth Beat"
            case .sixteenth:
                currentBeatName = "Sixteenth Beat"
            case .quarterTriplet, .eighthTriplet, .sixteenthTriplet:
                currentBeatName = "Triplet Beat"
            }
        }
        
        currentBeat = -1
        
        // Reset grid pattern for new beat count
        let maxBeats = max(16, beatsPerMeasure)
        for i in 0..<gridPattern.count {
            while gridPattern[i].count < maxBeats {
                gridPattern[i].append(false)
            }
        }
        
        // Reset accent pattern for new beat count
        while accentPattern.count < maxBeats {
            accentPattern.append(false)
        }
        
        setupDefaultPattern()
        
        if isPlaying {
            timer?.cancel()
            let interval = (60.0 / bpm) / noteValue.multiplier
            let queue = DispatchQueue(label: "metronome.timer", qos: .userInteractive)
            
            timer = DispatchSource.makeTimerSource(queue: queue)
            timer?.schedule(deadline: .now() + interval, repeating: interval)
            timer?.setEventHandler { [weak self] in
                DispatchQueue.main.async {
                    self?.tick()
                }
            }
            timer?.resume()
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
        // Set to custom beat when user modifies pattern
        if currentBeatName != "Random Beat" {
            currentBeatName = "Custom Beat"
        }
    }
    
    func toggleAccentCell(col: Int) {
        accentPattern[col].toggle()
        // Set to custom beat when user modifies accent pattern
        if currentBeatName != "Random Beat" {
            currentBeatName = "Custom Beat"
        }
    }
    
    func updateGridSize(_ size: Int) {
        gridSize = size
        gridPattern = Array(repeating: Array(repeating: false, count: max(16, beatsPerMeasure)), count: size)
        setupDefaultPattern()
    }
    
    func tapTempo() {
        let now = Date()
        tapTimes.append(now)
        
        // Add visual tap point
        let newTapPoint = TapPoint(timestamp: now)
        tapPoints.append(newTapPoint)
        
        // Start or reset the animation timer
        startTapPointAnimation()
        
        // Remove taps older than 3 seconds
        tapTimes = tapTimes.filter { now.timeIntervalSince($0) < 3.0 }
        
        // Keep only the most recent taps
        if tapTimes.count > maxTapCount {
            tapTimes.removeFirst(tapTimes.count - maxTapCount)
        }
        
        // Calculate BPM if we have at least 2 taps
        if tapTimes.count >= 2 {
            let intervals = zip(tapTimes.dropFirst(), tapTimes).map { $0.timeIntervalSince($1) }
            let averageInterval = intervals.reduce(0, +) / Double(intervals.count)
            let newBPM = 60.0 / averageInterval
            
            // Clamp BPM to reasonable range
            bpm = min(max(newBPM, 40), 200)
            
            if isPlaying {
                updateBPM(bpm)
            }
        }
    }
    
    private func startTapPointAnimation() {
        // Clear old timer
        tapPointTimer?.invalidate()
        
        // Start new animation timer
        tapPointTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let now = Date()
            var hasActiveTaps = false
            
            // Update opacity and scale for each tap point
            for i in self.tapPoints.indices {
                let age = now.timeIntervalSince(self.tapPoints[i].timestamp)
                
                if age < 2.0 { // Fade out over 2 seconds
                    hasActiveTaps = true
                    self.tapPoints[i].opacity = max(0, 1.0 - (age / 2.0))
                    self.tapPoints[i].scale = 1.0 + (age * 0.5) // Grow from 1.0 to 2.0
                }
            }
            
            // Remove old tap points
            self.tapPoints.removeAll { now.timeIntervalSince($0.timestamp) >= 2.0 }
            
            // Stop timer if no active taps
            if !hasActiveTaps {
                self.tapPointTimer?.invalidate()
                self.tapPointTimer = nil
            }
        }
    }
    
    func updateGridBeats(_ beats: Int) {
        let maxBeats = max(16, beats)
        
        // Update beatsPerMeasure based on note value
        if noteValue.isTriplet {
            beatsPerMeasure = min(beats, 12) // Max 12 for triplets
        } else {
            beatsPerMeasure = min(beats, 16) // Max 16 for regular notes
        }
        
        currentBeat = -1
        
        // Ensure grid pattern accommodates new beat count
        for i in 0..<gridPattern.count {
            while gridPattern[i].count < maxBeats {
                gridPattern[i].append(false)
            }
        }
        
        // Reset accent pattern for new beat count
        while accentPattern.count < maxBeats {
            accentPattern.append(false)
        }
        
        setupDefaultPattern()
    }
    
    func saveBeatPreset(name: String) {
        let preset = BeatPreset(
            name: name,
            noteValue: noteValue,
            bpm: bpm,
            beatsPerMeasure: beatsPerMeasure,
            gridPattern: gridPattern[0],
            accentPattern: accentPattern,
            gridDisplayMode: gridDisplayMode
        )
        
        // Remove existing preset with same name
        savedBeats.removeAll { $0.name == name }
        savedBeats.append(preset)
        currentBeatName = name
    }
    
    func loadBeatPreset(_ preset: BeatPreset) {
        noteValue = preset.noteValue
        bpm = preset.bpm
        beatsPerMeasure = preset.beatsPerMeasure
        gridDisplayMode = preset.gridDisplayMode
        currentBeatName = preset.name
        
        // Update grid patterns
        for i in 0..<gridPattern.count {
            for j in 0..<gridPattern[i].count {
                if j < preset.gridPattern.count {
                    gridPattern[i][j] = preset.gridPattern[j]
                } else {
                    gridPattern[i][j] = false
                }
            }
        }
        
        // Update accent pattern
        for i in 0..<accentPattern.count {
            if i < preset.accentPattern.count {
                accentPattern[i] = preset.accentPattern[i]
            } else {
                accentPattern[i] = false
            }
        }
        
        if isPlaying {
            timer?.cancel()
            let interval = (60.0 / bpm) / noteValue.multiplier
            let queue = DispatchQueue(label: "metronome.timer", qos: .userInteractive)
            
            timer = DispatchSource.makeTimerSource(queue: queue)
            timer?.schedule(deadline: .now() + interval, repeating: interval)
            timer?.setEventHandler { [weak self] in
                DispatchQueue.main.async {
                    self?.tick()
                }
            }
            timer?.resume()
        }
    }
    
    func deleteBeatPreset(_ preset: BeatPreset) {
        savedBeats.removeAll { $0.id == preset.id }
        if currentBeatName == preset.name {
            currentBeatName = "Default Beat"
        }
    }
    
    func randomizeBeat() {
        // Randomize note value
        let allNoteValues = NoteValue.allCases
        let randomNoteValue = allNoteValues.randomElement()!
        
        // Randomize display mode
        let randomDisplayMode = GridDisplayMode.allCases.randomElement()!
        
        // Apply randomized settings (keep BPM unchanged)
        noteValue = randomNoteValue
        beatsPerMeasure = randomNoteValue.beatsPerMeasure
        gridDisplayMode = randomDisplayMode
        
        // Clear current pattern
        for i in 0..<gridPattern.count {
            for j in 0..<gridPattern[i].count {
                gridPattern[i][j] = false
            }
        }
        
        // Clear accent pattern
        for i in 0..<accentPattern.count {
            accentPattern[i] = false
        }
        
        // Generate random beat pattern
        let maxActiveBeats = min(beatsPerMeasure, 12) // Cap at 12 for complex patterns
        let minActiveBeats = max(2, beatsPerMeasure / 4) // At least 25% of beats
        let activeBeats = Int.random(in: minActiveBeats...maxActiveBeats)
        var selectedBeats: Set<Int> = []
        
        // Always include first beat
        selectedBeats.insert(0)
        gridPattern[0][0] = true
        accentPattern[0] = true // First beat always has accent
        
        // Add random beats
        while selectedBeats.count < activeBeats {
            let randomBeat = Int.random(in: 1..<beatsPerMeasure)
            if selectedBeats.insert(randomBeat).inserted {
                gridPattern[0][randomBeat] = true
                
                // Random chance for accent (25% for non-first beats)
                if Int.random(in: 1...4) == 1 {
                    accentPattern[randomBeat] = true
                }
            }
        }
        
        // Update timer if playing
        if isPlaying {
            timer?.cancel()
            let interval = (60.0 / bpm) / noteValue.multiplier
            let queue = DispatchQueue(label: "metronome.timer", qos: .userInteractive)
            
            timer = DispatchSource.makeTimerSource(queue: queue)
            timer?.schedule(deadline: .now() + interval, repeating: interval)
            timer?.setEventHandler { [weak self] in
                DispatchQueue.main.async {
                    self?.tick()
                }
            }
            timer?.resume()
        }
        
        currentBeatName = "Random Beat"
    }
    
    func resetToBasicBeat() {
        noteValue = .quarter
        bpm = 80
        beatsPerMeasure = 4
        gridDisplayMode = .andCounting
        
        // Reset current beat properly
        if isPlaying {
            currentBeat = -1 // Will become 0 on next tick
        } else {
            currentBeat = -1 // Stopped state
        }
        
        // Clear all patterns
        for i in 0..<gridPattern.count {
            for j in 0..<gridPattern[i].count {
                gridPattern[i][j] = false
            }
        }
        
        for i in 0..<accentPattern.count {
            accentPattern[i] = false
        }
        
        // Set up basic 4/4 pattern
        setupDefaultPattern()
        
        // Update timer if playing
        if isPlaying {
            timer?.cancel()
            let interval = (60.0 / bpm) / noteValue.multiplier
            let queue = DispatchQueue(label: "metronome.timer", qos: .userInteractive)
            
            timer = DispatchSource.makeTimerSource(queue: queue)
            timer?.schedule(deadline: .now() + interval, repeating: interval)
            timer?.setEventHandler { [weak self] in
                DispatchQueue.main.async {
                    self?.tick()
                }
            }
            timer?.resume()
        }
        
        currentBeatName = "Default Beat"
    }
}