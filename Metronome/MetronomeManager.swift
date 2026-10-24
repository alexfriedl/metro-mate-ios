import Foundation
import AVFoundation
import SwiftUI
import Combine

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

    // Loaded means the same pattern by value, the name may differ and the tempo may have moved since
    func matches(noteValue: NoteValue, beatsPerMeasure: Int, grid: [Bool], accents: [Bool]) -> Bool {
        guard noteValue == self.noteValue, beatsPerMeasure == self.beatsPerMeasure else { return false }
        func steps(_ cells: [Bool]) -> [Bool] {
            (0..<beatsPerMeasure).map { $0 < cells.count && cells[$0] }
        }
        return steps(grid) == steps(gridPattern) && steps(accents) == steps(accentPattern)
    }
}

class MetronomeManager: ObservableObject {
    static let shared = MetronomeManager()
    @Published var isPlaying = false {
        didSet { ScreenAwake.set("metronome", playing: isPlaying) }
    }
    @Published var bpm: Double = 60 {
        didSet {
            syncPattern()
            if isPlaying { PracticeLog.shared.updateTempo(Int(bpm)) }
        }
    }
    @Published var beatsPerMeasure = 8 { didSet { syncPattern() } }
    @Published var currentBeat = -1
    @Published var gridPattern: [[Bool]] = Array(repeating: Array(repeating: false, count: 16), count: 4) { didSet { syncPattern() } }
    @Published var accentPattern: [Bool] = Array(repeating: false, count: 16) { didSet { syncPattern() } }
    @Published var gridSize = 4
    @Published var noteValue: NoteValue = .eighth { didSet { syncPattern() } }
    // App volume on top of the system volume, shared by metronome and learn player
    @Published var volume: Double = UserDefaults.standard.object(forKey: "volume") as? Double ?? 1 {
        didSet {
            UserDefaults.standard.set(volume, forKey: "volume")
            clicks?.setVolume(Float(volume))
        }
    }
    @Published var clickSound: ClickSound = ClickSound(rawValue: UserDefaults.standard.string(forKey: "clickSound") ?? "") ?? .classic {
        didSet {
            UserDefaults.standard.set(clickSound.rawValue, forKey: "clickSound")
            clicks?.setSound(clickSound)
        }
    }
    @Published var gridDisplayMode: GridDisplayMode = .andCounting
    @Published var currentBeatName: String = "Eighth"
    @Published var savedBeats: [BeatPreset] = []
    @Published var tapPoints: [TapPoint] = []
    @Published var tapTimes: [Date] = []
    @Published var tapCount: Int = 0
    private let maxTapCount = 8
    private var tapClearTimer: Timer?
    private var tapPointTimer: Timer?
    
    private var clicks: ClickEngine?
    private var isConfigured = false
    private var interruptionObserver: NSObjectProtocol?

    // Beats stamped with the time they are heard, the visuals render from this instead of @Published ticks
    var beatTimeline: BeatTimeline { clicks!.timeline }

    private let savedBeatsKey = "savedBeatPresets"
    private let stateKey = "metronomeState"
    private var persistence: AnyCancellable?

    // Everything the user can set survives quitting the app
    private struct SavedState: Codable {
        var bpm: Double
        var noteValue: NoteValue
        var beatsPerMeasure: Int
        var gridPattern: [[Bool]]
        var accentPattern: [Bool]
        var gridDisplayMode: GridDisplayMode
        var currentBeatName: String
    }

    init() {
        setupDefaultPattern()
        restorePresets()
        restoreState()
        clicks = ClickEngine(pattern: clickPattern, sound: clickSound)
        clicks?.setVolume(Float(volume))
        clicks?.onBeat = { [weak self] event in
            self?.currentBeat = event.index
        }
        // A failed start or a phone call leaves the metronome stopped and closes the practice session
        clicks?.onStartFailed = { [weak self] in self?.stopIfPlaying() }
        interruptionObserver = observeAudioInterruptions { [weak self] in self?.stopIfPlaying() }
        isConfigured = true

        // Save shortly after the last change, ticks while playing just keep pushing it back
        persistence = objectWillChange
            .debounce(for: .milliseconds(600), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.persistState() }
    }

    private func persistState() {
        let state = SavedState(
            bpm: bpm,
            noteValue: noteValue,
            beatsPerMeasure: beatsPerMeasure,
            gridPattern: gridPattern,
            accentPattern: accentPattern,
            gridDisplayMode: gridDisplayMode,
            currentBeatName: currentBeatName
        )
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: stateKey)
        }
    }

    private func restoreState() {
        guard let data = UserDefaults.standard.data(forKey: stateKey),
              let state = try? JSONDecoder().decode(SavedState.self, from: data) else { return }
        bpm = state.bpm
        noteValue = state.noteValue
        beatsPerMeasure = state.beatsPerMeasure
        gridPattern = state.gridPattern
        accentPattern = state.accentPattern
        gridDisplayMode = state.gridDisplayMode
        currentBeatName = state.currentBeatName
    }

    private var clickPattern: ClickPattern {
        ClickPattern(
            bpm: bpm,
            subdivision: noteValue.multiplier,
            beats: beatsPerMeasure,
            grid: gridPattern.first ?? [],
            accents: accentPattern
        )
    }

    private var syncPending = false

    // Pattern edits arrive cell by cell, so coalesce them into one engine update per run loop
    private func syncPattern() {
        guard isConfigured, !syncPending else { return }
        syncPending = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.syncPending = false
            self.clicks?.update(self.clickPattern)
        }
    }

    func stopIfPlaying() {
        if isPlaying { stop() }
    }

    func previewSound() {
        clicks?.preview()
    }

    // Structural changes (note value, preset, reset) start the bar again from beat 1
    private func restartIfPlaying() {
        guard isPlaying else { return }
        currentBeat = -1
        clicks?.start(clickPattern)
    }
    
    deinit {
        tapPointTimer?.invalidate()
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
        currentBeat = -1
        clicks?.start(clickPattern)
        PracticeLog.shared.begin(.metronome, title: currentBeatName, detail: "Metronome · \(noteValue.rawValue)", bpm: Int(bpm))
    }
    
    private func stop() {
        isPlaying = false
        currentBeat = -1
        clicks?.stop()
        PracticeLog.shared.end()
    }
    
    func updateBPM(_ newBPM: Double) {
        // Tempo changes glide in on the next beat, no restart, so the groove keeps its phase
        bpm = newBPM
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
                currentBeatName = "Quarter"
            case .eighth:
                currentBeatName = "Eighth"
            case .sixteenth:
                currentBeatName = "Sixteenth"
            case .quarterTriplet:
                currentBeatName = "Quarter Triplet"
            case .eighthTriplet:
                currentBeatName = "Eighth Triplet"
            case .sixteenthTriplet:
                currentBeatName = "Sixteenth Triplet"
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
        
        restartIfPlaying()
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
        
        // Increment tap count (never resets, just keeps counting)
        tapCount += 1
        
        // Add to tap times for BPM calculation
        tapTimes.append(now)
        
        // Play tap sound and pulse the background (even when not playing)
        clicks?.tap()
        
        // Only keep recent taps for BPM calculation (but don't affect count)
        tapTimes = tapTimes.filter { now.timeIntervalSince($0) < 3.0 }
        
        // Keep only the most recent taps for calculation
        if tapTimes.count > maxTapCount {
            tapTimes.removeFirst(tapTimes.count - maxTapCount)
        }
        
        // Calculate BPM if we have at least 2 taps
        if tapTimes.count >= 2 {
            let intervals = zip(tapTimes.dropFirst(), tapTimes).map { $0.timeIntervalSince($1) }
            let averageInterval = intervals.reduce(0, +) / Double(intervals.count)
            let newBPM = 60.0 / averageInterval
            
            // Clamp BPM to reasonable range
            bpm = min(max(newBPM, 1), 300)
        }
        
        // Clear tap count after 3 seconds of no tapping
        tapClearTimer?.invalidate()
        tapClearTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.tapCount = 0
            // Don't clear BPM - it stays
        }
    }
    
    private func startTapPointAnimation() {
        // Clear old timer
        tapPointTimer?.invalidate()
        
        // Start new animation timer
        tapPointTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let now = Date()
            var hasActiveTaps = false
            
            // Update opacity and scale for each tap point
            for i in self.tapPoints.indices {
                let age = now.timeIntervalSince(self.tapPoints[i].timestamp)
                
                if age < 1.0 { // Fade out over 1 second (faster)
                    hasActiveTaps = true
                    self.tapPoints[i].opacity = max(0, 1.0 - age)
                    self.tapPoints[i].scale = 1.0 + (age * 1.0) // Grow faster
                }
            }
            
            // Remove old tap points
            self.tapPoints.removeAll { now.timeIntervalSince($0.timestamp) >= 1.0 }
            
            // Stop timer if no active taps
            if !hasActiveTaps {
                self.tapPointTimer?.invalidate()
                self.tapPointTimer = nil
            }
        }
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
        persistPresets()
    }

    // MARK: - Preset persistence

    /// Presets are stored in UserDefaults so they survive quitting the app.
    /// Nothing leaves the device - see PRIVACY.md.
    private func persistPresets() {
        do {
            let data = try JSONEncoder().encode(savedBeats)
            UserDefaults.standard.set(data, forKey: savedBeatsKey)
        } catch {
            print("Failed to save beat presets: \(error)")
        }
    }

    private func restorePresets() {
        guard let data = UserDefaults.standard.data(forKey: savedBeatsKey) else { return }

        do {
            savedBeats = try JSONDecoder().decode([BeatPreset].self, from: data)
        } catch {
            // Most likely a preset written by an older version whose shape has
            // since changed. Drop them rather than trapping the user in a
            // crash loop on every launch.
            print("Failed to load beat presets: \(error)")
            UserDefaults.standard.removeObject(forKey: savedBeatsKey)
        }
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
        
        restartIfPlaying()
    }
    
    func isLoaded(_ preset: BeatPreset) -> Bool {
        preset.matches(noteValue: noteValue, beatsPerMeasure: beatsPerMeasure, grid: gridPattern.first ?? [], accents: accentPattern)
    }

    func deleteBeatPreset(_ preset: BeatPreset) {
        savedBeats.removeAll { $0.id == preset.id }
        if currentBeatName == preset.name {
            currentBeatName = "Eighth"
        }
        persistPresets()
    }
    
    // Everything the shuffle key changes, kept so one roll can be taken back, the tempo is never touched
    private struct PatternSnapshot {
        let noteValue: NoteValue
        let beatsPerMeasure: Int
        let gridPattern: [[Bool]]
        let accentPattern: [Bool]
        let gridDisplayMode: GridDisplayMode
        let name: String
    }

    private var beforeRandom: PatternSnapshot?

    func undoRandomize() {
        guard let previous = beforeRandom else { return }
        beforeRandom = nil
        noteValue = previous.noteValue
        beatsPerMeasure = previous.beatsPerMeasure
        gridPattern = previous.gridPattern
        accentPattern = previous.accentPattern
        gridDisplayMode = previous.gridDisplayMode
        currentBeatName = previous.name
        restartIfPlaying()
    }

    func randomizeBeat() {
        beforeRandom = PatternSnapshot(
            noteValue: noteValue,
            beatsPerMeasure: beatsPerMeasure,
            gridPattern: gridPattern,
            accentPattern: accentPattern,
            gridDisplayMode: gridDisplayMode,
            name: currentBeatName
        )

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
        
        // Restart the bar if playing
        restartIfPlaying()
        
        currentBeatName = "Random Beat"
    }
    
    func resetToBasicBeat() {
        noteValue = .eighth
        bpm = 80
        beatsPerMeasure = 8
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
        
        // Restart the bar if playing
        restartIfPlaying()
        
        currentBeatName = "Eighth"
    }
}