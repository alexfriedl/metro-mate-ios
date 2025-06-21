import Foundation
import AVFoundation

class MetronomeManager: ObservableObject {
    @Published var isPlaying = false
    @Published var bpm: Double = 120
    @Published var beatsPerMeasure = 4
    @Published var currentBeat = -1
    @Published var shouldBlink = false
    @Published var gridPattern: [[Bool]] = Array(repeating: Array(repeating: false, count: 16), count: 4)
    @Published var gridSize = 4
    
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
        
        let frequency: Float = currentBeat == 0 ? 800 : 400
        
        guard let channelData = audioBuffer.floatChannelData?[0] else { return nil }
        
        for frame in 0..<Int(frameCount) {
            let value = sin(2.0 * Float.pi * frequency * Float(frame) / Float(sampleRate)) * 0.5
            channelData[frame] = value * Float(1.0 - Double(frame) / Double(frameCount))
        }
        
        return audioBuffer
    }
    
    private func setupDefaultPattern() {
        gridPattern[0][0] = true
        gridPattern[0][1] = true
        gridPattern[0][2] = true
        gridPattern[0][3] = true
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
        
        let interval = 60.0 / bpm
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
        
        let audioFile = currentBeat == 0 ? accentClickFile : normalClickFile
        
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
            let interval = 60.0 / bpm
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