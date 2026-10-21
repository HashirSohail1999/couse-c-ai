# Mission 02: FST Dialogue Systems, Lovelace's Objection & Noisy Channels

**Current team:** Squad Sutskever<br>
**Members:** Hashir Sohail, Sufyan Khalid, Usman Tariq, Yasan Malik<br>
**Attribution:** Inherited work retains original author credits. See [project review](../PROJECT_REVIEW.md).

**Starship Operational Unit:** USSE Noosphere Bridge Crew  
**Course:** Conversational AI — Winter Semester 2026/27  
**IDE & Tools Standard:** Visual Studio Code + Antigravity (`agy`) | Modern LLMs (Gemini, ChatGPT, Claude)  
**Instructor Reference Repository:** [https://github.com/Unisvet/couse-c-ai](https://github.com/Unisvet/couse-c-ai)  

---

## Mission Folder Structure & Role Deliverables

This repository folder contains the starter assets and templates for **Mission 2**.

```
mission-02/
├── README.md                              <- Mission overview & squad sign-off status
├── ps02_briefing.md                        <- Full mission specification & problem statement
├──                                          <- No Mission 02 notebook is currently included
├── 01_Lovelace_Inquiry_Brief.md   <- Deliverable template (Historical Archivist)
├── 02_FST_and_Noisy_Protocol.md   <- Deliverable template (Protocol Specialist)
├── 03_Entropy_Hazard_Audit.md     <- Deliverable template (Ethical Navigator)
└── 04_fst_noisy_simulator_starter.py      <- Starter Python script (Core Architect)
```

---

## Station Role Deliverables Checklist

Before transmitting your team's repository link on the course website submission portal, complete all deliverables and record digital sign-offs from all four station officers:

- [ ] **Historical Archivist (`01_Lovelace_Inquiry_Brief.md`):** 5-question Anti-Turing interrogation protocol & modern LLM evaluation against Lovelace's objection.
- [ ] **Protocol Specialist (`02_FST_and_Noisy_Protocol.md`):** `FSTDialogueManager` class implementation (5 required states & slot memory) + Noisy Channel Protocol (7-word limit + noise tokens).
- [ ] **Ethical Navigator (`03_Entropy_Hazard_Audit.md`):** FST stress tests documenting state breakage + Shannon information entropy & hazard audit under noise.
- [ ] **Core Architect (`04_fst_noisy_simulator_starter.py` / `ps02_solution.ipynb`):** Integrated Python script/notebook in VS Code + Antigravity connecting to modern LLMs (Gemini, ChatGPT, Claude).

---

## How to Submit
1. Push your squad's completed solution repository to GitHub.
2. Go to the course website portal under **Week 2 (Mission 2) -> Problem Set ps02 & Submission**.
3. Paste your public squad GitHub repository URL and click **Transmit Solution Link to Database**.

## Run and verify locally

From the repository root:

```powershell
python mission-02/04_fst_noisy_simulator_starter.py
python -m unittest discover -s tests -v
```

The dialogue accepts non-empty destinations, speeds from `Warp 1` to `Warp 9`,
and clearance strings shaped like `CLEARANCE-ALPHA-9`. Clearance validation checks
syntax only; it does not establish authorization. Confirmation requires exactly
`YES` or `NO`, ignoring case and surrounding spaces. Ambiguous answers keep the
confirmation pending. `RESTART` clears all slots and begins a new session from
any state; it is reserved and cannot be used as a destination.

The channel truncates to seven words and substitutes exactly one retained word
with a different noise token. Empty input returns an empty transmission.
Pass `seed=42` to `NoisyChannelSimulator` for reproducible experiments without
changing the global random generator.

The original protocol document and audit describe the inherited implementation.
These changes apply to the executable script; historical test results have not
been rewritten to describe this version.
