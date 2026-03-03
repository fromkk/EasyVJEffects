import SwiftUI

/// Single cherry blossom petal particle
private struct Petal: Identifiable {
  let id = UUID()
  var position: CGPoint
  var velocity: CGVector
  var rotationAngle: Double
  var rotationSpeed: Double
  var swayPhase: Double
  let swayAmplitude: CGFloat
  let swayFrequency: Double
  let width: CGFloat
  let height: CGFloat
  let opacity: Double
  let color: Color
}

public struct CherryBlossomsView: View {
  public init(
    audioLevel: Float = 0.0,
    petalCount: Int = 80,
    windStrength: CGFloat = 20,
    fallSpeed: CGFloat = 60,
    petalSizeRange: ClosedRange<CGFloat> = 8...18
  ) {
    self.audioLevel = audioLevel
    self.petalCount = petalCount
    self.windStrength = windStrength
    self.fallSpeed = fallSpeed
    self.petalSizeRange = petalSizeRange
  }

  @State private var petals: [Petal] = []
  @State private var lastUpdateTime: TimeInterval = 0
  @State private var canvasSize: CGSize = .zero

  /// Audio input level (0.0–1.0)
  public var audioLevel: Float

  /// Total number of petals on screen
  public var petalCount: Int

  /// Horizontal wind strength
  public var windStrength: CGFloat

  /// Vertical fall speed
  public var fallSpeed: CGFloat

  /// Size range for petals (width)
  public var petalSizeRange: ClosedRange<CGFloat>

  public var body: some View {
    TimelineView(.animation) { timeline in
      let time = timeline.date.timeIntervalSinceReferenceDate

      Canvas { context, size in
        Task { @MainActor in
          updateState(for: time, canvasSize: size)
        }

        // MARK: Rendering
        for petal in petals {
          let hw = petal.width / 2
          let hh = petal.height / 2

          // Build petal path (rounded ellipse with a slight heart notch at top)
          var path = Path()
          path.move(to: CGPoint(x: 0, y: -hh))
          path.addCurve(
            to: CGPoint(x: 0, y: hh),
            control1: CGPoint(x: hw * 1.4, y: -hh * 0.6),
            control2: CGPoint(x: hw * 1.4, y: hh * 0.6)
          )
          path.addCurve(
            to: CGPoint(x: 0, y: -hh),
            control1: CGPoint(x: -hw * 1.4, y: hh * 0.6),
            control2: CGPoint(x: -hw * 1.4, y: -hh * 0.6)
          )
          path.closeSubpath()

          var transform = CGAffineTransform(translationX: petal.position.x, y: petal.position.y)
          transform = transform.rotated(by: petal.rotationAngle)

          context.fill(
            path.applying(transform),
            with: .color(petal.color.opacity(petal.opacity))
          )
        }
      }
    }
    .ignoresSafeArea()
  }

  private func updateState(for time: TimeInterval, canvasSize: CGSize) {
    if lastUpdateTime == 0 {
      lastUpdateTime = time
      self.canvasSize = canvasSize
      initializePetals(in: canvasSize)
      return
    }

    if canvasSize != self.canvasSize {
      self.canvasSize = canvasSize
      initializePetals(in: canvasSize)
      return
    }

    let dt = time - lastUpdateTime
    lastUpdateTime = time

    let audioBoost = 1.0 + CGFloat(audioLevel) * 0.8

    for i in petals.indices {
      var petal = petals[i]

      // Advance sway phase
      petal.swayPhase += petal.swayFrequency * dt

      // Sinusoidal horizontal sway
      let swayOffset = petal.swayAmplitude * CGFloat(sin(petal.swayPhase))

      petal.position.x += (petal.velocity.dx + swayOffset) * dt
      petal.position.y += petal.velocity.dy * dt * audioBoost

      // Rotate petal
      petal.rotationAngle += petal.rotationSpeed * dt

      // Wrap horizontally
      if petal.position.x < -petal.width {
        petal.position.x = canvasSize.width + petal.width
      } else if petal.position.x > canvasSize.width + petal.width {
        petal.position.x = -petal.width
      }

      // Reset to top when petal exits bottom
      if petal.position.y > canvasSize.height + petal.height {
        petal.position.y = -petal.height
        petal.position.x = CGFloat.random(in: 0...canvasSize.width)
      }

      petals[i] = petal
    }
  }

  private func initializePetals(in size: CGSize) {
    let petalColors: [Color] = [
      Color(red: 1.0, green: 0.80, blue: 0.85),
      Color(red: 1.0, green: 0.75, blue: 0.80),
      Color(red: 0.98, green: 0.85, blue: 0.90),
      Color(red: 1.0, green: 0.70, blue: 0.78),
      Color(red: 1.0, green: 0.90, blue: 0.93),
    ]

    petals = (0..<petalCount).map { _ in
      let width = CGFloat.random(in: petalSizeRange)
      let height = width * CGFloat.random(in: 0.55...0.75)
      let wind = CGFloat.random(in: -windStrength...windStrength)

      return Petal(
        position: CGPoint(
          x: CGFloat.random(in: 0...size.width),
          y: CGFloat.random(in: -size.height...size.height)
        ),
        velocity: CGVector(
          dx: wind,
          dy: fallSpeed + CGFloat.random(in: -15...15)
        ),
        rotationAngle: Double.random(in: 0...(2 * .pi)),
        rotationSpeed: Double.random(in: -1.5...1.5),
        swayPhase: Double.random(in: 0...(2 * .pi)),
        swayAmplitude: CGFloat.random(in: 10...40),
        swayFrequency: Double.random(in: 0.5...1.5),
        width: width,
        height: height,
        opacity: Double.random(in: 0.6...1.0),
        color: petalColors.randomElement()!
      )
    }
  }
}

#Preview {
  ZStack {
    Color.black
    CherryBlossomsView(
      audioLevel: 0.3,
      petalCount: 120,
      windStrength: 30,
      fallSpeed: 70,
      petalSizeRange: 8...20
    )
  }
}
