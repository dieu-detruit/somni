# Binaural Intro Implementation Plan

**Goal:** Ship tonight's optional 12-minute 14-Hz binaural introduction followed by a 30-second crossfade to existing sound settings.

**Architecture:** Add a backward-compatible Boolean to SoundSettings and audio version 3. Render genuine independent stereo channels using left 165/right 179 Hz. Sample time drives the sequence, fades and existing total-session timer. The experiment selection is fixed for each playback; volume and subsequent sound settings remain adjustable.

**Tech Stack:** Existing SwiftUI, AVAudioEngine, SomnioCore and GitHub Actions/TestFlight pipeline.

**Authorization:** User requested immediate implementation and distribution, delegating tonight's choices and foregoing further design questions.

## Constraints and checks

- Default off for existing installations. Do not replace existing sound preferences.
- Require a headphone route before starting the experimental introduction; route removal retains existing stop behavior. UI explains stereo headphones and total timer.
- Preserve old decoding, baseline mono sound, manual stop and timer fades; no sleep-stage detection claims.
- Save intro selection in existing session settings/export; rendered transition times are deterministic from audio version 3 and elapsed playback.
- Test persistence migration, channel frequency/separation, intro/crossfade/baseline boundaries, bounded output, timer truncation and manual stop.

## Tasks

1. Write persistence regression first; run on existing macOS CI and observe failure because the intro flag is discarded.
2. Add settings, stereo DSP and meaningful waveform/timing regression tests. Add visible intro control, headphone gating and phase status.
3. Review code, run full Swift suite and signed archive in existing TestFlight workflow. Fix any failures, verify Apple processing and internal distribution before claiming delivery.

Local limitation: Swift/Xcode are unavailable on this Linux host; macOS GitHub Actions supplies executable verification.
