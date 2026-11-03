# Journal and export implementation plan

> Agentic workers: use subagent-driven-development; existing delegation permits routine implementation choices.

Goal: enable comfortable audio exploration, daily sleep-context records and user-initiated analysis export.
Architecture: extend shared Codable models/DSP/export helpers; transactional iPhone store; separate SwiftUI journal/export views; maintain Watch compatibility.
Spec: docs/superpowers/specs/2026-11-04-journal-and-export.md

## Tasks
1. Write shared regression tests, then extend backward-compatible SoundSettings and AudioSignal. Expose layer gains and exploratory rates in TonightView.
2. Add validated point/interval journal models and CRUD persistence/UI; preserve old stored JSON, edits, deletions and failures.
3. Implement versioned analysis JSON/CSV export and date-range HealthKit retrieval, share UI and cleanup. Include raw available sleep samples, not only stage totals.
4. Review privacy/data loss/migration/DSP changes, fix findings, run Mac tests + iOS/watchOS archive, then distribute through this repository's TestFlight workflow.

## Review focus
- Old settings/records survive migration without silent reset or sound change.
- Daytime/midnight intervals retain accurate timestamps and provenance.
- Export includes independent audio parameters and actual coverage; missing health data is not zero.
- Share is explicit; no personal data in repository or logs.
- Background changes preserve fade/timer/interrupt handling and Watch decoding.
