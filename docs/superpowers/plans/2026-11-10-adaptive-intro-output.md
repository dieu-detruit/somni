# Adaptive Intro Output Implementation Plan

**Goal:** Allow the existing 14-Hz introduction on speakers as well as headphones, with automatic routing and manual overrides, then distribute through TestFlight.

**Authorization:** User approved automatic/binaural/monaural selection and requested immediate implementation and distribution without more design questions.

**Architecture:** Add IntroMode (automatic/binaural/monaural) to saved preferences and IntroDelivery (binaural/monaural) to playback provenance. Resolve after audio-session activation using output transport, channel count and system Mono Audio setting. Record the generated method independently of the preference. Legacy audio-version-3 intro sessions remain identified as binaural. New preferences default to automatic.

**Signal:** Keep left165/right179 Hz for binaural. For monaural, send the average of both tones to both channels, keeping the peak at or below the binaural peak. Keep 720-second intro, 30-second transition, master gain, current baseline layers and total-session timer. Selection is fixed during a playback. Route/Mono Audio changes stop playback; restarting resolves the new environment. Bluetooth/USB transport is an inference, with a manual override for speakers or unusual devices.

**Tasks:**

1. Observe a failing regression for dropped preference/provenance fields on existing macOS CI.
2. Add core routing policy, backward-compatible Codable fields, stereo/mono DSP, CSV provenance and regression tests for routing matrix, mono spectrum/equality, transitions, bounds and migration.
3. Remove headphone playback rejection. Add the three-way selector and generated-method status. Preserve interruption/route-stop behavior and persistence failure cleanup.
4. Review, run complete shared suite plus signed iOS/Watch archive, publish to TestFlight and verify Apple VALID/internal distribution. Merge into main and document results.

**Research side task:** Investigate 852 Hz as a carrier/pitch, separately from beat rate. No unapproved change to the nightly sound defaults follows from interest alone.

**Verification environment:** This Linux host has no Swift/Xcode. GitHub macOS CI runs executable tests and archives. Preserve existing 50 tests; add direct crossfade boundary checks in the new mono tests.
