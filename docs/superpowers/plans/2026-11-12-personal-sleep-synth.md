# Personal Sleep Synthesizer Implementation Plan

**Goal:** Make comfortable sound creation the main app experience: independently mix generated ambient music, a pure tone/physical beat and existing wave-like noise; save favorites; optionally add the existing timed 14-Hz introduction; distribute through TestFlight.

**Authorization:** User approved the proposed direction and requested implementation. Existing delegation covers implementation choices and distribution without further design questions.

**Architecture:** Extend backward-compatible SoundSettings with music gain/timbre/brightness/motion, tone frequency and introductory gain. Keep existing baseline defaults, interruption handling, HealthKit and Watch behavior. Add a deterministic polyphonic ambient music generator with slow chord transitions and continuous oscillator phase; no copyrighted recordings, vocals or network dependencies. Music remains audible during the optional introduction. Tone beat rate zero produces a pure tone. Favorites store full normalized settings in the existing lightweight user-record file and appear in JSON/CSV exports.

**Controls:** Music and environment each have an independent enable/gain control; tone uses existing mode and gain, with 80–1000-Hz carrier (including 852) and 0–40-Hz beat rate. Music timbres: warmPad and softKeys, brightness/motion 0–1. All realtime gain/frequency/timbre changes are smoothed. Intro mode stays fixed per session; its level is adjustable. Starter patches include music alone, music plus a gentle beat, music with the 14-Hz introduction, 852-Hz pure tone and original baseline. These are sound suggestions, not proven treatments. Preset application is disabled during playback to avoid changing fixed control state; individual sound controls remain live.

**Tasks:**

1. Reproduce dropped new sound controls with a regression on existing macOS CI.
2. Implement models, music DSP, independent mixing and persistence/export of favorites. Test legacy decoding, finite bounds, waveform spectrum, mute isolation, mixed intro, transitions, continuous changes, favorite disk round trips and export provenance.
3. Replace the experiment-first sound screen with visible layer cards, quick presets/favorites and an optional control section. Keep playback and morning/daytime records.
4. Independently review; run full Swift tests and signed iOS/Watch archive; verify Apple VALID/internal TestFlight distribution; merge and document.

**Review focus:** Preserved user settings and historical decoding; no clipping/discontinuity at control changes; music audible with intro and all tone controls independent; favorites survive restart/delete/export; no hidden preset changes while playing. Local Linux has no Swift/Xcode, so macOS CI supplies executable verification. Device listening remains necessary for comfort and real sound level; automated tests do not validate recovery.

## Execution record

- Initial regression reproduced discarded settings on macOS and in the official Swift 6.0 Linux container: 57 tests, four expected missing-field assertions; pre-existing tests passed.
- Implementation passed all 63 shared tests on Linux and macOS. The official container was introduced after macOS queue delay; it mounts source read-only with build output inside the disposable container.
- Independent source review found no critical/important defects. Its minor legacy sound-label issue was corrected using settings-derived descriptions in history, Watch summaries and lock-screen metadata, plus updated help text.
- Actual production DSP generated 45-second WAV previews for warm pad, soft keys and music with a gentle beat. These support listening review; no automated result establishes pleasantness or efficacy.
- Release run 43195298116: all 63 shared tests and signed iOS/Watch archive passed; Apple confirmed VALID and IN_BETA_TESTING, Internal automatic distribution enabled. Binary source b6e6c5d, app 0.4.0 build 1008.1. Merged into main.
