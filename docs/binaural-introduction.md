# Optional 14-Hz introduction

Somnio 0.3.1, audio version 4, supports an optional introduction for headphones and speakers. It is off by default and does not replace saved sound preferences.

Enable **最初の12分に14 Hzを試す** on the Tonight screen before playback, then choose **自動**, **バイノーラル**, or **モノラル**. Binaural sends 165 Hz left and 179 Hz right. Monaural sends the average of both tones equally to both channels, producing a physical 14-Hz beat with a bounded peak. Mono and binaural have different perceived loudness; equal peak limits do not establish equal acoustic exposure.

Automatic resolves after audio-session activation: headphone/Bluetooth/USB transports with at least two output channels are treated as likely headphones and use binaural. Built-in speakers and other routes use monaural. Bluetooth and USB transport cannot certify headphones: choose monaural for speakers or single-ear listening, or manually choose binaural for a stereo headset the automatic policy does not recognize. System Mono Audio or fewer than two output channels always selects monaural. The generated method is displayed during playback; it does not prove delivery to separate ears.

The introduction lasts 720 seconds, then crossfades linearly over 30 seconds into the selected sound/layer settings. Master volume applies throughout; layer sliders apply after the introduction. The timer includes the introduction and can truncate it. Intro enable/mode controls are fixed during playback. Stop, interruption, audio-route changes, or system Mono Audio changes stop playback. Starting again re-evaluates output and begins a new introduction, rather than silently moving sound to another device. After transition, playback stays on the same route.

Settings/session JSON and CSV preserve `binauralIntro` and requested `introMode`; sessions separately record generated `introDelivery`. Preference defaults to automatic when absent. Historical audio-version-3 intro sessions are known binaural and decode accordingly. Missing delivery for other versions remains unknown; null also applies when the intro was disabled. Audio versions 3 and 4 define the same deterministic transition schedule, with version 4 adding monaural generation. No Watch-triggered timing or sleep-onset detection is used.

## Experimental rationale

The hypothesis is that a brief waking introduction before ordinary bedtime audio may reduce carry-over cognitive fatigue. The [mental-fatigue literature inventory](research/mental-fatigue-audio-candidates.md) records the 14-Hz, 12-minute waking post-task study that informed the parameters. This combined bedtime sequence, generated pure tones without the study's composed track, monaural adaptation, and next-morning recovery have not been validated by that study. The 30-second crossfade is an engineering choice. The 15-Hz and [852-Hz](research/852-hz.md) candidates remain research only in this release.
