# Experiment roadmap

Product direction updated 2026-11-12: the app's main interaction is a [personal sleep synthesizer](../personal-synthesizer.md), with music, tone/beat and environmental layers, saved favorites and optional control recipes. The research methods below are optional tools behind that experience; they do not impose a trial workflow or rank subjective comfort below protocol compliance.

Status: proposals for discussion, not implemented features. Updated 2026-11-03.

## Objective

Run a single-participant research program: find audio conditions that reproducibly improve next-morning restfulness for the participant, without worsening sleep continuity, daytime sleepiness, or burden. Population efficacy and productization are not current goals. Only audio properties and their playback policy are intervention variables; breathing exercises, spoken guidance and other behavioral interventions are out of scope. Context is recorded as a potential confound, not deliberately manipulated. See the [evidence review](evidence-review.md) for sources and appraisal limitations. The priorities below are engineering judgments informed by that evidence, not established treatment rankings.

| Priority | Route | Why it is testable | Main uncertainty | First useful comparison |
| --- | --- | --- | --- | --- |
| 1 | Comfortable, short wind-down audio | Fits current speaker/timer architecture; subjective music outcomes are promising | Current synthesized ambience is not the prerecorded music studied | Fixed 30-minute current ambience versus no added audio |
| 2 | Monaural beat as an add-on | Current app already offers a 4 Hz physical beat | Specific sleep/recovery benefit beyond carrier sound unproven | Same ambience, timer and comparable perceived loudness, beat on versus off |
| 4 | Noise masking only when noise is a problem | Plausible benefit under disruptive environmental noise | Continuous noise can itself worsen sleep; acoustic exposure is unknown | Reduce external noise first; otherwise a separately designed short, low-level masking test |
| Later | Retrospective personalization | Could choose the most tolerable repeatable settings | Sparse data, confounding and overfitting | Replicate an apparent winner on new randomized nights before recommending it |
| Parallel research | Real-time feedback controlling audio | A central research interest; separate acquisition feasibility from benefit | Sensor freshness, availability, artifacts and delay; Watch stages are not EEG phase | Log usable inputs first, then compare adaptive and matched fixed/replayed audio |

## Comfort-led exploration

Immediate comfort and next-morning recovery take precedence over an ideal experimental sequence. This is informal personal exploration, not a publication-ready trial. There is no mandatory requirement to start with silence, ambience alone, or a beat-off condition. A tolerable beat-containing setting can be the reference, and preferred beat variations can be explored first. Beat-off remains an optional candidate if later experience makes it useful, rather than a prerequisite.

Prioritize beat parameters and independently adjustable background level. Keep a comfortable reference preset available and avoid changing a successful setting merely to satisfy a study schedule. Background alternatives can be explored separately, but background-only playback need not be the first comparator. Changes may be chosen by preference; label those records as exploratory rather than claiming randomized causal estimates.

A minimal useful record is the setting/version, whether it felt comfortable, morning restfulness, and any sound-related disturbance. Randomization, neutral labels and replication are optional tools when uncertainty warrants the burden. If formal evidence is later needed, design a separate prospective study instead of retroactively presenting convenience data as a controlled trial.

## Optional comparison tools (not a required sequence)

### Step 0: make outcomes trustworthy

Keep morning restfulness 1–5 as the primary outcome, collected soon after waking and before displaying Watch results. Keep labels fixed. Record rating time. Add optional midday sleepiness and sound-related disturbance; do not silently treat them as the same outcome.

Add trial condition, intended versus actual audio exposure, preset/version, timer, settings changes and adherence. Ask for only a few contextual fields: sleep opportunity, unusual caffeine/alcohol, illness/travel, and unusual bedroom noise. An imperfect short diary completed consistently is more useful than an abandoned detailed form.

The current app records settings, playback history and morning ratings, but does not yet implement prospective assignment, concealed neutral condition labels, complete exposure checkpoints, or trial analysis. Its existing comparison is observational. Watch data gaps remain missing, not zero sleep.

### Step 1: determine whether the basic routine helps

Proposed feasibility design: seven ordinary baseline nights, then 14 assigned comparison nights with seven audio and seven no-added-audio nights in randomized balanced order. Keep bedtime opportunity, placement and 30-minute timer reasonably consistent. These counts are pragmatic workload choices, not a power calculation or a clinical efficacy sample size. Extend or repeat if too few completed nights; do not keep testing until a favorable p-value appears.

This estimates the value of the whole listening routine, including expectation and ritual. The no-audio condition cannot blind the user. A useful routine can still be worthwhile without proving brainwave entrainment.

### Step 2: isolate the beat's added value

When an incremental beat-effect question becomes useful, compare matched audio with and without beats. Before then, a comfortable beat-containing reference can be compared with another beat setting. Do not simultaneously change carrier, noise color, timer and volume. Use neutral A/B labels with consent and record which condition the listener thinks occurred: audible beats can break masking. There is no guaranteed placebo-equivalent audio.

Do not vary frequencies nightly to chase the prior morning's rating. The current 180/184 Hz carrier pair is an experimental implementation choice, not a literature-established optimum. Comfort and speaker playback feasibility should be checked before a frequency sweep is even considered.

### Parallel track: real-time feedback

This is an active research direction, not dismissed as low value. Begin with acquisition feasibility while fixed-audio comparisons continue. See [feedback feasibility](feedback-feasibility.md). Only the audio output is manipulated. Distinguish a tolerability controller (e.g. reduce sound after a reliable disturbance signal) from a sleep-stage controller and from EEG-phase stimulation. They need different measurements and evidence.

### Before any new stimulus

Audit the [current waveform](current-audio-audit.md). The synthetic wave-like swell and the 4-Hz tonal beat have independent parameters and no direct efficacy validation. A component comparison (steady versus swelling ambience, beat off) can precede the beat comparison if it answers the participant's most relevant question. These are available research choices, not a mandatory fixed order.

## Analysis and decisions

- Freeze the outcome, schedule, practical benefit threshold and exclusion flags before seeing condition results. For example, a sustained one-category restfulness shift can be chosen as a personal threshold; it is not a validated minimum clinically important difference.
- Show every night's value and missing entries. Report condition counts, category distributions, medians and descriptive means, plus paired/block differences where the design supplies them. The 1–5 score is ordinal; means alone can hide distribution changes.
- Describe assigned-condition results first, then an adherence-based sensitivity view. Keep bad nights and protocol deviations visible. Mark unusual events prospectively and show results with/without them rather than deleting inconvenient observations.
- Check sleep opportunity and day-of-week imbalance. Tiny personal samples do not support elaborate covariate models, subgroup discovery or confident personalized causal predictions.
- Watch total sleep and awakenings are secondary; stage durations are exploratory. Do not select settings by maximizing Deep or by declaring that absent Watch confirmation disproves subjective benefit.
- A repeated benefit with no meaningful downside supports keeping a setting. An inconclusive result supports more data or a simpler choice. Replicate a promising winner against its comparator in a new period. Worsened sleep or daytime function overrides a better stage score.

## Exposure boundaries

Prefer the existing short timer for initial tests. Continuous playback is not the automatic next escalation. Do not increase volume in response to a poor night or a Watch metric. Digital amplitude is not calibrated bedside dBA; record device volume, output route and placement, and acknowledge that the app cannot infer acoustic dose from its slider. Assess sound annoyance, awakenings and earworms.

Audio is an adjunctive personal experiment. Persistent non-restorative sleep, marked daytime sleepiness or suspected sleep-disordered breathing should not be handled by escalating sound stimulation. Clinical insomnia care and individualized treatment are separate from this product roadmap.

## Next implementation candidate

A small experiment journal is the highest-value next change: condition assignment, morning-first ratings, adherence/exposure logs, and a simple comparison chart. It makes the existing audio useful for learning before adding more sound technologies. Decide on this scope before writing product code.
