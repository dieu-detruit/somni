# Verification

## Version 0.2.0 (1002.1)

Verified 2026-11-04 (Asia/Tokyo), app source `296a948`.

- 24 shared behavior tests passed on macOS: legacy record/settings migration with nonempty fixtures, audio-layer isolation and limits, journal validation, timestamp precision, CSV escaping, DST range boundaries and sample deduplication.
- iPhone and embedded Watch Release archives built successfully; bundle IDs, companion relationship and version matching checked.
- Final scoped review confirmed export serialization/file generation runs off the main actor with generation-specific cancellation and cleanup.
- [Build verification](https://github.com/dieu-detruit/somni/actions/runs/41664966583).
- [Signed distribution](https://github.com/dieu-detruit/somni/actions/runs/41664965998): Apple reported VALID, exempt-only encryption accepted, IN_BETA_TESTING. Internal group automatic distribution enabled.

Device validation is still needed for actual loudness, overnight battery/playback, HealthKit data availability and the destination-specific share-sheet/file-copy experience. Automated tests and archive validation do not establish sleep efficacy or device UI behavior.
