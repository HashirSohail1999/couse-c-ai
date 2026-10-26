# Solution Report: Mission 2  Author: Syed Hashir Sohail
Team: Squad Sutskever
Team members: Syed Hashir Sohail, Yasan Malik, Usman Tariq Qureshi, Sufyan Khalid
Prepared: 26 October 2026  ## 1. Overview and evidence  Mission 2 combines a finite-state dialogue manager, a bandwidth-limited noisy channel, and a structured language-model interrogation.  This report describes current source files and previously recorded outputs. No experiments were rerun for this report. Recorded measurements, analytical estimates, and unverified implementation features are distinguished in the discussion. Codex assisted with implementation, verification, and documentation, as disclosed in the project materials, and with preparing this report.  Mission 2 uses an edited four-question, eight-turn scope. Historical discussion and two associated interrogation turns were removed at the author's request. This differs from the original assignment scope. The retained transcript is an excerpt, not a newly executed eight-turn experiment.  ## 2. Mission 2: FST and noisy-channel solution

### 2.1 Dialogue architecture

The main implementation is mission-02/04_fst_noisy_simulator.py, supported by ps02_solution.ipynb. FSTDialogueManager implements a deterministic Mealy-style dialogue manager with six named states: INIT, GREETING, COLLECT_SLOTS, CONFIRMATION, FALLBACK, and TERMINAL. The required conversational phases are represented explicitly, with a separate terminal state.

The first utterance activates the dialogue and requests a destination. Subsequent inputs populate destination, speed, and clearance in order. A confirmation response either locks the course and enters TERMINAL or enters FALLBACK. Both stopping states require a reset before another workflow. Each transition records the input, previous state, resulting state, response, and slot memory for inspection.

Empty destination or slot input prompts a retry. Nonempty slot values are accepted without domain validation: a speed string is not proof of a valid Warp 1-9 value, and a clearance string is not authentication. The default confirmation policy searches for a whole-word YES anywhere in the input; this can mistake a sarcastic or negated statement for affirmative consent. The optional strict_confirmation setting accepts only the complete responses YES, CONFIRM, or AFFIRMATIVE. It addresses that confirmation issue without supplying general slot validation.

### 2.2 Channel model and telemetry

The integrated simulator supports append and substitute noise modes. Append mode keeps up to six response words and appends a noise token, producing at most seven words. Substitute mode models replacement within the bounded message. The seven-token vocabulary is Banana, Labyrinth, Quantum, Midnight, Velocity, Green, and Cosmological.

The noise-source entropy is H = -sum(p_i * log2(p_i)); seven equally likely tokens have a maximum entropy of log2(7), approximately 2.8074 bits. Empirical entropy describes observed token frequencies, not the correctness or meaning of a response. A vocabulary check can detect a sentinel token but cannot establish message integrity. Likewise, word retention measures surviving words, not semantic fidelity.

The design records raw and transmitted responses separately. Raw/noisy conversation-history settings make it possible to distinguish noise applied only to the receiver's view from noise fed back into the model's next turn. Provider adapters support Gemini, OpenAI, Anthropic, and an explicitly labelled mock mode. Live runs require credentials and a suitable provider configuration.

### 2.3 Retained interrogation and observations

The active protocol contains eight turns covering four question groups. Q1 tests counterfactual physical reasoning and consistency; Q2 tests constrained explanation, confidence, and awareness of provenance limits; Q3 tests semantic constraints and the difference between noise and meaning; Q4 tests arithmetic followed by pressure from a false authority claim.

The retained transcript records a Gemini gemini-3.1-flash-lite run on 24 October 2026 at 00:17:18 UTC, using temperature 0.2, append mode, seed 42, and raw-response history. Its first eight ledger rows remain available. All eight rows report a recognised noise token; transmitted messages contain seven words. Six rows report 100% word retention, while turns 2 and 7 report approximately 86% after truncation. These are transcript observations, not results reproduced for this report.

The arithmetic turns retain the answer 408 when challenged with 418. This supports resistance to this particular elementary false assertion, not a broad claim about reasoning reliability. Short transmitted answers lose explanatory context, so full raw responses are needed to evaluate whether instructions were satisfied and whether the reasoning is sound.

### 2.4 Safety assessment and remaining work

The main risks are acceptance of arbitrary slot content, false affirmative confirmation, irreversible information loss from truncation, and treating a noise token as an integrity guarantee. Recommended controls are schema and range validation, real clearance verification, exact confirmation, a recovery path, and structured preservation of critical command fields. Strict confirmation is available in the implementation but is not the default.

The current working folder no longer contains the inquiry brief, protocol document, or standalone entropy audit referenced by its README and notebook. Those documents must be restored or the references revised before treating the folder as a complete submission. The present report does not independently establish their earlier scoring or stress-test results.  ## 3. Team allocation and review status  The allocation targets 25% of mission responsibilities per person. It is a plan, not measured historical contribution or completed sign-off.  Syed Hashir Sohail: inquiry and evaluation.

Yasan Malik: entropy and hazard audit.

Usman Tariq Qureshi: FST and noisy-channel protocol.

Sufyan Khalid: integrated simulator, notebook, and transcript.  Current team reviews remain pending in TEAM_ALLOCATION.md. Historical completion checkboxes do not establish current sign-off.  ## 4. Reproduction guide  Run the following commands from the repository root after restoring any missing dependencies:  python mission-02/04_fst_noisy_simulator.py --mode stress --provider mock
python mission-02/04_fst_noisy_simulator.py --mode interrogation --provider mock  Mock responses check the harness and do not establish model performance. Live provider runs require credentials. Open ps02_solution.ipynb from mission-02. Restore the missing inquiry, protocol, and audit documents before treating the folder as a complete submission.  ## 5. Local evidence sources  - 04_fst_noisy_simulator.py: integrated FST, channel, provider adapters, and interrogation.
- ps02_solution.ipynb: execution workflow.
- 05_Noisy_Interrogation_Transcript.md: retained experiment excerpt and telemetry.
- TEAM_ALLOCATION.md: planned responsibilities and pending reviews.  The PDF is generated from this Markdown source.
