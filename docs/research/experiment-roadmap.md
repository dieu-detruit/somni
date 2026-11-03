# Experiment roadmap

Status: proposals for discussion, not implemented features. Updated 2026-11-03.

## Objective

Increase next-morning restfulness without worsening sleep continuity, daytime sleepiness, or burden. See the [evidence review](evidence-review.md) for sources and appraisal limitations. The priorities below are engineering judgments informed by that evidence, not established treatment rankings.

| Priority | Route | Why it is testable | Main uncertainty | First useful comparison |
| --- | --- | --- | --- | --- |
| 1 | Comfortable, short wind-down audio | Fits current speaker/timer architecture; subjective music outcomes are promising | Current synthesized ambience is not the prerecorded music studied | Fixed 30-minute current ambience versus no added audio |
| 2 | Monaural beat as an add-on | Current app already offers a 4 Hz physical beat | Specific sleep/recovery benefit beyond carrier sound unproven | Same ambience, timer and comparable perceived loudness, beat on versus off |
| 3 | Short breathing/relaxation guidance | Targets bedtime arousal; low implementation cost | Pilot physiology is weak evidence for recovery; forcing pace can be uncomfortable | Same audio with versus without optional comfortable guidance |
| 4 | Noise masking only when noise is a problem | Plausible benefit under disruptive environmental noise | Continuous noise can itself worsen sleep; acoustic exposure is unknown | Reduce external noise first; otherwise a separately designed short, low-level masking test |
| Later | Retrospective personalization | Could choose the most tolerable repeatable settings | Sparse data, confounding and overfitting | Replicate an apparent winner on new randomized nights before recommending it |
| Defer | Watch-triggered overnight sound / EEG-phase stimulation | Interesting future research | Watch stages are not live EEG phase; physiological and practical prerequisites missing | Feasibility study before efficacy study; no overnight control feature yet |

## Recommended sequence

### Step 0: make outcomes trustworthy

Keep morning restfulness 1–5 as the primary outcome, collected soon after waking and before displaying Watch results. Keep labels fixed. Record rating time. Add optional midday sleepiness and sound-related disturbance; do not silently treat them as the same outcome.

Add trial condition, intended versus actual audio exposure, preset/version, timer, settings changes and adherence. Ask for only a few contextual fields: sleep opportunity, unusual caffeine/alcohol, illness/travel, and unusual bedroom noise. An imperfect short diary completed consistently is more useful than an abandoned detailed form.

The current app records settings, playback history and morning ratings, but does not yet implement prospective assignment, concealed neutral condition labels, complete exposure checkpoints, or trial analysis. Its existing comparison is observational. Watch data gaps remain missing, not zero sleep.

### Step 1: determine whether the basic routine helps

Proposed feasibility design: seven ordinary baseline nights, then 14 assigned comparison nights with seven audio and seven no-added-audio nights in randomized balanced order. Keep bedtime opportunity, placement and 30-minute timer reasonably consistent. These counts are pragmatic workload choices, not a power calculation or a clinical efficacy sample size. Extend or repeat if too few completed nights; do not keep testing until a favorable p-value appears.

This estimates the value of the whole listening routine, including expectation and ritual. The no-audio condition cannot blind the user. A useful routine can still be worthwhile without proving brainwave entrainment.

### Step 2: isolate the beat's added value

Only if audio is tolerable, compare ambience alone with the same ambience plus monaural beat on another preassigned set of nights. Do not simultaneously change carrier, noise color, timer and volume. Use neutral A/B labels with consent and record which condition the listener thinks occurred: audible beats can break masking. There is no guaranteed placebo-equivalent audio.

Do not vary frequencies nightly to chase the prior morning's rating. The current 180/184 Hz carrier pair is an experimental implementation choice, not a literature-established optimum. Comfort and speaker playback feasibility should be checked before a frequency sweep is even considered.

### Step 3: compare one wind-down addition

An optional brief, comfortable breathing/relaxation cue is a reasonable next feasibility test, or a personally pleasant non-intrusive sound alternative. A 5–10 minute introduction is a product hypothesis, not the 30-minute research intervention. Avoid breath holds and pressure to hit a target; stop guidance if uncomfortable. Track burden and bedtime arousal, then check whether any change persists to morning. Do not interpret a higher HRV reading during paced breathing as recovery.

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
