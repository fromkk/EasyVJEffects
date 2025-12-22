# EasyVJEffects
SwiftUI views for quickly prototyping VJ/visualizer style overlays—fireworks, laser fans, spotlight washes, and concentric waves. Every effect is lightweight, customizable, and can react to an audio intensity value so you can sync it with music, microphone input, or Core Audio metering.

## Requirements
- Swift 6.2 (Swift Package Manager)
- iOS 17 / macOS 14 / visionOS 1 or newer
- SwiftUI

## Installation
Add the package with Swift Package Manager and target `EasyVJEffects`.

```swift
dependencies: [
  .package(
    url: "https://github.com/fromkk/EasyVJEffects.git",
    branch: "main"
  )
]
```

Then import the module where you render your overlays.

```swift
import EasyVJEffects
```

## Provided Views
| View | Description | Key Parameters |
| --- | --- | --- |
| `FireworksView` | Emits colorful bursts that are triggered by random timers or an audio-level spike. | `audioLevel`, `particlesPerFirework`, `gravity`, `launchIntervalRange`, `audioThreshold` |
| `LaserFanView` | A club-style fan of moving beams with animated colors and pulse-driven intensity. | `audioLevel`, `beamCount`, `speed`, `hueSpeed` |
| `WaveEffectView` | Expanding concentric circles that brighten and blur as audio grows louder. | `audioLevel`, `numberOfWaves`, `hueSpeed` |
| `SpotlightOverlay` | Figure-eight spotlights that sweep the screen using configurable colors. | `colors` |

All effects ignore safe areas and are optimized for rendering over a full-screen background (e.g., camera feed, metal layer, or a static gradient).

## Basic Usage
Below is a composited example that shows how to layer multiple effects and feed them an audio level (0.0–1.0) coming from your DSP pipeline.

```swift
import SwiftUI
import EasyVJEffects

struct VisualizerView: View {
  @State private var liveAudioLevel: Float = 0.0
  let audioMeter: AudioMeter // Replace with your own audio source

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()
      WaveEffectView(audioLevel: liveAudioLevel)
      SpotlightOverlay()
      FireworksView(
        audioLevel: liveAudioLevel,
        particlesPerFirework: 120,
        gravity: 260,
        audioThreshold: 0.04
      )
      LaserFanView(audioLevel: liveAudioLevel)
    }
    .task {
      for await level in audioMeter.levels {
        liveAudioLevel = level
      }
    }
  }
}
```

## Tips
- Normalize any incoming audio values to the expected `0.0...1.0` range for more predictable visuals.
- Because the effects run inside `TimelineView`, they automatically animate at the system’s animation cadence; prefer batching state updates to avoid extra work on the main thread.
- The views are composable—stack multiple overlays in a `ZStack` and adjust parameters to build richer mixes.
