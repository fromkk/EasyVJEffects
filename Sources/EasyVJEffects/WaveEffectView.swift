import SwiftUI

/// Audio-reactive wave effect view that expands from the center of the screen
public struct WaveEffectView: View {
  // Wave settings
  private let numberOfWaves: Int

  /// Speed at which the hue shifts
  private let hueSpeed: Double

  var audioLevel: Float

  public init(
    audioLevel: Float,
    numberOfWaves: Int = 8,
    hueSpeed: Double = 0.05
  ) {
    self.audioLevel = audioLevel
    self.numberOfWaves = numberOfWaves
    self.hueSpeed = hueSpeed
  }

  public var body: some View {
    GeometryReader { geometry in
      ZStack {
        TimelineView(.animation) { timeline in
          let time = timeline.date.timeIntervalSinceReferenceDate
          let audioLevel = Double(audioLevel)

          // Base color that evolves over time (shared hue for all waves)
          let baseHue = (time * hueSpeed)
            .truncatingRemainder(dividingBy: 1.0)
          let color = Color(
            hue: baseHue,
            saturation: 1.0,
            brightness: 1.0
          )

          ZStack {
            ForEach(0..<numberOfWaves, id: \.self) { index in
              WaveCircle(
                index: index,
                time: time,
                audioLevel: audioLevel,
                color: color,
                screenSize: geometry.size
              )
            }
          }
        }
      }
    }
  }
}

/// Individual wave circle view
struct WaveCircle: View {
  let index: Int
  let time: TimeInterval
  let audioLevel: Double
  let color: Color
  let screenSize: CGSize

  // Wave animation parameters
  private var phase: Double {
    // Each wave has a time offset for staggered expansion
    let phaseOffset = Double(index) * 0.5
    return (time * 0.8 + phaseOffset).truncatingRemainder(dividingBy: 3.0)
  }

  private var scale: CGFloat {
    // Adjust wave scale based on audio level
    let baseScale = CGFloat(phase / 3.0)
    let audioScale = 1.0 + CGFloat(audioLevel) * 2.0
    return baseScale * audioScale
  }

  private var opacity: Double {
    // Fade out as wave expands
    let fadeOut = 1.0 - (phase / 3.0)
    // Brighter when audio is louder
    let audioBoost = 0.2 + audioLevel * 0.8
    return fadeOut * audioBoost
  }

  var body: some View {
    let maxDimension = max(screenSize.width, screenSize.height)
    let baseSize = maxDimension * 0.9

    Circle()
      .strokeBorder(
        color.opacity(opacity),
        lineWidth: 3 + CGFloat(audioLevel) * 15
      )
      .frame(
        width: baseSize * scale,
        height: baseSize * scale
      )
      .blur(radius: 2 + audioLevel * 8)
      .position(x: screenSize.width / 2, y: screenSize.height / 2)
  }
}

#Preview("WaveEffectView") {
  ZStack {
    Color.black
    WaveEffectView(audioLevel: 0.5)
  }

}

#Preview("WaveCircle") {
  ZStack {
    Color.black
    WaveCircle(
      index: 0,
      time: 1,
      audioLevel: 1,
      color: .blue.opacity(0.8),
      screenSize: CGSize(width: 1920, height: 1280)
    )
  }
}
