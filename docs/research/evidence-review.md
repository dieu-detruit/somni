# Sleep audio: evidence review

Reviewed: 2026-11-03. Status: research synthesis, not a clinical protocol or an implemented feature specification.

## Question and scope

Which interventions are worth testing in an iPhone audio app whose primary outcome is morning restfulness, with Apple Watch supplying retrospective sleep estimates?

This is a targeted narrative review, not an exhaustive systematic review. Searches used PubMed, PMC, journal websites, and official Apple documentation. Search families included bedtime music/insomnia/randomized trial, monaural or binaural beats/sleep, continuous noise/PSG, presleep slow breathing, and closed-loop acoustic stimulation. Positive, null, and adverse findings were retained. Clinical trials and direct physiological measurements informed decisions; reviews provided context. No commercial product claims were used as efficacy evidence.

Access is stated below. An abstract-level review cannot establish all allocation, attrition, calibration, or analysis details. Full-text access failed for some publisher pages; these studies are not represented as fully appraised. Evidence labels are informal decision aids, not a new GRADE assessment. Findings from insomnia patients, young healthy adults, and anxiety experiments are not interchangeable. Morning recovery is usually not the primary endpoint in these papers.

## Decision summary

1. **Prioritize a short, comfortable wind-down session and measure morning outcomes.** This is more directly feasible than overnight physiological stimulation. Music studies support perceived sleep quality more consistently than objective changes.
2. **Keep monaural beats as a controlled experimental addition.** Plausibility and acute psychological findings do not establish improved sleep or morning recovery.
3. **Treat continuous noise as environment-dependent.** Sound that masks traffic can also disrupt sleep. Do not assume all-night playback or a particular noise color is beneficial.
4. **Keep guidance outside the current experimental scope.** Breathing findings below remain background evidence and do not define an active intervention.
5. **Investigate real-time audio feedback as a parallel feasibility track.** EEG-phase stimulation has distinct hardware requirements and must not be conflated with Watch-informed adaptation.

## Evidence ledger

### Music and pre-sleep relaxation

**M1 — Jespersen et al., 2019.** [A randomized controlled trial of bedtime music for insomnia disorder](https://pubmed.ncbi.nlm.nih.gov/30676671/), DOI 10.1111/jsr.12817. **Access: abstract.** Fifty-seven people with insomnia randomized to music, audiobook, or waitlist (19 each), assessor-blinded. The primary insomnia-severity interaction was not clearly significant (p=.06); perceived improvement and quality of life improved, while objective sleep did not. This supports testing subjective benefit with an active comparator. It does not show that music reliably increases restorative physiology.

**M2 — Jespersen et al., 2022.** [Cochrane review: Listening to music for insomnia in adults](https://pubmed.ncbi.nlm.nih.gov/36000763/), DOI 10.1002/14651858.CD010459.pub3. **Access: abstract; synthesis rather than primary trial.** Thirteen trials, 1,007 participants, daily prerecorded music for 25–60 minutes over three days to three months. Supports subjective sleep quality; three studies with objective measures did not establish objective improvement. Blinding and variation in intervention/control limit attribution. Do not translate questionnaire-scale differences into minutes saved, or generalize prerecorded music evidence directly to synthesized noise.

**M3 — Scullin et al., 2021.** [Bedtime Music, Involuntary Musical Imagery, and Sleep](https://pubmed.ncbi.nlm.nih.gov/34105416/), DOI 10.1177/0956797621989724. **Access: abstract.** Survey N=199; laboratory randomized comparison N=50 of lyrical versus instrumental popular songs. Instrumental versions increased nighttime earworms and worsened PSG-measured sleep. This is not a test of all ambient sound or of instrumental audio versus silence. Track unwanted repetition/earworms rather than assuming lyric-free music is universally sleep-friendly.

### Beats: mechanism and sleep must be separated

**B1 — Bang, Choi & Yoon, 2019.** [Minimal Effects of Binaural Auditory Beats for Subclinical Insomnia](https://pubmed.ncbi.nlm.nih.gov/31433343/), DOI 10.1097/JCP.0000000000001097. **Access: abstract.** Double-blind randomized sham-controlled trial, 43 completers; music with versus without theta binaural beats for 30 minutes before sleep over two weeks. No significant between-group insomnia-severity difference (p=.656). Within-group effect sizes do not establish an incremental beat effect. This is a reason to include the same carrier audio without beats as comparator, not proof that every beat design is ineffective.

**B2 — Lee et al., 2024.** [Effect of dynamic binaural beats on sleep quality](https://pubmed.ncbi.nlm.nih.gov/38629490/), DOI 10.1093/sleep/zsae097. **Access: abstract.** Ten healthy adults, two-night crossover, PSG. Dynamic left/right differences of 0–3 Hz were associated with shorter sleep latency than no-sound sham. Small sample, short exposure and absence of an ordinary-audio active control leave considerable uncertainty. Binaural delivery requires separated left/right signals; this is not validation of a mono phone speaker preset.

**B3 — Venkatesan et al., 2025.** [Beating stress](https://www.frontiersin.org/journals/psychology/articles/10.3389/fpsyg.2025.1539823/full), DOI 10.3389/fpsyg.2025.1539823. **Access: full-text methods, results and limitations.** Online N=308 randomized to monaural beats plus music, beats only, or pure tone, 30 minutes. Anxiety/mood changes favored the combined listening experience in relevant analyses; sleep and next-morning recovery were not measured. No music-only control means the additional contribution of beats cannot be isolated. Headphone screening also limits transfer to speaker use. Authors reported music-industry employment/consulting interests. A relaxation hypothesis remains testable; a sleep-efficacy conclusion does not follow.

### Continuous noise and environmental masking

**N1 — Riedy et al., 2021.** [Noise as a sleep aid](https://pubmed.ncbi.nlm.nih.gov/33007706/), DOI 10.1016/j.smrv.2020.101385. **Access: abstract; systematic review.** Thirty-eight studies of continuous broadband noise; evidence for sleep benefit rated very low, with both improvements and disruption. Noise properties, comparators, measurements and co-interventions differed. This review excludes intermittent stimulation intended to enhance slow waves, so it cannot be used to dismiss that separate mechanism.

**N2 — Capezuti et al., 2022.** [Systematic review: auditory stimulation and sleep](https://pubmed.ncbi.nlm.nih.gov/34964434/), DOI 10.5664/jcsm.9860. **Access: abstract; systematic review.** Thirty-four studies, 1,103 participants, white/pink/mixed sound. Some positive findings but no strong overall support. Music alone, binaural tones and synchronization studies were excluded. Short-term studies reporting no adverse effects are not evidence that indefinite nightly playback is harmless.

**N3 — 2026 PSG trial.** [Efficacy of pink noise and earplugs for mitigating intermittent environmental noise](https://pubmed.ncbi.nlm.nih.gov/41627391/), DOI 10.1093/sleep/zsag001. **Access: abstract and figure descriptions; full text blocked.** Twenty-five healthy adults, seven laboratory nights. Conditions included environmental noise, continuous pink noise at 40/50 dBA in relevant combinations, and earplugs. Environmental noise reduced N3; pink-noise exposure reduced REM. Adding pink noise worsened sleep structure despite some improvements in fragmentation/N3; earplugs mitigated most environmental-noise effects. Subjective outcomes also worsened after noise exposures. These specific laboratory levels and spectra cannot be mapped to an app volume slider or generalized to all low-level sound.

**N4 — 2026 pilot.** [Pink noise reduces impact of traffic noise on sleep and the blood metabolome](https://pubmed.ncbi.nlm.nih.gov/41513961/). **Access: abstract.** Twelve healthy participants, five consecutive laboratory nights; traffic events, 45 dB continuous pink noise, combined exposure and quiet baseline. Masking attenuated acute traffic-related fragmentation and some metabolic changes. Small homogeneous sample and different acoustic conditions limit generalization. N3 and N4 are genuine tension in the evidence, not grounds to select only the favorable study. Bedroom noise context, exposure level, duration and stage-specific effects need comparison.

### Breathing and closed-loop stimulation

**R1 — Kuula et al., 2020.** [Presleep slow breathing and music listening pilot](https://pmc.ncbi.nlm.nih.gov/articles/PMC7198497/), DOI 10.1038/s41598-020-64218-7. **Access: full-text methods, Table 2 and limitations.** Twenty young adults, ten per intervention arm, each with intervention/control nights; 30-minute breathing or music. Acute HRV increased, but breathing had no main effect on basic PSG measures. Music's N3 increase was a nonsignificant trend (p=.091). Small sample, unblinded participants and uncorrected multiple testing make spectral findings exploratory. A short breathing feature would be a usability experiment, not a reproduction of this dose or proof of better recovery.

**C1 — Ngo et al., 2013.** [Auditory closed-loop stimulation of the sleep slow oscillation enhances memory](https://pubmed.ncbi.nlm.nih.gov/23583623/), DOI 10.1016/j.neuron.2013.03.006. **Access: abstract.** In-phase EEG-triggered stimulation enhanced slow oscillations/spindles and declarative memory; out-of-phase stimulation was ineffective. The defining feature is measured EEG phase, not merely playing a low-frequency beat or detecting a sleep stage.

**C2 — Henin et al., 2019.** [Closed-loop stimulation enhances oscillations but not memory](https://pubmed.ncbi.nlm.nih.gov/31604814/), DOI 10.1523/ENEURO.0306-19.2019. **Access: abstract.** Nap study N=12 and overnight double-blind replication N=19 increased oscillatory responses without improving the tested memory outcomes. Physiological entrainment cannot be equated with a useful behavioral result, much less next-morning restfulness.

## Measurement and clinical context

- [Consensus Sleep Diary, Carney et al., 2012](https://pubmed.ncbi.nlm.nih.gov/22294820/), DOI 10.5665/sleep.1642: expert/user-informed prospective diary framework. Use it to inform timestamps, estimated latency and awakenings. A shortened Somnio form is not automatically a validated instrument.
- [Apple sleep-stage validation, updated October 2025](https://www.apple.com/health/pdf/Estimating_Sleep_Stages_from_Apple_Watch_Oct_2025.pdf): accelerometer-based estimates aligned with PSG/EEG reference data; not EEG phase sensing. Treat stage durations as secondary observations with missingness and algorithm variation, not optimization targets.
- [AASM behavioral-treatment guideline, 2021](https://pubmed.ncbi.nlm.nih.gov/33164742/): multicomponent CBT-I strongly recommended for chronic insomnia; relaxation conditionally recommended; sleep hygiene alone not recommended as sole treatment. This does not validate a specific audio-guided breathing app. Somnio's wellness experiment should not be presented as CBT-I or automated sleep restriction.

## Unanswered questions

No selected study establishes the optimal speaker-based monaural frequency, carrier, level or duration for morning restfulness. No evidence here establishes that personalized frequency optimization outperforms comfortable ordinary audio. Pleasantness, expectations, bedtime ritual and masking remain plausible overlapping contributors. A good first night is encouraging but cannot distinguish them from ordinary night-to-night variation.

Priority full-text follow-up: N3/N4 exposure calibration and counterbalancing, M1 adherence/control delivery, B1/B2 allocation and carryover. Preserve effect definitions and confidence intervals when extracting these; do not substitute significant within-group changes for a between-condition result.

## Additional closed-loop evidence

**C3 — Diep et al., 2021.** [Consecutive-night acoustic stimulation in chronically short sleepers](https://pubmed.ncbi.nlm.nih.gov/33639484/), DOI 10.1016/j.sleep.2021.01.044. **Access: abstract.** Twenty-five adults, randomized double-blind crossover, automated device with up-phase-triggered tones and sleep-stage/arousal gating, two consecutive nights. Participants reported better daytime alertness and objective attention improved after two nights; responses varied substantially. This is positive evidence relevant to the recovery goal, rather than memory alone. It does not establish benefit from a fixed beat or a Watch-only controller, and does not justify deliberately restricting sleep. Several authors had device-industry affiliations.

The current research scope is audio-only single-participant reproducibility. See the [current audio audit](current-audio-audit.md) for why the existing synthetic wave and carrier parameters must be treated as engineering hypotheses.
