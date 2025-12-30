import SwiftUI

struct Star: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var opacity: Double
    var baseOpacity: Double
    var rotationAngle: Double
    var orbitRadius: CGFloat
    var orbitSpeed: Double
    var pulsePhase: Double
}

struct StarFieldView: View {
    @ObservedObject var metronome: MetronomeManager
    @State private var stars: [Star] = []
    @State private var pulseScale: CGFloat = 1.0
    @State private var rotationAngle: Double = 0
    
    let starCount = 60
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(stars) { star in
                    Circle()
                        .fill(Color.white)
                        .frame(width: star.size, height: star.size)
                        .opacity(calculateStarOpacity(star))
                        .position(calculateStarPosition(star, in: geometry.size))
                        .scaleEffect(calculateStarScale(star))
                        .blur(radius: star.size < 2 ? 0.5 : 0)
                }
            }
            .rotationEffect(.degrees(rotationAngle))
            .onAppear {
                generateStars(in: geometry.size)
                startAnimation()
            }
            .onChange(of: metronome.shouldBlink) { _, newValue in
                if newValue && metronome.isPlaying {
                    triggerPulse()
                }
            }
        }
    }
    
    private func generateStars(in size: CGSize) {
        stars = []
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let maxRadius = min(size.width, size.height) * 0.45
        
        for i in 0..<starCount {
            let angle = Double(i) * (360.0 / Double(starCount)) + Double.random(in: -15...15)
            let radius = CGFloat.random(in: 0.1...1.0)
            let actualRadius = radius * maxRadius
            
            let radian = angle * .pi / 180
            let x = center.x + cos(radian) * actualRadius
            let y = center.y + sin(radian) * actualRadius
            
            let star = Star(
                position: CGPoint(x: x, y: y),
                size: CGFloat.random(in: 1...4),
                opacity: Double.random(in: 0.3...0.8),
                baseOpacity: Double.random(in: 0.3...0.8),
                rotationAngle: angle,
                orbitRadius: actualRadius,
                orbitSpeed: Double.random(in: 0.2...0.5),
                pulsePhase: Double.random(in: 0...1)
            )
            
            stars.append(star)
        }
    }
    
    private func calculateStarPosition(_ star: Star, in size: CGSize) -> CGPoint {
        if !metronome.isPlaying {
            return star.position
        }
        
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let time = Date().timeIntervalSinceReferenceDate
        let angle = star.rotationAngle + (time * star.orbitSpeed * 10)
        let radian = angle * .pi / 180
        
        let x = center.x + cos(radian) * star.orbitRadius
        let y = center.y + sin(radian) * star.orbitRadius
        
        return CGPoint(x: x, y: y)
    }
    
    private func calculateStarOpacity(_ star: Star) -> Double {
        if !metronome.isPlaying {
            return star.baseOpacity * 0.5
        }
        
        let time = Date().timeIntervalSinceReferenceDate
        let pulse = sin(time * 2 + star.pulsePhase * .pi * 2) * 0.3 + 0.7
        return star.baseOpacity * pulse * pulseScale
    }
    
    private func calculateStarScale(_ star: Star) -> CGFloat {
        if !metronome.isPlaying {
            return 1.0
        }
        
        return 1.0 + (pulseScale - 1.0) * 0.5
    }
    
    private func triggerPulse() {
        let isAccent = metronome.currentBeat < metronome.accentPattern.count && 
                      metronome.accentPattern[metronome.currentBeat]
        
        withAnimation(.easeOut(duration: 0.1)) {
            pulseScale = isAccent ? 1.3 : 1.15
        }
        
        withAnimation(.easeIn(duration: 0.3).delay(0.1)) {
            pulseScale = 1.0
        }
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            if metronome.isPlaying {
                rotationAngle += 0.1
            }
        }
    }
}