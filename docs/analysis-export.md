# Analysis export

The app exports data only when the user requests it and chooses a destination in the iOS share sheet. There is no automatic upload to an analysis service.

## Sharing a dataset

Use the export screen, select the calendar-date range for a fresh Apple Health sleep query, generate the files, and share/save them. The JSON file is the canonical dataset. Attach it to an analysis conversation; the CSV tables are optional conveniences for spreadsheets.

The date range controls the fresh HealthKit query. Local playback, ratings, journal events and previously imported sleep summaries are included in full, as described before sharing. The export contains health data and free-text notes. Review the scope and share only with an intended recipient.

## Data interpretation

- `playbackSessions` preserves sessions, actual known played duration, end reason and timestamped settings changes. Master volume, ambience gain, beat gain, rate and audio version are distinct fields.
- `morningFeedback` contains self-reported morning outcomes. It is not an objective recovery measurement.
- `journalEvents` contains manually entered sleepiness, bedtime, nap and morning return-to-sleep events. Event time and creation/edit time differ; retrospective entry is allowed. These do not assert sleep-stage measurements.
- `healthSleepSamples` contains available HealthKit sleep intervals from the requested full-day range, including daytime periods when present. Sources remain separate. Do not add overlapping intervals from multiple sources as if they were independent sleep time.
- `cachedSleepRecords` contains the earlier imported summaries and their selected sources/fetch times. These may overlap the fresh query and must not be counted twice.
- `healthCoverage` records query scope/status and limitations. Query success means the query completed, not that permission or full physiological coverage was confirmed. Missing samples are not zero sleep.
- Metadata includes export/schema/app/audio versions and timezone information. Canonical timestamps use ISO 8601; use timezone metadata to reconstruct local dates and handle midnight boundaries.

CSV is a convenience view: quotes and multiline notes need proper parsing, and formula-like text may be escaped for spreadsheet safety. Use JSON when exact original text matters. Digital gains do not establish bedside acoustic dBA, and device volume/placement should not be inferred when absent.

## Suggested analysis request

“Summarize the available dates and missingness first. Plot audio exposure/settings, self-reported events and sleep intervals on a common local-time axis. Keep self-report separate from HealthKit estimates. Compare morning restfulness and daytime sleepiness across the actual audio settings, showing individual nights and deviations. Describe associations and uncertainty; do not claim causation from this convenience sample.”

Avoid reconstructing fine-grained audio settings from only a session's final value: apply its timestamped setting changes. An unknown session end or partial log remains uncertain. A daytime nap and a morning return-to-sleep interval should retain their explicit labels rather than being automatically combined into the prior night's main sleep.

## Export boundaries

HealthKit records are available observations, not Apple's proprietary internal classification inputs or an exact reproduction of every official graph. The export can support a sleep-stage timeline from the records it contains. It does not expose live sleep-stage feedback or a physiological controller.

No personal export or example containing real health data belongs in the public repository. Use synthetic fixtures for tests.
