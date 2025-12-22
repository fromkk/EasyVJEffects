import SwiftUI

public struct LaserFanView: View {
  /// Number of laser beams (raise it to make the effect denser)
  var beamCount: Int

  /// Beam movement speed (higher values create wilder motion)
  var speed: Double

  /// Rate at which the hue shifts over time
  var hueSpeed: Double

  /// Overall brightness (pass 0–1 when linking to audio levels)
  var globalIntensity: Float

  public init(beamCount: Int = 16, speed: Double = 1.5, hueSpeed: Double = 0.05, globalIntensity: Float) {
    self.beamCount = beamCount
    self.speed = speed
    self.hueSpeed = hueSpeed
    self.globalIntensity = globalIntensity
  }

  public var body: some View {
    TimelineView(.animation) { timeline in
      let time = timeline.date.timeIntervalSinceReferenceDate

      Canvas { context, size in
        let w = size.width
        let h = size.height

        // Laser origin near the bottom-center of the screen
        let origin = CGPoint(x: w / 2, y: h * 0.95)

        // Fan spread defined in degrees
        let spreadDegrees: Double = 80  // Fan opening
        let spread = Angle.degrees(spreadDegrees).radians
        let minAngle = -spread / 2
        let maxAngle = spread / 2

        // Beam length
        let beamLength = h * 1.2

        // Time-varying base hue shared across all beams
        let baseHue = (time * hueSpeed)
          .truncatingRemainder(dividingBy: 1.0)

        for i in 0..<beamCount {
          let progress = Double(i) / Double(max(beamCount - 1, 1))
          let phase = Double(i) * 1.2345  // Arbitrary phase offset

          // Evenly space beams in the fan plus small jitter for randomness
          let baseAngle = minAngle + (maxAngle - minAngle) * progress
          let jitter = 0.15 * sin(time * 0.7 + phase)
          let angle = baseAngle + jitter

          // Flicker effect so beams randomly pulse in and out
          let rawPulse = sin(time * 3.0 * speed + phase * 2.1)
          // Convert to a 0–1 range and sharpen it into a pulse
          var beamIntensity = max(0, rawPulse)
          // Use a smaller exponent so beams appear longer
          beamIntensity = pow(beamIntensity, 2)

          // Apply the global brightness (e.g., audio level)
          beamIntensity *= Double(globalIntensity)

          // Skip drawing when the beam is almost invisible
          // Lower threshold slightly so dim beams can still appear
          if beamIntensity < 0.01 { continue }

          // Convert the angle into a direction vector (0 rad means straight up)
          let dx = sin(angle)
          let dy = -cos(angle)

          // Beam end point
          let end = CGPoint(
            x: origin.x + dx * beamLength,
            y: origin.y + dy * beamLength
          )

          // Beam thickness (narrow base, wide tip)
          // Increase thickness to make beams stand out
          let nearWidth = 6.0 + 20.0 * beamIntensity
          let farWidth = nearWidth * 3.0

          // Normal vector relative to the beam (lateral direction)
          let nx = -dy
          let ny = dx

          // Normalize the normal vector
          let nLen = max(0.0001, sqrt(nx * nx + ny * ny))
          let ux = nx / nLen
          let uy = ny / nLen

          // Build a tapered polygon (narrow near the origin, wide at the tip)
          let p0 = CGPoint(
            x: origin.x + ux * nearWidth / 2,
            y: origin.y + uy * nearWidth / 2
          )
          let p1 = CGPoint(
            x: end.x + ux * farWidth / 2,
            y: end.y + uy * farWidth / 2
          )
          let p2 = CGPoint(
            x: end.x - ux * farWidth / 2,
            y: end.y - uy * farWidth / 2
          )
          let p3 = CGPoint(
            x: origin.x - ux * nearWidth / 2,
            y: origin.y - uy * nearWidth / 2
          )

          var beamPath = Path()
          beamPath.move(to: p0)
          beamPath.addLine(to: p1)
          beamPath.addLine(to: p2)
          beamPath.addLine(to: p3)
          beamPath.closeSubpath()

          // Color shifts slowly over time and is shared by all beams
          // Keep the color vibrant
          let color = Color(
            hue: baseHue,
            saturation: 1.0,
            brightness: 1.0
          )

          // Gradient fades from the beam origin to the tip
          // Make the origin brighter
          let gradient = Gradient(colors: [
            color.opacity(1.0 * beamIntensity),
            color.opacity(0.0),
          ])

          context.fill(
            beamPath,
            with: .linearGradient(
              gradient,
              startPoint: origin,
              endPoint: end
            )
          )

          // Accentuate a narrow central core to boost the laser look
          var core = Path()
          core.move(to: origin)
          core.addLine(to: end)
          // Draw the core with extra thickness for emphasis
          context.stroke(
            core,
            with: .color(color.opacity(0.9 * beamIntensity)),
            lineWidth: nearWidth * 0.8
          )
        }
      }
    }
  }
}

#Preview {
  ZStack {
    Color.black.ignoresSafeArea()
    LaserFanView(globalIntensity: 0.5)
      .ignoresSafeArea()
  }
}
