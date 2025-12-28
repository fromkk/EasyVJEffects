import SwiftUI

/// Single raindrop particle
private struct Raindrop: Identifiable {
  let id = UUID()
  var position: CGPoint
  var velocity: CGVector
  let length: CGFloat
  let thickness: CGFloat
  let opacity: Double
}

public struct RainfallView: View {
  public init(
    audioLevel: Float = 0.0,
    raindropCount: Int = 30,
    windStrength: CGFloat = 1,
    fallSpeed: CGFloat = 100,
    raindropLengthRange: ClosedRange<CGFloat> = 20...40,
    raindropThicknessRange: ClosedRange<CGFloat> = 1.0...2.0,
    raindropOpacityRange: ClosedRange<Double> = 0.5...0.8
  ) {
    self.audioLevel = audioLevel
    self.raindropCount = raindropCount
    self.windStrength = windStrength
    self.fallSpeed = fallSpeed
    self.raindropLengthRange = raindropLengthRange
    self.raindropThicknessRange = raindropThicknessRange
    self.raindropOpacityRange = raindropOpacityRange
  }

  @State private var raindrops: [Raindrop] = []
  @State private var lastUpdateTime: TimeInterval = 0
  @State private var canvasSize: CGSize = .zero

  /// Audio input level (0.0–1.0)
  public var audioLevel: Float

  /// Total number of raindrops on screen
  public var raindropCount: Int

  /// Horizontal wind strength (affects side-to-side movement)
  public var windStrength: CGFloat

  /// Vertical fall speed
  public var fallSpeed: CGFloat

  /// Length range for raindrops
  public var raindropLengthRange: ClosedRange<CGFloat>

  /// Thickness range for raindrops
  public var raindropThicknessRange: ClosedRange<CGFloat>

  /// Opacity range for raindrops
  public var raindropOpacityRange: ClosedRange<Double>

  public var body: some View {
    TimelineView(.animation) { timeline in
      let time = timeline.date.timeIntervalSinceReferenceDate

      Canvas { context, size in
        Task { @MainActor in
          updateState(for: time, canvasSize: size)
        }

        // MARK: Rendering
        for drop in raindrops {
          // Calculate angle based on wind (horizontal velocity)
          // Vertical direction is constant, wind affects the angle
          let angle = atan2(drop.velocity.dx, drop.velocity.dy)

          var path = Path()
          let startPoint = drop.position
          let endPoint = CGPoint(
            x: drop.position.x + drop.length * sin(angle),
            y: drop.position.y - drop.length * cos(angle)
          )

          path.move(to: startPoint)
          path.addLine(to: endPoint)

          context.stroke(
            path,
            with: .color(.white.opacity(drop.opacity)),
            lineWidth: drop.thickness
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
      initializeRaindrops(in: canvasSize)
      return
    }

    // Canvas size changed, reinitialize
    if canvasSize != self.canvasSize {
      self.canvasSize = canvasSize
      initializeRaindrops(in: canvasSize)
      return
    }

    let dt = time - lastUpdateTime
    lastUpdateTime = time

    // Update each raindrop
    for i in raindrops.indices {
      var drop = raindrops[i]

      // Apply velocity with audio boost
      let audioBoost = 1.0 + CGFloat(audioLevel) * 0.8
      drop.position.x += drop.velocity.dx * dt
      drop.position.y += drop.velocity.dy * dt * audioBoost

      // Wrap around horizontally
      if drop.position.x < -drop.length {
        drop.position.x = canvasSize.width + drop.length
      } else if drop.position.x > canvasSize.width + drop.length {
        drop.position.x = -drop.length
      }

      // Reset to top when raindrop goes off bottom
      if drop.position.y > canvasSize.height + drop.length {
        drop.position.y = -drop.length
        drop.position.x = CGFloat.random(in: 0...canvasSize.width)
      }

      raindrops[i] = drop
    }
  }

  private func initializeRaindrops(in size: CGSize) {
    raindrops = (0..<raindropCount).map { _ in
      let length = CGFloat.random(in: raindropLengthRange)
      let windVariation = CGFloat.random(in: -windStrength...windStrength)

      return Raindrop(
        position: CGPoint(
          x: CGFloat.random(in: 0...size.width),
          y: CGFloat.random(in: -size.height...size.height)
        ),
        velocity: CGVector(
          dx: windVariation,
          dy: fallSpeed + CGFloat.random(in: -50...50)
        ),
        length: length,
        thickness: CGFloat.random(in: raindropThicknessRange),
        opacity: Double.random(in: raindropOpacityRange)
      )
    }
  }
}

#Preview {
  ZStack {
    Color.black
    RainfallView(
      audioLevel: 0.4,
      raindropCount: 300,
      windStrength: 20,
      fallSpeed: 500
    )
  }
}
