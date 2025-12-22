import SwiftUI

/// Single firework particle
private struct FireworkParticle: Identifiable {
  let id = UUID()
  var position: CGPoint
  var velocity: CGVector
  let birthTime: TimeInterval
  let lifespan: TimeInterval
  let baseRadius: CGFloat
  let color: Color
}

public struct FireworksView: View {
  public init(
    audioLevel: Float = 0.0,
    particlesPerFirework: Int = 80,
    launchIntervalRange: ClosedRange<Double> = 0.5...1.5,
    gravity: CGFloat = 300,
    audioThreshold: Float = 0.05
  ) {
    self.audioLevel = audioLevel
    self.particlesPerFirework = particlesPerFirework
    self.launchIntervalRange = launchIntervalRange
    self.gravity = gravity
    self.audioThreshold = audioThreshold
  }

  @State private var particles: [FireworkParticle] = []
  @State private var lastUpdateTime: TimeInterval = 0
  @State private var nextLaunchTime: TimeInterval = 0
  @State private var currentTime: TimeInterval = 0
  @State private var previousAudioLevel: Float = 0.0
  @State private var canvasSize: CGSize = .zero

  /// Audio input level (0.0–1.0)
  public var audioLevel: Float

  /// Number of particles per firework burst
  public var particlesPerFirework: Int

  /// Randomized range for launch intervals in seconds
  public var launchIntervalRange: ClosedRange<Double>

  /// Gravity strength (higher values make particles fall faster)
  public var gravity: CGFloat

  /// Threshold delta in the audio level that triggers a launch
  public var audioThreshold: Float

  public var body: some View {
    TimelineView(.animation) { timeline in
      let time = timeline.date.timeIntervalSinceReferenceDate

      Canvas { context, size in
        let drawTime = currentTime

        Task { @MainActor in
          updateState(for: time, canvasSize: size)
        }

        // MARK: Rendering
        for p in particles {
          let age = drawTime - p.birthTime
          if age > p.lifespan || age < 0 {
            continue
          }
          let t = max(0, min(1, age / p.lifespan))  // Normalized 0–1

          // Gradually shrink and fade over time
          let fade = pow(1 - t, 2.0)
          let radius = p.baseRadius * (0.7 + 0.6 * (1 - t))

          let rect = CGRect(
            x: p.position.x - radius,
            y: p.position.y - radius,
            width: radius * 2,
            height: radius * 2
          )

          context.fill(
            Path(ellipseIn: rect),
            with: .radialGradient(
              Gradient(colors: [
                p.color.opacity(Double(fade)),
                p.color.opacity(0),
              ]),
              center: p.position,
              startRadius: 0,
              endRadius: radius
            )
          )
        }
      }
      .onChange(of: time) { _, newTime in
        currentTime = newTime
      }
    }
    .background(Color.black)
    .ignoresSafeArea()
  }

  private func updateState(for time: TimeInterval, canvasSize size: CGSize?) {
    if lastUpdateTime == 0 {
      lastUpdateTime = time
      nextLaunchTime = time + Double.random(in: launchIntervalRange)
      if let size = size {
        canvasSize = size
      }
      return
    }

    if let size = size {
      canvasSize = size
    }

    let dt = time - lastUpdateTime
    lastUpdateTime = time

    // MARK: Particle updates (position + gravity) and lifetime checks
    var alive: [FireworkParticle] = []
    alive.reserveCapacity(particles.count)

    for var p in particles {
      let age = time - p.birthTime
      if age > p.lifespan {
        continue  // Lifetime ended
      }

      // Apply downward gravity
      var v = p.velocity
      v.dy += gravity * dt
      p.velocity = v

      // Update position based on new velocity
      p.position.x += v.dx * dt
      p.position.y += v.dy * dt

      alive.append(p)
    }
    particles = alive

    if audioLevel - previousAudioLevel >= audioThreshold || time >= nextLaunchTime {
      guard let size = size else { return }
      spawnFirework(
        at: randomFireworkOrigin(in: size),
        birthTime: time
      )
      nextLaunchTime = time + Double.random(in: launchIntervalRange)
    }
    previousAudioLevel = audioLevel
  }

  // Choose a firework origin near the upper middle portion of the screen
  private func randomFireworkOrigin(in size: CGSize) -> CGPoint {
    CGPoint(
      x: .random(in: size.width * 0.15...size.width * 0.85),
      y: .random(in: size.height * 0.15...size.height * 0.45)
    )
  }

  // Generate a single firework burst
  private func spawnFirework(at origin: CGPoint, birthTime: TimeInterval) {
    // Pick a base color per firework with slight variation
    let baseHue = Double.random(in: 0...1)

    var newParticles: [FireworkParticle] = []
    newParticles.reserveCapacity(particlesPerFirework)

    for _ in 0..<particlesPerFirework {
      let angle = Double.random(in: 0 ..< .pi * 2)

      // Initial velocity with a bit of variation
      let speed = Double.random(in: 80...260)
      let vx = cos(angle) * speed
      let vy = sin(angle) * speed

      // Slightly jitter the hue
      let hueJitter = Double.random(in: -0.03...0.03)
      let color = Color(
        hue: (baseHue + hueJitter)
          .truncatingRemainder(dividingBy: 1.0),
        saturation: 0.9,
        brightness: 1.0
      )

      let lifespan = Double.random(in: 0.8...1.8)
      let radius = CGFloat.random(in: 3...8)

      let particle = FireworkParticle(
        position: origin,
        velocity: CGVector(dx: vx, dy: vy),
        birthTime: birthTime,
        lifespan: lifespan,
        baseRadius: radius,
        color: color
      )
      newParticles.append(particle)
    }

    particles.append(contentsOf: newParticles)
  }

  // Launch fireworks in response to audio level spikes
  private func triggerAudioFirework() {
    guard canvasSize != .zero else { return }
    let origin = randomFireworkOrigin(in: canvasSize)
    spawnFirework(at: origin, birthTime: currentTime)
  }
}

#Preview {
  FireworksView()
}
