import SwiftUI

struct Dot {
    var baseX: CGFloat
    var baseY: CGFloat
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var distanceFromCenter: CGFloat
}

struct StarFieldView: View {
    @ObservedObject var metronome: MetronomeManager
    @State private var dots: [[Dot]] = []
    @State private var wavePhase: CGFloat = 0
    @State private var pulseTime: CGFloat = 1.0
    
    let dotSpacing: CGFloat = 10 // Tighter spacing between dots
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // Draw all dots
                for row in dots {
                    for dot in row {
                        let rect = CGRect(
                            x: dot.x - dot.size/2,
                            y: dot.y - dot.size/2,
                            width: dot.size,
                            height: dot.size
                        )
                        
                        // Subtle monochrome colors
                        let normalizedDistance = min(dot.distanceFromCenter / (size.width * 0.7), 1.0)
                        let opacity = 0.4 - normalizedDistance * 0.3
                        
                        context.fill(
                            Circle().path(in: rect),
                            with: .color(Color(hex: "#DDDDDD").opacity(opacity))
                        )
                    }
                }
            }
            .onAppear {
                setupDots(size: geometry.size)
                startAnimation()
            }
            .onChange(of: geometry.size) { newSize in
                setupDots(size: newSize)
            }
        }
        .ignoresSafeArea() // Cover entire screen including safe areas
        .onChange(of: metronome.shouldBlink) { newValue in
            if newValue {
                triggerPulse()
            }
        }
    }
    
    private func setupDots(size: CGSize) {
        dots = []
        
        let centerX = size.width / 2
        let centerY = size.height / 2
        
        // Calculate how many dots we need to cover the screen
        let cols = Int(size.width / dotSpacing) + 6 // Extra dots to ensure full coverage
        let rows = Int(size.height / dotSpacing) + 6
        
        // Start from beyond the edges to ensure full coverage
        let startX = -dotSpacing * 2
        let startY = -dotSpacing * 2
        
        for row in 0..<rows {
            var dotRow: [Dot] = []
            
            for col in 0..<cols {
                let baseX = startX + CGFloat(col) * dotSpacing
                let baseY = startY + CGFloat(row) * dotSpacing
                
                let dx = baseX - centerX
                let dy = baseY - centerY
                let distance = sqrt(dx * dx + dy * dy)
                
                let dot = Dot(
                    baseX: baseX,
                    baseY: baseY,
                    x: baseX,
                    y: baseY,
                    size: 1.5, // Smaller dots
                    distanceFromCenter: distance
                )
                
                dotRow.append(dot)
            }
            dots.append(dotRow)
        }
    }
    
    private func triggerPulse() {
        // Adjust pulse intensity based on note value
        let intensity = getPulseIntensity()
        if intensity > 0 {
            pulseTime = 0
        }
    }
    
    private func getPulseIntensity() -> CGFloat {
        // If not playing (tap tempo), always use full intensity
        if !metronome.isPlaying {
            return 1.0
        }
        
        // Check if current beat is accented
        let isAccented = metronome.currentBeat >= 0 && 
                        metronome.currentBeat < metronome.accentPattern.count && 
                        metronome.accentPattern[metronome.currentBeat]
        
        // Base intensity: full for accented, half for non-accented
        let baseIntensity: CGFloat = isAccented ? 1.0 : 0.5
        
        // BPM-based intensity scaling
        let bpmFactor: CGFloat = {
            if metronome.bpm <= 100 {
                return 1.0  // Full intensity at slow speeds
            } else if metronome.bpm >= 180 {
                return 0.3  // Minimal intensity at high speeds
            } else {
                // Linear interpolation between 100-180 BPM
                return 1.0 - ((metronome.bpm - 100) / 80) * 0.7
            }
        }()
        
        return baseIntensity * bpmFactor
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
            updateDots()
        }
    }
    
    private func updateDots() {
        // Slower wave movement at higher BPMs
        let speedScale = max(0.5, 1.0 - (metronome.bpm - 80) / 160)
        wavePhase += 0.03 * speedScale
        
        // Pulse wave
        if pulseTime < 1.0 {
            pulseTime += 1.0/30.0 // Faster pulse
        }
        
        guard !dots.isEmpty else { return }
        
        let centerX = UIScreen.main.bounds.width / 2
        let centerY = UIScreen.main.bounds.height / 2
        
        // Update each dot
        for row in 0..<dots.count {
            for col in 0..<dots[row].count {
                var dot = dots[row][col]
                
                // Calculate wave displacement
                let waveRadius = pulseTime * 600
                let waveDistance = abs(dot.distanceFromCenter - waveRadius)
                
                var displacement: CGFloat = 0
                var sizeMultiplier: CGFloat = 1.0
                
                // Sharp, fast wave effect with intensity based on note value
                let intensity = getPulseIntensity()
                if waveDistance < 80 && pulseTime < 1.0 && intensity > 0 {
                    let waveStrength = 1.0 - waveDistance / 80
                    let fadeOut = 1.0 - pulseTime
                    displacement = Darwin.sin(waveDistance * 0.1) * 20 * waveStrength * fadeOut * intensity
                    sizeMultiplier = 1.0 + waveStrength * fadeOut * intensity
                }
                
                // Apply displacement radially
                let angle = Darwin.atan2(dot.baseY - centerY, dot.baseX - centerX)
                let displacementX = Darwin.cos(angle) * displacement
                let displacementY = Darwin.sin(angle) * displacement
                
                // Subtle ambient wave motion (also scaled by BPM)
                let bpmScale = max(0.3, 1.0 - (metronome.bpm - 80) / 120)
                let ambientWave = Darwin.sin(wavePhase + dot.distanceFromCenter * 0.008) * 2 * bpmScale
                
                // Update position
                dot.x = dot.baseX + displacementX + Darwin.cos(wavePhase * 0.5 + CGFloat(row) * 0.05) * ambientWave
                dot.y = dot.baseY + displacementY + Darwin.sin(wavePhase * 0.5 + CGFloat(col) * 0.05) * ambientWave
                dot.size = 1.5 * sizeMultiplier
                
                dots[row][col] = dot
            }
        }
    }
}