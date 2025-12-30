import SwiftUI

struct Star: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGPoint = .zero
    var size: CGFloat
    var opacity: Double
    var baseOpacity: Double
    var brightness: Double = 1.0
    var distanceFromCenter: CGFloat
}

struct PulseRing {
    var radius: CGFloat = 0
    var opacity: Double = 1.0
    var age: TimeInterval = 0
    var speed: CGFloat
}

struct StarFieldView: View {
    @ObservedObject var metronome: MetronomeManager
    @State private var stars: [Star] = []
    @State private var pulseRings: [PulseRing] = []
    @State private var animationTimer: Timer?
    @State private var lastUpdateTime = Date()
    
    let baseStarCount = 500
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Golden pulse rings (visible)
                ForEach(0..<pulseRings.count, id: \.self) { index in
                    if index < pulseRings.count {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "#FFD700").opacity(pulseRings[index].opacity * 0.6),
                                        Color(hex: "#FFA500").opacity(pulseRings[index].opacity * 0.3),
                                        Color.clear
                                    ],
                                    startPoint: .center,
                                    endPoint: .trailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: pulseRings[index].radius * 2, height: pulseRings[index].radius * 2)
                            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                            .blur(radius: pulseRings[index].opacity < 0.3 ? 2 : 0)
                    }
                }
                
                // Stars
                ForEach(stars) { star in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: "#FFD700").opacity(star.opacity * star.brightness),
                                    Color(hex: "#FFA500").opacity(star.opacity * star.brightness * 0.5),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: star.size
                            )
                        )
                        .frame(width: star.size * 2, height: star.size * 2)
                        .position(star.position)
                        .blur(radius: star.size < 1 ? 0.3 : 0)
                }
            }
            .onAppear {
                generateStars(in: geometry.size)
                startAnimation()
            }
            .onDisappear {
                animationTimer?.invalidate()
            }
            .onChange(of: metronome.shouldBlink) { _, newValue in
                if newValue && metronome.isPlaying {
                    triggerPulse(in: geometry.size)
                }
            }
        }
    }
    
    private func generateStars(in size: CGSize) {
        stars = []
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let maxRadius = min(size.width, size.height) * 0.4
        
        // Create stars in concentric circles
        for ring in 0..<8 {
            let ringRadius = maxRadius * CGFloat(ring + 1) / 8.0
            let starsInRing = 20 + ring * 10
            
            for i in 0..<starsInRing {
                let angle = (360.0 / Double(starsInRing)) * Double(i) + Double.random(in: -10...10)
                let radian = angle * .pi / 180
                
                let radiusVariation = CGFloat.random(in: 0.8...1.2)
                let actualRadius = ringRadius * radiusVariation
                
                let x = center.x + Darwin.cos(radian) * actualRadius
                let y = center.y + Darwin.sin(radian) * actualRadius
                
                let star = Star(
                    position: CGPoint(x: x, y: y),
                    size: CGFloat.random(in: 0.5...2.0),
                    opacity: Double.random(in: 0.3...0.8),
                    baseOpacity: Double.random(in: 0.3...0.8),
                    distanceFromCenter: actualRadius
                )
                
                stars.append(star)
            }
        }
    }
    
    private func triggerPulse(in size: CGSize) {
        let isAccent = metronome.currentBeat < metronome.accentPattern.count && 
                      metronome.accentPattern[metronome.currentBeat]
        
        // Create a single strong pulse
        let pulse = PulseRing(
            radius: 10,
            opacity: 1.0,
            age: 0,
            speed: isAccent ? 250 : 200
        )
        pulseRings.append(pulse)
        
        // Keep only recent rings
        if pulseRings.count > 5 {
            pulseRings.removeFirst()
        }
    }
    
    private func updateStars(deltaTime: TimeInterval, in size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        
        for i in stars.indices {
            var star = stars[i]
            
            // Apply velocity with damping
            star.position.x += star.velocity.x * deltaTime
            star.position.y += star.velocity.y * deltaTime
            star.velocity.x *= pow(0.9, deltaTime * 60)
            star.velocity.y *= pow(0.9, deltaTime * 60)
            
            // Check pulse ring interactions
            for ring in pulseRings {
                let ringRadius = ring.radius
                let starDist = star.distanceFromCenter
                
                // When ring passes through star
                if abs(starDist - ringRadius) < 20 {
                    let intensity = (1.0 - abs(starDist - ringRadius) / 20) * ring.opacity
                    
                    // Boost brightness
                    star.brightness = min(2.5, star.brightness + intensity * 1.5)
                    
                    // Small outward push
                    let dx = star.position.x - center.x
                    let dy = star.position.y - center.y
                    let dist = sqrt(dx * dx + dy * dy)
                    if dist > 0 {
                        let pushAngle = atan2(dy, dx)
                        let pushForce = intensity * 15
                        star.velocity.x += Darwin.cos(pushAngle) * pushForce
                        star.velocity.y += Darwin.sin(pushAngle) * pushForce
                    }
                }
            }
            
            // Update distance from center
            let dx = star.position.x - center.x
            let dy = star.position.y - center.y
            star.distanceFromCenter = sqrt(dx * dx + dy * dy)
            
            // Brightness decay
            star.brightness = max(1.0, star.brightness - deltaTime * 2)
            
            // Gentle drift back
            if star.distanceFromCenter > 20 {
                let pullAngle = atan2(center.y - star.position.y, center.x - star.position.x)
                let pullForce = min(10, star.distanceFromCenter / 50) * deltaTime
                star.velocity.x += Darwin.cos(pullAngle) * pullForce
                star.velocity.y += Darwin.sin(pullAngle) * pullForce
            }
            
            // Base opacity modulation
            if metronome.isPlaying {
                let time = Date().timeIntervalSinceReferenceDate
                let breathe = Darwin.sin(time * 1.5 + Double(i) * 0.1) * 0.2 + 0.8
                star.opacity = star.baseOpacity * breathe
            } else {
                star.opacity = star.baseOpacity * 0.4
            }
            
            stars[i] = star
        }
        
        // Update rings
        for i in pulseRings.indices.reversed() {
            pulseRings[i].age += deltaTime
            pulseRings[i].radius += pulseRings[i].speed * deltaTime
            
            // Fade out
            let maxAge: TimeInterval = 1.5
            pulseRings[i].opacity = max(0, 1.0 - pulseRings[i].age / maxAge)
            
            if pulseRings[i].age > maxAge {
                pulseRings.remove(at: i)
            }
        }
    }
    
    private func startAnimation() {
        lastUpdateTime = Date()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
            DispatchQueue.main.async { [self] in
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    let now = Date()
                    let deltaTime = now.timeIntervalSince(self.lastUpdateTime)
                    self.lastUpdateTime = now
                    
                    let size = window.bounds.size
                    self.updateStars(deltaTime: deltaTime, in: size)
                }
            }
        }
    }
}