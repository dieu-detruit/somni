# Current audio: implementation and evidence

Reviewed 2026-11-03. Source: `app/Shared/AudioSignal.swift`. This audit documents the existing stimulus; it does not change playback.

## What is actually played

The ambience is synthesized, not an ocean recording. A deterministic pseudo-random sequence is passed through a first-order low-pass filter:

```
y[n] = 0.985 y[n-1] + 0.015 white[n]
ambience[n] = 3.5 y[n] (0.6 + 0.4 sin(2π · 0.07 · t))
```

The amplitude envelope repeats every approximately 14.29 seconds and ranges from 0.2 to 1.0 before the other gains. This produces a slow swell resembling waves. It is neither a calibrated pink-noise generator nor a physical ocean model. Its fixed filter coefficient makes the spectrum sample-rate dependent. The one-pole cutoff is approximately 106 Hz at 44.1 kHz and 115 Hz at 48 kHz; these are analytical approximations, not bedside acoustic measurements.

With beat mode enabled, an additional signal is mixed in:

```
beat(t) = 0.13 (sin(2π · 180 · t) + sin(2π · 184 · t))
```

The two tones physically mix into a monaural beat with four audible envelope peaks per second. Both terms go to the same mono output; this is not binaural stimulation. Slow wave-like swelling and faster tonal beating are distinct candidate sources of a perceived pulsing sound. Without identifying the enabled preset and pulse timing, a listener's description alone does not identify which component they noticed.

The final signal also has app volume, a common factor of 0.5, a 3-second onset fade, a final 10-second timer fade, a manual 2-second fade and a ±0.22 digital peak limit. Beat on/off uses a 250-ms smoothing time constant. Actual perceived level additionally depends on system volume, output hardware and placement. Peak limiting does not establish a safe or effective acoustic dose.

## Why these parameters exist

The initial choices of wave-like timbre, 0.07-Hz swell, 180/184-Hz carriers and relative gains were engineering defaults. They were not selected from a validated sleep/recovery protocol. The 4-Hz difference has a broad low-frequency-beat rationale, but that is not evidence for this particular stimulus. A matching EEG-band name does not demonstrate entrainment, deep sleep enhancement or improved morning restfulness.

No reviewed study directly validates this exact waveform, spectrum, modulation depth, mix or speaker delivery. Do not cite general music research as validation of this synthesized ambience, or binaural research as validation of its monaural tones.

## Relevant comparisons in the literature

- [Ocean sound versus earplugs/eye mask in ICU patients, N=68](https://pubmed.ncbi.nlm.nih.gov/33425385/): subjective sleep outcomes favored the earplug/mask intervention over ocean sound. Abstract reviewed. Different population, setting, delivery and comparator; not validation of this synthetic waveform.
- [Ambient sounds in disturbed sleepers, N=28](https://pubmed.ncbi.nlm.nih.gov/20043248/): double-blind counterbalanced exposure; subjective awakenings improved, objective responses differed and volume explained sound differences. No psychomotor-performance difference. Abstract reviewed. Sound choice, level and exposure order are potential confounds.
- [Broadband sound in transient insomnia, N=18](https://pubmed.ncbi.nlm.nih.gov/29312136/): randomized crossover with bedtime advanced 90 minutes; N2 latency shortened under surrounding broadband sound. Abstract reviewed. This is an encouraging context-specific result, not evidence for ocean-like modulation or this app's level.
- [USleep app-audio trial, 2026, N=495](https://pubmed.ncbi.nlm.nih.gov/42223503/): four-week multi-arm randomized trial; Sleep Sounds versus digital control had a small nonsignificant effect on sleep disturbance (g=.14, 95% CI −.11 to .39). Abstract reviewed. Average null results do not rule out a reproducible individual preference/benefit, but they argue against assuming audio efficacy.
- For monaural and binaural findings and their limitations, see B1–B3 in the [evidence review](evidence-review.md).

## Parameters worth separating in personal experiments

Possible comparisons include ambience with/without its slow swell and matched sound with beats on/off. These are optional diagnostic comparisons, not a required order. Comfort-led exploration may instead begin with variations of a preferred beat-containing reference and a separately adjustable background level. These answer different questions. Equal peak settings do not guarantee equal perceived loudness; document loudness matching and its limitations. Keep timer and device placement stable. Only later compare different carriers, beat rates, spectra or duration, one contrast at a time.

Component preview/solo, independently switchable swell and tone layers, a sample-rate-independent filter, preset versioning and actual exposure logs would make future experiments interpretable. These are proposed changes, not current controls. Preserve the current preset as a versioned reference rather than silently changing the stimulus between nights.
