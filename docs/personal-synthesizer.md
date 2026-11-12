# Personal sleep synthesizer

Somnio 0.4.0 makes comfortable sound creation the main experience. Its three sound layers are independently adjustable, with an optional timed controller on top. Morning feedback, sleep history and exports remain available.

## Sound layers

- **Ambient music:** original, generated polyphonic music with four slowly changing chords, overlapping transitions and modest stereo spread. Choose a warm pad or soft synthesized keys, then adjust level, brightness and movement. These are synthesized instruments, not recordings or sampled piano. A chord takes 24–48 seconds depending on movement, with a smooth transition during its final third. Music pauses its internal progression while effectively muted and fades in when enabled again.
- **Pure tone / physical beat:** choose an 80–1000-Hz base tone, including an 852-Hz shortcut. Beat rate 0 produces a single tone; 0.5–40 Hz adds a second tone at base frequency plus beat rate. This ordinary layer sends the same sound to both channels, so it works through speakers. Carrier pitch and beat rate are distinct controls. Gain, frequency and pure/beat transitions are smoothed.
- **Wave-like environment:** the existing synthesized, slowly swelling filtered noise with independent gain. It is not an ocean recording.

All layers share master volume and the existing total-session timer/fades. The final digital peak remains limited to ±0.22. This is not acoustic exposure calibration; hardware volume and output placement are not recorded. Musical preferences and tolerability need listening on the actual device.

## Starting and saving

The bottom transport remains accessible while adjusting sounds. Changes apply during playback. Existing installations keep their saved sound settings; generated music defaults to off so an update does not replace a familiar sound.

Starter recipes provide music alone, music with a quiet physical beat, music with the 14-Hz introduction, an 852-Hz pure tone, and the original noise/beat balance. Recipe application replaces the whole sound setting, including master volume and timer, and is available while stopped. Recipes are starting points, not efficacy rankings. Sound controls remain live during playback.

Save the current full setting with a name to create a favorite. Favorites remain on the device, can be applied while stopped or deleted, and are included in analysis exports. Up to 50 favorites are retained; saving never silently replaces an older favorite. Deleting all app records also removes favorites. A blank name becomes a generic favorite name.

## Optional control

The timed 14-Hz introduction remains available under the time-control section. It uses fixed 165/179-Hz tones for 720 seconds followed by a 30-second transition, with automatic/binaural/monaural delivery and independently adjustable introductory level. **Music remains audible throughout**. The ordinary noise/tone layers fade in as the introduction ends, preserving their prior transition behavior. Intro enablement and delivery preference stay fixed during playback; introductory level is live.

The research-derived numbers inform a hypothesis, not a validated reproduction: the published composed track is not used here. The generated music, mix and bedtime schedule are different stimuli. No EEG-phase synchronization or Watch-driven live sleep control is implemented. See [introduction delivery](binaural-introduction.md) and [mental-fatigue candidates](research/mental-fatigue-audio-candidates.md).

## Recording and compatibility

Audio version 5 adds `musicGain`, `musicTimbre`, `musicBrightness`, `musicMotion`, `toneFrequencyHz`, and `introGain` to settings and timestamped playback changes. Old records decode with music off, 180-Hz base pitch and introductory level 1. Existing noise, 4-Hz beat, fixed intro, timing and reset behavior remain available.

JSON exports include `soundPresets`; `sound_presets.csv` contains favorite settings and `setting_changes.csv` contains all synthesizer controls. Favorites describe saved choices, not playback exposure. Use actual playback records for comparisons. Delivery provenance continues to describe generated channels rather than measured sound at each ear.

## Research posture

Comfort and exploration are primary interactions; next-morning cognitive restfulness remains the intended outcome. The app makes no claim that a selected Hz, chord, timbre or saved recipe reliably restores brain function. 852 Hz is offered as a selectable pitch, with its [evidence review](research/852-hz.md) kept separate from the interface. Sound preference is a valid reason to explore an option without calling it a proven intervention.
