# Current architecture

Somnio consists of an iOS 17+ SwiftUI app, a watchOS 10+ companion, and a shared Foundation package.

- iPhone generates ambient sound and optional monaural beats through AVFoundation. Timers and fades follow rendered audio samples; interruptions and route changes stop playback.
- Local records contain presets, playback sessions/settings changes, morning restfulness and ease-of-sleep ratings, notes, and imported sleep summaries.
- HealthKit sleep records are read retrospectively, with sources kept separate and Apple Watch preferred. Sleep duration merges overlapping asleep intervals and excludes in-bed-only time. The selected overnight window is 18:00–12:00; this is an app convention, not a universal definition of a night.
- WatchConnectivity transfers summaries and durable morning-feedback events. The Watch app does not independently classify sleep or run an all-night sensor session.
- The app does not yet randomize conditions or estimate causal audio effects. Interrupted sessions and missing data need to remain visible during personal experiments.
- GitHub Actions in this repository runs validation and TestFlight distribution. Signing credentials are repository secrets. No deployment credentials belong in documentation or source files.

The development research priority is morning restfulness rather than maximizing an estimated sleep stage. See the [experiment roadmap](research/experiment-roadmap.md).
