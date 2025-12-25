import SwiftUI

/// Single snowflake particle
private struct Snowflake: Identifiable {
  let id = UUID()
  var position: CGPoint
  var velocity: CGVector
  var rotationAngle: Double
  var rotationSpeed: Double
  let size: CGFloat
  let opacity: Double
}

public struct SnowfallView: View {
  public init(
    audioLevel: Float = 0.0,
    snowflakeCount: Int = 100,
    windStrength: CGFloat = 30,
    fallSpeed: CGFloat = 50
  ) {
    self.audioLevel = audioLevel
    self.snowflakeCount = snowflakeCount
    self.windStrength = windStrength
    self.fallSpeed = fallSpeed
  }

  @State private var snowflakes: [Snowflake] = []
  @State private var lastUpdateTime: TimeInterval = 0
  @State private var canvasSize: CGSize = .zero

  /// Audio input level (0.0–1.0)
  public var audioLevel: Float

  /// Total number of snowflakes on screen
  public var snowflakeCount: Int

  /// Horizontal wind strength (affects side-to-side movement)
  public var windStrength: CGFloat

  /// Vertical fall speed
  public var fallSpeed: CGFloat

  public var body: some View {
    TimelineView(.animation) { timeline in
      let time = timeline.date.timeIntervalSinceReferenceDate

      Canvas { context, size in
        Task { @MainActor in
          updateState(for: time, canvasSize: size)
        }

        // MARK: Rendering
        for flake in snowflakes {
          let rect = CGRect(
            x: flake.position.x - flake.size / 2,
            y: flake.position.y - flake.size / 2,
            width: flake.size,
            height: flake.size
          )

          // Create a snowflake shape
          var path = Path()
          let center = CGPoint(x: rect.midX, y: rect.midY)
          let radius = flake.size / 2

          // Draw a simple 6-pointed snowflake
          for i in 0..<6 {
            let angle = Double(i) * .pi / 3 + flake.rotationAngle
            let endX = center.x + radius * CGFloat(cos(angle))
            let endY = center.y + radius * CGFloat(sin(angle))
            path.move(to: center)
            path.addLine(to: CGPoint(x: endX, y: endY))
          }

          context.stroke(
            path,
            with: .color(.white.opacity(flake.opacity)),
            lineWidth: 1.5
          )
        }
      }
    }
    .ignoresSafeArea()
  }

  private func updateState(for time: TimeInterval, canvasSize: CGSize) {
    // First time initialization
    if lastUpdateTime == 0 {
      lastUpdateTime = time
      self.canvasSize = canvasSize
      initializeSnowflakes(in: canvasSize)
      return
    }

    // Canvas size changed, reinitialize
    if canvasSize != self.canvasSize {
      self.canvasSize = canvasSize
      initializeSnowflakes(in: canvasSize)
      return
    }

    let dt = time - lastUpdateTime
    lastUpdateTime = time

    // Update each snowflake
    for i in snowflakes.indices {
      var flake = snowflakes[i]

      // Apply velocity
      let audioBoost = 1.0 + CGFloat(audioLevel) * 0.5
      flake.position.x += flake.velocity.dx * dt
      flake.position.y += flake.velocity.dy * dt * audioBoost

      // Rotate snowflake
      flake.rotationAngle += flake.rotationSpeed * dt

      // Wrap around horizontally
      if flake.position.x < -flake.size {
        flake.position.x = canvasSize.width + flake.size
      } else if flake.position.x > canvasSize.width + flake.size {
        flake.position.x = -flake.size
      }

      // Reset to top when snowflake goes off bottom
      if flake.position.y > canvasSize.height + flake.size {
        flake.position.y = -flake.size
        flake.position.x = CGFloat.random(in: 0...canvasSize.width)
      }

      snowflakes[i] = flake
    }
  }

  private func initializeSnowflakes(in size: CGSize) {
    snowflakes = (0..<snowflakeCount).map { _ in
      let flakeSize = CGFloat.random(in: 4...12)
      let windVariation = CGFloat.random(in: -windStrength...windStrength)

      return Snowflake(
        position: CGPoint(
          x: CGFloat.random(in: 0...size.width),
          y: CGFloat.random(in: -size.height...size.height)
        ),
        velocity: CGVector(
          dx: windVariation,
          dy: fallSpeed + CGFloat.random(in: -10...10)
        ),
        rotationAngle: Double.random(in: 0...(2 * .pi)),
        rotationSpeed: Double.random(in: -1...1),
        size: flakeSize,
        opacity: Double.random(in: 0.5...1.0)
      )
    }
  }
}

#Preview {
  ZStack {
    Color.black
    SnowfallView(
      audioLevel: 0.3,
      snowflakeCount: 150,
      windStrength: 40,
      fallSpeed: 60
    )
  }
}
