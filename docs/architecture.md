# Current architecture

Somnio consists of an iOS 17+ SwiftUI app, a watchOS 10+ companion, and a shared Foundation package.

- iPhone generates independent ambient music, wave-like noise, and pure-tone/monaural-beat layers through AVFoundation, with an optional timed binaural/monaural introduction. Timers and fades follow rendered audio samples; interruptions and route changes stop playback.
- Local records contain presets, playback sessions/settings changes, morning restfulness and ease-of-sleep ratings, notes, and imported sleep summaries.
- HealthKit sleep records are read retrospectively, with sources kept separate and Apple Watch preferred. Sleep duration merges overlapping asleep intervals and excludes in-bed-only time. The selected overnight window is 18:00–12:00; this is an app convention, not a universal definition of a night.
- WatchConnectivity transfers summaries and durable morning-feedback events. The Watch app does not independently classify sleep or run an all-night sensor session.
- The app does not yet randomize conditions or estimate causal audio effects. Interrupted sessions and missing data need to remain visible during personal experiments.
- GitHub Actions in this repository runs validation and TestFlight distribution. Signing credentials are repository secrets. No deployment credentials belong in documentation or source files.

The development research priority is morning restfulness rather than maximizing an estimated sleep stage. See the [experiment roadmap](research/experiment-roadmap.md).

## Personal synthesizer

The sound-design screen exposes independent layers and starter recipes, with saved favorites in the lightweight user-record file. Audio version 5 adds polyphonic generated music, timbre/brightness/movement controls, base pitch selection, rate-zero pure tones and adjustable intro gain. Music can continue beneath the timed introduction. Settings changes retain all sound controls for analysis; JSON and CSV also include favorites as saved preferences, separately from playback exposure. See [the personal synthesizer](personal-synthesizer.md).

## Version 0.2 additions

Independent ambience/beat gains and selectable beat rates retain legacy defaults when reading older settings. Timestamped self-reported journal events are stored separately from HealthKit sleep estimates. User-initiated [analysis export](analysis-export.md) includes the full local history plus a fresh full-day HealthKit query for selected calendar dates. JSON is authoritative; CSV is a convenience view. Serialization/file generation runs off the main actor, and generation-scoped temporary files are removed after sharing/cancellation or on a later launch.

## Automatic sleep synchronization

A lifecycle-owned HealthKit reader performs initial all-readable-history import and anchored incremental catch-up on foreground and updates observed while running. Raw samples, deletions and the query anchor commit together; local save failure preserves the prior anchor. See [synchronization](sleep-synchronization.md) for permission, reset and foreground limits. Export schema 2 distinguishes synced raw intervals, current nightly summaries, and retained legacy caches.
