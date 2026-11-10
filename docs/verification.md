# Verification

## Version 0.3.1 (1006.1)

Verified 2026-11-10 (Asia/Tokyo), binary source `5f8891f`.

- All 56 shared tests passed, including automatic/manual routing, Mono Audio/channel-count fallback, independent requested/generated provenance, v3-history migration, monaural spectrum/channel equality, direct transition-boundary samples, exact baseline return and timer/manual stop.
- Signed iPhone archive with embedded Watch companion passed archive validation.
- [Distribution run](https://github.com/dieu-detruit/somni/actions/runs/42762726048): Apple reported VALID and IN_BETA_TESTING; Internal automatic distribution enabled.
- Independent source review found no critical/important defects. Preference/provenance loss was reproduced by the initial regression before implementation.
- Actual device routing, headphone separation, perceived loudness and overnight outcome remain device-validation items. Bluetooth/USB inference is explicitly overridable; generated delivery is not a measurement of two-ear exposure.

## Version 0.3.0 (1005.1)

Verified 2026-11-07 (Asia/Tokyo), binary source `786a2ab`.

- All 50 shared tests passed on macOS, including independent left/right intro frequencies, exact return to baseline after 750 seconds, timer/manual-stop behavior, settings migration and JSON/CSV experiment provenance.
- Signed iPhone archive with embedded Watch companion passed archive validation.
- [Distribution run](https://github.com/dieu-detruit/somni/actions/runs/42368016945): Apple reported VALID and IN_BETA_TESTING; Internal automatic distribution enabled.
- Independent source review led to CSV experiment-field and activated-route validation fixes. Intro persistence and CSV regressions were observed failing before their fixes.
- Device-level headphone separation, actual loudness, route transitions and subjective next-morning effects remain unverified. Exact crossfade-start amplitude assertions are a test coverage follow-up.

## Version 0.2.1 (1003.1)

Verified 2026-11-05 (Asia/Tokyo), source `4a86afe`.

- 43 shared tests passed, including incremental sleep merge/deletion, all-night indexing, source selection, migration, reset/in-flight generation checks and seven split-file persistence failure/recovery tests.
- iPhone and embedded Watch signed archives passed bundle/companion/version checks.
- [Distribution run](https://github.com/dieu-detruit/somni/actions/runs/41873722664): VALID, IN_BETA_TESTING; Internal automatic distribution enabled.
- Review resolved full-history writes on ordinary edits by separating bulk sleep persistence from lightweight user records.
- Actual HealthKit delivery/foreground behavior still requires confirmation on paired devices; no terminated-app background-delivery guarantee is made.

## Version 0.2.0 (1002.1)

Verified 2026-11-04 (Asia/Tokyo), app source `296a948`.

- 24 shared behavior tests passed on macOS: legacy record/settings migration with nonempty fixtures, audio-layer isolation and limits, journal validation, timestamp precision, CSV escaping, DST range boundaries and sample deduplication.
- iPhone and embedded Watch Release archives built successfully; bundle IDs, companion relationship and version matching checked.
- Final scoped review confirmed export serialization/file generation runs off the main actor with generation-specific cancellation and cleanup.
- [Build verification](https://github.com/dieu-detruit/somni/actions/runs/41664966583).
- [Signed distribution](https://github.com/dieu-detruit/somni/actions/runs/41664965998): Apple reported VALID, exempt-only encryption accepted, IN_BETA_TESTING. Internal group automatic distribution enabled.

Device validation is still needed for actual loudness, overnight battery/playback, HealthKit data availability and the destination-specific share-sheet/file-copy experience. Automated tests and archive validation do not establish sleep efficacy or device UI behavior.
