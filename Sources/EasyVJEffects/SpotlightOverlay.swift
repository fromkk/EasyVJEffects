import SwiftUI

struct Spotlight: Identifiable {
  let id: Int
  let color: Color
  let phaseOffset: CGFloat
  let centerOffset: CGPoint
  let scale: CGFloat
  let speed: CGFloat
  let size: CGSize
}

public struct SpotlightOverlay: View {
  let colors: [Color]
  let spotlights: [Spotlight]

  public init(colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange]) {
    // Give each spotlight a random initial position and parameters
    var lights: [Spotlight] = []
    for i in 0..<colors.count {
      let size: CGFloat = CGFloat.random(in: 100...1000)
      lights.append(
        Spotlight(
          id: i,
          color: colors[i],
          phaseOffset: CGFloat.random(in: 0...(2 * .pi)),
          centerOffset: CGPoint(
            x: CGFloat.random(in: -200...200),
            y: CGFloat.random(in: -200...200)
          ),
          scale: CGFloat.random(in: 1...5),
          speed: CGFloat.random(in: 0.5...1.5),
          size: CGSize(width: size, height: size)
        )
      )
    }
    self.spotlights = lights
    self.colors = colors
  }

  public var body: some View {
    TimelineView(.animation) { timeline in
      GeometryReader { geometry in
        let time = timeline.date.timeIntervalSinceReferenceDate

        ZStack {
          ForEach(spotlights) { spotlight in
            Circle()
              .fill(
                RadialGradient(
                  gradient: Gradient(colors: [
                    spotlight.color.opacity(0.6),
                    spotlight.color.opacity(0.3),
                    .clear,
                  ]),
                  center: .center,
                  startRadius: 0,
                  endRadius: spotlight.size.width / 2
                )
              )
              .frame(
                width: spotlight.size.width,
                height: spotlight.size.height
              )
              .position(
                figure8Position(
                  in: geometry.size,
                  time: time,
                  spotlight: spotlight
                )
              )
              .blur(radius: 20)
          }
        }
      }
      .ignoresSafeArea()
    }
  }

  /// Compute a figure-eight path
  private func figure8Position(
    in size: CGSize,
    time: TimeInterval,
    spotlight: Spotlight
  ) -> CGPoint {
    let centerX = size.width / 2 + spotlight.centerOffset.x
    let centerY = size.height / 2 + spotlight.centerOffset.y

    // Lemniscate (figure-eight) parametric equation
    let scale = min(size.width, size.height) * spotlight.scale
    let animatedPhase =
      (time * spotlight.speed).truncatingRemainder(dividingBy: 8) / 8 * 2 * .pi
    let t = animatedPhase + spotlight.phaseOffset

    let denominator = 1 + pow(sin(t), 2)
    let x = centerX + (scale * cos(t)) / denominator
    let y = centerY + (scale * sin(t) * cos(t)) / denominator

    return CGPoint(x: x, y: y)
  }
}

#Preview {
  ZStack {
    Color.black
    SpotlightOverlay()
  }
}
