# Sleep synchronization

Somnio imports readable Apple Health sleep records without requiring a particular night to be selected.

## Behavior

After the initial sleep-reading request, opening or foregrounding the app catches up on sleep records. Changes observed while the app is running also trigger catch-up. Initial import covers readable history without an arbitrary date cutoff; later imports use a HealthKit query anchor to retrieve added and deleted objects. This is retrospective data synchronization, not live sleep-stage feedback.

Manual full refresh remains available as recovery, particularly after changing Health permissions. Night selection changes which summary is displayed; it is not the scope of automatic import. Night labels identify both the evening and the following morning. Imported daytime and morning sleep intervals retain their raw timestamps even when an overnight summary uses a narrower window.

Apple's privacy model does not let the app determine whether sleep-reading access was denied. An empty query can mean hidden permission, unavailable/unsynced records, or genuinely no matching data. Completing an authorization request does not prove permission was granted. Permission can be reviewed in the Health app under the profile's apps/services section.

## Reliability

The query anchor and raw records are saved together in a bulk sleep file. Ordinary settings, ratings and journal edits save only a lightweight user-record file. Migration writes recoverable bulk data before replacing the legacy combined file; an authoritative generation marker prevents stale bulk data from returning after a reset. A failed local save must not advance the anchor. Additions replace matching sample IDs, deletions remove them, and affected night summaries are rebuilt while retaining valid source selections. Samples from different sources are not silently summed together. Existing playback, ratings, journal entries and historical caches remain backward compatible.

Deleting all Somnio data clears imported records and the synchronization position, and pauses automatic import until the user explicitly reconnects. Apple Health originals are unchanged.

Foreground catch-up does not guarantee immediate delivery while the app is suspended or terminated. Watch-to-iPhone synchronization and HealthKit publication can be delayed. A missing interval must not be displayed as confirmed wakefulness or zero sleep.

## References

- [HKAnchoredObjectQuery](https://developer.apple.com/documentation/healthkit/hkanchoredobjectquery)
- [HKObserverQuery](https://developer.apple.com/documentation/healthkit/hkobserverquery)
- [Authorizing access to health data](https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data)
