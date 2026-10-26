# Mission 03 — Squad Sutskever

Author: Syed Hashir Sohail. Earlier author names were aliases used for anonymity. This document records the current team's planned work allocation. Recorded evidence and AI-assistance disclosures are retained.

| Team member | Assigned role | Primary deliverable | Planned share |
|---|---|---|---|
| Syed Hashir Sohail | Systems Architect | `01_MultiHead_Attention_Core_starter.py` | 25% |
| Usman Tariq Qureshi | Communications & Protocol Officer | `02_RoPE_Positional_Engine.py`, `02_RoPE_Positional_Engine_starter.py` | 25% |
| Yasan Malik | Security & Ethics Sentinel | `04_Memory_Hierarchy_and_Safety_Audit_template.md` | 25% |
| Sufyan Khalid | Data & Payload Specialist | `03_GQA_and_KVCache_Benchmark_starter.py`, `results/gqa_kvcache_report.md` | 25% |

Each member has the same planned workload: 40% of his time on implementation or analysis, 30% on verification, 20% on documentation, and 10% on peer review. Shares represent intended effort, not file counts or measured completed work. Rebalance supporting tasks if one role takes longer. Syed coordinates the shared solution notebook; each member supplies and verifies his own section.

## Responsibilities and acceptance criteria

- **Syed Hashir Sohail:** Review attention shapes, head splitting, scaling and causal masking; run the numerical correctness checks and explain their limits. Peer-review Yasan's memory audit.
- **Usman Tariq Qureshi:** Review RoPE rotation and position offsets; verify relative-position behavior and integration with cached keys. Peer-review Sufyan's cache integration.
- **Yasan Malik:** Review memory calculations, FlashAttention IO reasoning and resource-exhaustion mitigations; reconcile audit claims with the implementation and recorded measurements. Peer-review Syed's attention analysis.
- **Sufyan Khalid:** Review grouped-query attention and cache lifecycle; verify full versus cached decoding and record benchmark configuration, latency and memory. Peer-review Usman's positional engine.

## Current-team sign-off

- [ ] Syed Hashir Sohail — assigned section and peer review verified.
- [ ] Usman Tariq Qureshi — assigned section and peer review verified.
- [ ] Yasan Malik — assigned section and peer review verified.
- [ ] Sufyan Khalid — assigned section and peer review verified.

Historical completion marks elsewhere do not establish sign-off by the current team.
