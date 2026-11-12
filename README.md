# Somnio

A personal sleep synthesizer for iPhone, with a morning journal and sleep records from Apple Watch. Mix sounds that feel comfortable, save your favorites, and explore how they relate to feeling more rested the next morning.

## Features

- Mix generated ambient music, pure tones or monaural beats, and wave-like environmental noise independently.
- Shape musical timbre, brightness and chord movement; adjust tone pitch separately from beat rate, including an 852-Hz pure-tone starting point.
- Save and delete favorite sound recipes on your device, and adjust sounds while playing with an always-accessible transport.
- Optionally start with a 12-minute, 14-Hz introduction for headphones or speakers, with automatic/binaural/monaural selection, then return to the selected sound. See [the experimental protocol](docs/binaural-introduction.md).
- Adjust ambience and beat levels independently, explore beat rates, and set a sleep timer with a gentle fade-out.
- Record morning restfulness, ease of falling asleep, and notes.
- Record sleepiness, bedtime, naps, and morning return-to-sleep intervals.
- Automatically catch up on readable Apple Health sleep history when the app opens, and review it alongside playback history.
- Export timestamped JSON and CSV files for personal analysis through the iOS share sheet.
- Record restfulness on Apple Watch and sync it to iPhone.
- Keep records on your devices, without an account or analytics service.

See [the personal synthesizer](docs/personal-synthesizer.md) for controls, starting recipes, timing, recording and compatibility.

Audio research has mixed results. Somnio supports personal experimentation and reflection; it does not promise improved sleep or provide medical diagnosis or treatment. Apple Watch sleep stages are estimates.

## Requirements

- iOS 17 or later
- watchOS 10 or later for the companion app
- Xcode 26.3 and XcodeGen for development

Enable Apple's sleep tracking on Apple Watch to include sleep records. Connect sleep data in Somnio and grant read access when prompted. Subsequent app openings catch up automatically; selecting a night only changes the displayed summary. See [sleep synchronization](docs/sleep-synchronization.md) for recovery and permission details.

## Development

```sh
brew install xcodegen
swift test
xcodegen generate
open Somnio.xcodeproj
```

Select the `Somnio` scheme and configure your signing team before installing on a device.

```sh
bash scripts/check.sh
```

This runs the shared tests, creates an unsigned iOS archive, and checks the embedded Watch app's identifiers and versions. Audio interruptions, overnight playback, HealthKit synchronization, and Watch connectivity also require device testing.

## TestFlight

The `Somnio TestFlight` GitHub Actions workflow builds, signs, uploads, and checks Apple's processing status. Run it manually from the Actions tab or push a `somnio-testflight-*` tag.

Configure these **repository secrets** under **Settings → Secrets and variables → Actions**:

| Secret | Value |
| --- | --- |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID for your App Store Connect team API key. |
| `APP_STORE_CONNECT_KEY_IDENTIFIER` | Key ID for that API key. |
| `APP_STORE_CONNECT_PRIVATE_KEY` | Complete contents of the API key's `.p8` file, including PEM headers and line breaks. |
| `CERTIFICATE_PRIVATE_KEY` | PEM private key matching the Apple Distribution signing certificate. This is separate from the API key's `.p8` file. |

The API key needs permission to manage signing assets and upload builds. Keep private keys in GitHub Secrets; never commit them.

Repository variable `APPLE_TEAM_ID` is set to `XLVLA9AY6A`. Bundle identifiers are configured as:

- iPhone: `com.takafumi.somni`
- Apple Watch: `com.takafumi.somni.watchkit`

Create the corresponding App Store Connect app and enable automatic distribution for your internal TestFlight group. The workflow fetches signing profiles and enables HealthKit on the iPhone App ID. Build numbers use `1000 + GitHub run number`, followed by the run attempt; they must exceed previously uploaded build numbers.

## Research

See the [evidence review](docs/research/evidence-review.md) for study-level findings and limitations, and the [experiment roadmap](docs/research/experiment-roadmap.md) for prioritized hypotheses and proposed personal comparisons. These are research proposals, not implemented features or efficacy claims.

See [analysis export](docs/analysis-export.md) for data scope and interpretation.

The [documentation index](docs/README.md) also describes the current architecture.
