# Real-time audio feedback: feasibility track

Status: research proposal, not implemented control. Goal: determine whether timely, reliable physiological or environmental information can improve audio decisions for one participant.

## Controllers are different hypotheses

| Controller | Possible input | Audio decision | What it would establish |
| --- | --- | --- | --- |
| Disturbance/tolerability | A validated movement or arousal proxy, with quality flags | Attenuate or stop sound | Whether avoiding poorly tolerated exposure helps; not sleep-stage accuracy |
| Environmental masking | Background noise estimate separated from app playback | Change masking only within a predefined range | Whether context-dependent masking beats a fixed exposure |
| Stage-aware | Validated timely stage estimates | Gate defined sounds to selected intervals | Whether stage gating adds benefit over comparable fixed/replayed audio |
| EEG-phase | Measured EEG phase with validated timing | Trigger precisely timed pulses | Whether phase timing helps; requires EEG acquisition, not just Watch stages |

Candidate inputs are not currently available or validated simply because they appear in this table. A microphone can hear the app's own output and needs echo/source separation; movement and heart rate are nonspecific. No input should be presented as an arousal detector before validation.

## Acquisition experiment before stimulation

Log sensor timestamp, receipt timestamp, source, sample quality, missing intervals and app lifecycle. Characterize latency distribution and overnight coverage. Measure communication failures, battery use and whether sensing perturbs normal sleep recording. No sound changes during this stage. Retrospective agreement with Watch labels cannot prove real-time EEG/arousal accuracy.

[HealthKit observer queries](https://developer.apple.com/documentation/healthkit/hkobserverquery) notify about stored/deleted samples; they are not a guaranteed live sleep-stage feed. [Watch extended runtime sessions](https://developer.apple.com/documentation/watchkit/using-extended-runtime-sessions) have purpose-specific limits: smart alarm is 30 minutes and requires alarm behavior. Do not chain it into an overnight monitoring mechanism or label sleep as a workout solely to keep the app running.

Short foreground experiments can test communications and commands, but are not evidence of all-night background operation. If the intended sensor path cannot supply suitable overnight data under supported APIs, reconsider the controller or use separately evaluated hardware. A personal research target does not remove OS runtime constraints.

## First control experiment, once inputs are usable

Prefer a conservative attenuation/stop controller over automatic escalation of sound intensity. Predefine input quality requirements, thresholds, minimum dwell time, hysteresis, change-rate limits and the fallback when data become stale. Log every trigger, input age, actual audio command and exposure. A stale or missing input must not be treated as confirmed deep sleep.

Compare adaptive playback with a fixed condition and, if feasible, a matched replay of an earlier control sequence. Replay helps separate the value of timing from merely hearing less or different audio; it is imperfect because nights differ. Assess assigned-condition outcomes and actual exposure separately. Judge morning restfulness, sleep disturbance and daytime function, not just apparent closed-loop activity.

[Diep et al. (2021)](https://pubmed.ncbi.nlm.nih.gov/33639484/) is a promising physiological-stimulation lead, but its EEG-related timing and automated device are prerequisites of that study, not capabilities already supplied by the current Watch app. Fixed tonal beating and a 14-second swell do not reproduce it.

## Slow-scale control and identification

The [I/O formulation](audio-methods-and-control-model.md) treats minute-scale audio decisions, delayed stage estimates and morning outcomes separately. Its five-minute block is a provisional engineering timescale, not a measured Watch delivery guarantee. Fixed-night experiments can precede and inform within-night adaptation.
