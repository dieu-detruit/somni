# Audio methods and a system-identification model

Status: research and design proposal, not implemented behavior. Reviewed 2026-11-03. Scope: audio-only, single-participant reproducibility. Distinguish carrier pitch, beat/pulse rate, slow amplitude envelope, and controller update period: all are sometimes called “frequency,” but they are different inputs.

## Literature methods to investigate

Access below is abstract-level unless stated otherwise. Exact stimulation hardware, calibration, randomization and full protocol need verification before replication. This is a targeted method inventory, not an exhaustive review.

| Method/source | Input and timing | Measured result | Transfer to current app |
| --- | --- | --- | --- |
| [Ocean sound ICU trial, 2020](https://pubmed.ncbi.nlm.nih.gov/33425385/) | Ocean sound compared with earplugs/eye mask in 68 ICU patients; four nights, subjective ratings | Earplugs/mask performed better | Neither an optimal wave envelope nor this synthesized waveform was tested |
| [Broadband sound, Messineo 2017](https://pubmed.ncbi.nlm.nih.gov/29312136/) | Two-speaker surrounding broadband noise; 18 healthy participants, crossover; bedtime advanced 90 minutes; approximately 46 versus 40 dB conditions | N2 latency shortened; selected subjective findings | Candidate for a steady-noise comparison, not proof of benefit from the current 14-second swell. Do not map dB to app slider |
| [Fan 2024](https://pubmed.ncbi.nlm.nih.gov/39478090/), DOI 10.1038/s41598-024-76059-9 | Earphone binaural beats, 250-Hz carrier, sham/0/0.25/1 Hz, four 90-minute afternoon naps, N=12 | 0.25 Hz shortened N2/N3 latency versus sham; no significant slow-frequency entrainment result | A frequency lead for binaural delivery, not validation of 0.25-Hz monaural speaker playback or overnight recovery. Comparator matters: superiority versus sham does not establish superiority versus every active frequency |
| [Jirakittayakorn & Wongsawat 2018](https://pubmed.ncbi.nlm.nih.gov/30319382/), DOI 10.3389/fnhum.2018.00387 | 3-Hz binaural beat sleep-stage study | Candidate for detailed protocol extraction | Full method extraction pending; do not present it as a monaural-frequency recommendation |
| [Lee 2024](https://pubmed.ncbi.nlm.nih.gov/38629490/), DOI 10.1093/sleep/zsae097 | Dynamic binaural difference 0–3 Hz; one ear 100 Hz, the other 100–103 Hz; N=10, two-night crossover, PSG, stimulation around selected initiation/transition periods | Reduced sleep latency versus no-sound sham | Interesting sweep hypothesis; exact sweep law/period must be extracted before replication. Simultaneously changing delivery/carrier/rate would defeat attribution |
| [Bang 2019](https://pubmed.ncbi.nlm.nih.gov/31433343/) | Music with/without theta binaural beats, 30 minutes before sleep for two weeks, 43 completers | No significant incremental insomnia-severity improvement | Active comparator is essential; matching an EEG band name is insufficient |
| [Venkatesan 2025](https://www.frontiersin.org/journals/psychology/articles/10.3389/fpsyg.2025.1539823/full) | Monaural beats plus music / beats only / pure tone, N=308, 30 minutes; full-text limitations reviewed | Acute anxiety/mood outcomes; no sleep/recovery measurement; no music-only arm | Supports a relaxation hypothesis, not the current 4-Hz sleep prescription |
| [Ngo 2013, rhythmic stimulation](https://pubmed.ncbi.nlm.nih.gov/22913273/), DOI 10.1111/j.1365-2869.2012.01039.x | Repeated 0.8-Hz tones versus random/sham, beginning awake and continuing about 90 minutes into sleep | Delayed sleep onset, but enhanced slow oscillations once stable NREM was established | Strong reason to distinguish sleep-onset and established-sleep control. Not a reason to play 0.8-Hz pulses immediately at bedtime |
| [Schade 2020](https://pubmed.ncbi.nlm.nih.gov/32765139/), DOI 10.2147/NSS.S243204 | N=8, supervised live PSG scoring; non-phase-locked sound variants during NREM; counterbalanced enhancing/disruptive nights with sham | Higher N3 proportion under enhancing condition; momentary low-frequency power also rose with disruptive sounds; disruptive exposure impaired next-day vigilance | Relevant to stage-scale gating without precise EEG phase. Still required live PSG supervision; not a Watch-only validation or proof of morning benefit |
| [Diep 2021](https://pubmed.ncbi.nlm.nih.gov/33639484/) | N=25 short sleepers, two consecutive nights, device-driven phase/stage-gated short tones | Improved reported alertness and objective attention; heterogeneous response | Positive recovery-related lead, but its timing/hardware cannot be assumed available on Watch |
| [Yoon & Choi 2023](https://pubmed.ncbi.nlm.nih.gov/37514760/), DOI 10.3390/s23146468 | Continuously respiratory-adapted audio; six participants, nap with/without stimulation | Reported sleep-initiation interval 14.00 versus 9.67 minutes, with physiological differences | An audio-envelope feedback lead; tiny preliminary study, not efficacy confirmation. Spoken/breathing instructions remain out of scope; any passive envelope-only adaptation would be a distinct test |
| [Sardooeinasab 2026](https://pubmed.ncbi.nlm.nih.gov/41593748/), DOI 10.1093/sleep/zsag017 | Analysis of PSG in 133 adolescents, tones delivered randomly every 15–30 seconds; response compared by EEG and heart-rhythm phase | Certain heart-rhythm phases associated with stronger evoked oscillations | Timing association/analysis is not a prospective trial of a heart-only controller. ECG-derived rhythm phase is not sparse Watch HR or a morning stage graph |

A five-minute heart-rate-minus-3% example found in a review refers to **vibration**, not auditory beating. It must not be imported as an established acoustic control law. Continuous-noise adverse findings and music limitations remain in the [evidence review](evidence-review.md).

## Tonight: a useful choice without changing several things

The current released app exposes two modes: swelling ambience, and the same ambience plus a fixed 4-Hz monaural beat. It cannot independently disable the swell, select a new beat rate, or perform feedback control.

Recommended low-burden candidate: keep yesterday's ambience, timer, volume, placement and ordinary routine; change only beat on versus off. If preserving the apparently comfortable night is more important tonight, repeat the exact prior setting as a reference instead. One night either way is a pilot observation, not a causal result. Do not compare a changed wave envelope and changed beat frequency on the same night and attribute the outcome to frequency.

For a subsequent build, independently switchable swell and beat controls would allow: (A) steady filtered noise, (B) the same noise with the existing 0.07-Hz swell, then separate beat-rate comparisons. The 14.29-second envelope is a baseline engineering choice, not a paper-derived optimum. Preserve versioned existing presets; match perceived loudness as well as practicable and log differences.

There is no sufficiently established speaker-monaural optimal rate to recommend changing 4 Hz to 0.25/1/3 Hz tonight as an evidence-based improvement. These can become explicitly exploratory candidates with a matched delivery method and active controls. Avoid arbitrary sweeps until fixed-condition responses are interpretable.

For feedback tonight: normal retrospective Watch recording plus accurate audio/subjective logs. No implemented overnight controller is available. The following model guides future acquisition and experiments rather than silently introducing stimulation tonight.

## Proposed plant and I/O

Index night by n and a nominal decision block by k. A five-minute decision block is an initial engineering hypothesis matching the desired slow scale; it is not a proven physiological response time. The renderer runs at audio sample rate independently.

Input vector:

```
u[n,k] = (g_noise, g_tone, f_carrier, f_beat, f_swell, swell_depth, gate)
```

Include the delivered waveform/version, output route, system volume, fade transitions and actual exposure timestamps. Initially vary only one component (e.g. beat rate) and fix the rest. Digital gain is not bedside acoustic pressure.

Latent state and disturbances:

```
x[n,k] = (sleep/wake state, time in state, sleep pressure,
          circadian phase, autonomic/arousal state)
w[n,k] = (unobserved environmental events, health/context, process noise)
x[n,k+1] ~ F_theta(x[n,k], u[n,k], recent input history, w[n,k])
```

This is a nonlinear, time-varying, partially observed system with stage dwell times and carryover. A controlled hidden semi-Markov/state-space model is a candidate representation, not a claim that available data identify every physiological component. Start with simpler models if data cannot support it.

Observations:

```
y[n,k] = H(x[n,k]) + measurement error       # HR/motion/etc if available
y_stage[n,k] ~ confusion_model(stage[n,k])  # retrospective stage estimate
r[n] = morning restfulness, plus disturbance/daytime-function outcomes
```

Every observation carries a source time, receipt time, quality flag and missingness flag. At decision time t, the controller may use only observations already received (information set I_t), not subsequently backfilled stage labels. Offline identification can use retrospective labels with uncertainty, but a live policy cannot use future information. Logging graphical epoch width does not establish delivery latency.

HR decrease, HRV increase and more N3 are candidate observations/proxies, not validated rewards. Arousal and stage changes can naturally alter them even without sound; movement can also be artifact or normal repositioning. No current sensor pathway is certified here as an arousal detector.

## Aim of identification and control

Primary question: which bounded audio setting or policy increases expected personal morning restfulness reproducibly, while preserving continuity and daytime function?

```
maximize over policy pi: E[r[n] | u = pi(I_t)]
subject to predefined exposure bounds and tolerability/continuity constraints
```

Restfulness is ordinal; category distributions and replication matter beyond a fitted mean. Practical comparison utility may penalize sound-related awakenings, excessive exposure and unnecessary switching, but penalty weights are explicit personal design choices. Do not hide them in an unexplained “sleep score.”

Identification targets, in increasing difficulty:

1. Night-level total effect of a fixed setting versus its comparator.
2. Context/state-dependent short-horizon effects, including disturbances and plausible lags.
3. Whether adaptation improves morning outcomes over the best fixed setting and matched exposure replay.

A single scalar morning rating cannot identify many independent five-minute frequency effects in one night. Natural deep-sleep prevalence is also strongly time-dependent. Always assigning one frequency early and another late confounds frequency with time/state. Changing frequency only when HR rises confounds treatment with the trigger. These are identification problems, not solved by a more elaborate optimizer.

## Proposed identification sequence

1. Preserve a versioned baseline and quantify adherence/missingness. Use balanced randomized fixed conditions across nights to learn a coarse personal response before any fine search.
2. Separately log acquisition latency/coverage without adaptive audio. Confirm whether suitable overnight data are available under supported Watch APIs; see [feasibility](feedback-feasibility.md).
3. Only after tolerability and usable sensing, consider randomized bounded block assignments with minimum dwell and smooth transitions. Five-minute blocks, allowable frequencies and washout/lag windows are provisional. A larger block or fixed-night design may be necessary to avoid disturbance and carryover. Record assignment probabilities, trigger context, elapsed sleep time and input history.
4. Fit an interpretable lagged model or stage-transition model with uncertainty. Evaluate on held-out nights and replicate. Thirty-second stage epochs are correlated; they are not thousands of independent participants. Do not optimize on a stage label that is both noisy and affected by scoring artifacts.
5. Compare a frozen adaptive policy against a fixed/replayed policy on new randomized nights. Separate learning from evaluation. Use attenuation/stop fallbacks for stale or poor-quality inputs; no automatic escalation to chase a favorable proxy.

This is closer to constrained adaptive experimentation plus state estimation than classical regulation to a target frequency. Bayesian optimization/contextual bandits could help choose a small night-level parameter set later, but only with logged exploration, suitable uncertainty and validation. If no useful real-time output is available, night-to-night optimization using morning outcomes remains a legitimate slower loop.
