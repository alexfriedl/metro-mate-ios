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
    
    let gridSize = 30 // Balanced grid size
    let dotSpacing: CGFloat = 12
    
    var body: some View {
        Canvas { context, size in
            let centerX = size.width / 2
            let centerY = size.height / 2
            
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
                    let normalizedDistance = min(dot.distanceFromCenter / 250, 1.0)
                    let opacity = 0.4 - normalizedDistance * 0.3
                    
                    context.fill(
                        Circle().path(in: rect),
                        with: .color(Color(hex: "#DDDDDD").opacity(opacity))
                    )
                }
            }
        }
        .onAppear {
            setupDots()
            startAnimation()
        }
        .onChange(of: metronome.shouldBlink) { _, newValue in
            if newValue && metronome.isPlaying {
                triggerPulse()
            }
        }
    }
    
    private func setupDots() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let centerX = screenWidth / 2
        let centerY = screenHeight / 2
        
        dots = []
        
        // Create grid
        let startX = centerX - CGFloat(gridSize / 2) * dotSpacing
        let startY = centerY - CGFloat(gridSize / 2) * dotSpacing
        
        for row in 0..<gridSize {
            var dotRow: [Dot] = []
            
            for col in 0..<gridSize {
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
                    size: 2.5,
                    distanceFromCenter: distance
                )
                
                dotRow.append(dot)
            }
            dots.append(dotRow)
        }
    }
    
    private func triggerPulse() {
        pulseTime = 0
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
            updateDots()
        }
    }
    
    private func updateDots() {
        wavePhase += 0.03
        
        // Pulse wave
        if pulseTime < 1.0 {
            pulseTime += 1.0/30.0 // Faster pulse
        }
        
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let centerX = screenWidth / 2
        let centerY = screenHeight / 2
        
        // Update each dot
        for row in 0..<dots.count {
            for col in 0..<dots[row].count {
                var dot = dots[row][col]
                
                // Calculate wave displacement
                let waveRadius = pulseTime * 500
                let waveDistance = abs(dot.distanceFromCenter - waveRadius)
                
                var displacement: CGFloat = 0
                var sizeMultiplier: CGFloat = 1.0
                
                // Sharp, fast wave effect
                if waveDistance < 60 && pulseTime < 1.0 {
                    let waveStrength = 1.0 - waveDistance / 60
                    let fadeOut = 1.0 - pulseTime
                    displacement = Darwin.sin(waveDistance * 0.1) * 15 * waveStrength * fadeOut
                    sizeMultiplier = 1.0 + waveStrength * fadeOut * 0.8
                }
                
                // Apply displacement radially
                let angle = Darwin.atan2(dot.baseY - centerY, dot.baseX - centerX)
                let displacementX = Darwin.cos(angle) * displacement
                let displacementY = Darwin.sin(angle) * displacement
                
                // Subtle ambient wave motion
                let ambientWave = Darwin.sin(wavePhase + dot.distanceFromCenter * 0.008) * 1.5
                
                // Update position
                dot.x = dot.baseX + displacementX + Darwin.cos(wavePhase * 0.5 + CGFloat(row) * 0.05) * ambientWave
                dot.y = dot.baseY + displacementY + Darwin.sin(wavePhase * 0.5 + CGFloat(col) * 0.05) * ambientWave
                dot.size = 2.5 * sizeMultiplier
                
                dots[row][col] = dot
            }
        }
    }
}