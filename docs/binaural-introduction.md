# Optional binaural introduction

Somnio 0.3.0, audio version 3, adds an optional introduction to a playback session. It is off by default and does not replace saved sound preferences.

Enable **最初の12分に14 Hzを試す** on the Tonight screen before playback. Use stereo headphones in both ears, with system Mono Audio off. The introduction sends 165 Hz to the left ear and 179 Hz to the right ear for 720 seconds, then crossfades linearly over 30 seconds into the selected existing sound and layer settings. Master volume applies throughout. The existing timer counts from playback start, including the introduction; shorter timers can end before transition. Stopping or interruption still ends playback. Removing or changing the audio route stops playback rather than switching unexpectedly to the phone speaker. Resume by starting a new session, which begins the introduction again.

The app blocks introduction playback on the built-in speaker. Bluetooth and USB routes cannot reliably identify headphones or guarantee separated ear delivery; the user must check the actual output, stereo accessibility settings and headphone placement. After the transition, playback remains on the same output route. It does not automatically move to the speaker.

The introduction is fixed for the current playback. Its toggle is disabled during playback; master volume and the subsequent sound/layer settings remain adjustable. Layer volume controls apply to the sound after the introduction, not to the separate introductory tone. Settings and session exports include `binauralIntro`; older records decode as false. Audio version 3 defines the deterministic transition schedule, so its delivered duration can be interpreted using each session's played seconds and ending reason. No Watch-triggered timing or sleep-onset detection is used.

## Experimental rationale

The hypothesis is that a brief waking introduction before ordinary bedtime audio may reduce carry-over cognitive fatigue. The [mental-fatigue literature inventory](research/mental-fatigue-audio-candidates.md) records the 14-Hz, 12-minute waking post-task study that informed the parameters. This combined bedtime sequence, generated pure tones without the study's composed track, and next-morning recovery have not been validated by that study. The 30-second crossfade is an engineering choice. The 15-Hz candidate remains research only in this release.
