# Mission 07: Solution Report

**Contributors:** Syed Hashir Sohail, Yasan Malik, Sufyan Khalid, Usman Tariq

**Group:** sustkever (Group 17)

**Course:** Conversational AI, Winter Semester 2026/27

**Repository:** https://github.com/HashirSohail1999/couse-c-ai

**Prepared:** 23 November 2026

## 1. Objective and scope

Mission 07 repairs AURA Subsystem 07, the Gravitational Search Horizon and Process Reward Evaluator, in the Sagittarius A* scenario (`SEC-07-SGR`). Single-pass, left-to-right decoding commits to one reasoning chain and cannot recover from an early mistake. The solution replaces it with a System 2 test-time compute architecture: two search strategies over reasoning steps, a step-level process verifier, and a pruner that cuts hallucinated or reward-hacked branches. All modules use only Python's standard library.

This report covers the four Python modules and the squadron documentation `mission-07-doc.md`. The results below are the recorded outputs of each module's verification run, reproduced in Section 4 of `mission-07-doc.md`. The search problems, value models and reward scores are deterministic educational fixtures; they are not measurements of a live LLM.

The station mapping is:

- Syed Hashir Sohail: Systems Architect, Tree-of-Thoughts solver (`tot_solver.py`).
- Yasan Malik: Communications & Protocol Officer, MCTS and PUCT engine (`mcts_protocol.py`).
- Sufyan Khalid: Data & Payload Specialist, process reward evaluator (`prm_evaluator.py`).
- Usman Tariq: Security & Ethics Sentinel, event horizon pruner (`horizon_pruner.py`).

The mission is credited to all four contributors. Existing AI-assistance disclosures remain in the source files and in `mission-07-doc.md`.

## 2. Deliverables and execution flow

- `tot_solver.py`: `ThoughtNode`, `TreeOfThoughtsSolver` with BFS beam search and DFS backtracking, 8 self-checks and a Game-of-24 budget benchmark.
- `mcts_protocol.py`: `MCTSNode`, the 4-phase `MCTSEngine` with PUCT selection, 12 self-checks, a PUCT sensitivity sweep and a full search demo.
- `prm_evaluator.py`: `OutcomeRewardEvaluator`, `ProcessRewardEvaluator` with `min`, `prod` and `geometric_mean` reductions, and Math-Shepherd soft and hard labels.
- `horizon_pruner.py`: `EventHorizonPruner` with threshold pruning, sycophantic filler detection and step-splitting detection.
- `mission-07-doc.md`: squadron roster, architecture diagrams, station reports, integrated verification output and reflection.

The two search front-ends never judge reasoning themselves. Every candidate step that ToT or MCTS creates is scored by a value callback, which is the process reward evaluator. The event horizon pruner then adjusts that score for reward hacking. In ToT, a step whose adjusted score falls below the prune threshold is never expanded. In MCTS, the adjusted score becomes the rollout reward that is backpropagated into Q(s,a).

```text
Navigation prompt x
  -> Part 1: TreeOfThoughtsSolver | Part 2: MCTSEngine (PUCT)
  -> candidate step z_t
  -> Part 3: ProcessRewardEvaluator   (raw step score r_t)
  -> Part 4: EventHorizonPruner       (adjusted score r_adj)
  -> r_adj >= tau_horizon : surviving beam / MCTS backpropagation
  -> r_adj <  tau_horizon : branch severed before the event horizon
```

Test-time compute is metered in one place: one expansion means one generated thought scored by one verifier call, and `max_expansions` is a hard cap. Pruning, beam width and early stopping on a solved node decide where that fixed budget is spent; they do not add to it.

## 3. Part 1: Tree-of-Thoughts search

`ThoughtNode` stores the thought text, depth, step score, cumulative score, parent and children, and reconstructs the root-to-node trajectory. `TreeOfThoughtsSolver` offers two strategies under the same `max_expansions` budget:

- BFS beam search keeps the best B nodes at each depth and scores all of their children before going deeper.
- DFS backtracking follows the best child first, prunes children below the threshold, and backtracks into siblings when a branch dies.

The trajectory score is the weakest link (minimum step score), which matches the PRM `min` reduction. On the mission's mock tree (budget 12, B = 2, threshold 0.45, depth 3), both searches used 5 of 12 expansions, pruned the two dead ends, and reached the goal `13 - 9 = 4 -> 10 - 4 = 6 -> 4 * 6 = 24` with trajectory score 0.85. DFS needed 2 backtracks.

Because the mock tree is too small to separate the methods, the module also runs a real Game-of-24 benchmark on 12 solvable puzzles. A noisy value model (+/-0.35 deterministic noise) stands in for an LLM value prompt. Puzzles solved out of 12, with mean expansions used in brackets:

| Method | Budget 10 | Budget 25 | Budget 50 | Budget 100 | Budget 200 |
| --- | --- | --- | --- | --- | --- |
| ToT-BFS B=1 | 0 (10) | 2 (25) | 5 (39) | 10 (42) | 10 (42) |
| ToT-BFS B=2 | 0 (10) | 0 (25) | 3 (46) | 10 (61) | 10 (61) |
| ToT-BFS B=4 | 0 (10) | 0 (25) | 2 (50) | 7 (88) | 10 (98) |
| ToT-DFS | 0 (10) | 2 (25) | 5 (42) | 10 (53) | 11 (62) |

With about 30 children per node, breadth is expensive: BFS with B = 4 spends most of a 50-expansion budget on the first two layers. DFS matched the best beam at every budget and was the only method to solve 11/12 at 200 expansions, because it could backtrack into a sibling that a fixed beam had already discarded. BFS remains preferable when the value model ranks siblings reliably, when solutions sit at a shallow and similar depth, or when wall-clock latency matters, because a whole layer can be scored as one GPU batch. Each live beam also needs its own KV-cache, so memory grows with B, while DFS holds a single root-to-leaf stack.

Four starter defects were fixed and are covered by regression self-checks: the deepest node used to win over a solved goal at a shallower depth; DFS compared absolute rather than relative depth; re-using an expanded root duplicated its children; and invalid beam width, budget or threshold values were accepted.

## 4. Part 2: MCTS with PUCT selection

`MCTSNode` stores state, policy prior P(a|s), visit count N(s,a), cumulative reward W(s,a), parent and children, and a terminal flag. Q(s,a) = W/N when N > 0, otherwise 0.0, so unvisited nodes are ranked purely by their exploration bonus. `MCTSEngine.run_search` repeats select, expand, simulate and backpropagate, using:

```text
PUCT(s,a) = Q(s,a) + c_puct * P(a|s) * sqrt(N(s)) / (1 + N(s,a))
```

After expansion, the highest-prior child is simulated. Dead-end leaves are still scored by the rollout function instead of being given zero, and an optional `is_terminal_fn` marks solved nodes.

The starter trace at c_puct = 1.5 and N(s) = 16 gives Branch A (Q = 0.75, N = 5, P = 0.50) a PUCT of 1.25 and Branch B (Q = 0.55, N = 1, P = 0.40) a PUCT of 1.75. Branch B is selected: its lower reward is outweighed by its larger exploration bonus.

A sensitivity sweep compares a well-visited, high-reward branch A (Q = 0.80, N = 8, P = 0.35) with an under-visited branch B (Q = 0.50, N = 4, P = 0.65) at root N = 20. At c_puct = 0.5 the engine exploits A (0.887 vs 0.791); from c_puct = 1.0 upward it explores B. The crossover is at about c_puct = 0.74. A reliable PRM therefore justifies a lower c_puct, while a noisy evaluator needs a higher one to keep exploring.

In the 12-iteration navigation demo, the prograde frame-dragging slingshot received 8 visits (Q = 0.84) and the retrograde Penrose extraction 4 visits (Q = 0.65). The dangerous direct radial plunge, with prior 0.15, received no visits. The module's 12 self-checks all pass.

## 5. Part 3: Process reward evaluation

The instructor's marker-based fixture is kept: a `[FLAWED]` or `SIGN_ERROR` step scores 0.12, `[MINOR_DRIFT]` scores 0.55, and an unmarked step scores 0.94; a flaw takes precedence. Trajectories are reduced with the minimum, the product, or the geometric mean, computed in log space as exp(sum(log r) / T) to avoid underflow.

| Trajectory | ORM | PRM min | PRM prod | PRM geometric mean |
| --- | --- | --- | --- | --- |
| Instructor unmarked chain | 1.00 | 0.940 | 0.831 | 0.940 |
| Instructor sign trap | 1.00 | 0.120 | 0.106 | 0.473 |
| Valid algebra (x + 3 = 7 -> x = 4) | 1.00 | 0.940 | 0.831 | 0.940 |
| Two cancelling sign errors | 1.00 | 0.120 | 0.014 | 0.238 |

The outcome reward model only checks the final answer, so it gives 1.00 to a chain whose two sign errors cancel out. The PRM `min` reduction exposes the flawed step at 0.12. Over unmarked chains of 3, 10 and 100 steps, the minimum and geometric mean stay at 0.94 while the product falls to 0.831, 0.539 and 0.002, so the product penalises length even when step quality is constant. For 1,000 steps of 0.12, the product underflows to 0.0 while the log-space geometric mean correctly stays at 0.12.

Math-Shepherd labels are computed from supplied completions of a fixed step. With ground truth 24.0 km/s, the unmarked step gets 3 of 4 correct completions (soft label 0.75, hard label 1.0) and the trap step 1 of 4 (soft 0.25, hard 1.0). These are hand-specified fixtures, not sampled model outputs.

The evaluator is a rule-based surrogate: the flaw markers do the error detection, and the scores are not calibrated probabilities.

## 6. Part 4: Event horizon pruning and reward-hacking defense

`EventHorizonPruner` walks a trajectory step by step and severs it at the first step whose adjusted score falls below tau_horizon = 0.45. Before comparing, it penalises two reward-hacking patterns by multiplying the score by 0.20:

- Sycophantic filler: confident phrases such as "let us carefully verify this 100% rigorous step" that add no reasoning.
- Step-splitting inflation: repeated or redundant micro-steps intended to dilute a bad step under mean aggregation.

| Step | Original score | Finding | Adjusted score | Decision |
| --- | --- | --- | --- | --- |
| 1 | 0.93 | Clean | 0.93 | Retained |
| 2 | 0.96 | Sycophantic filler | 0.192 | Pruned |
| 3 | 0.10 | Not evaluated | n/a | Skipped |

The adversarial step 2 would have passed a naive check at 0.96. After the penalty it fell to 0.192, below the threshold, so the branch was cut at step 2, one step was skipped, and an estimated 15 tokens were saved (word and punctuation proxy). Tests also cover clean trajectories, repeated steps, empty trajectories, the threshold boundary, and invalid scores and configuration.

The detector uses rule-based pattern matching. It can miss paraphrased filler or semantically repeated steps, and it can penalise legitimate reasoning that happens to contain a flagged phrase. Pruning decisions are therefore not a guarantee of mathematical correctness.

## 7. Integrated outcomes and reflection

Recorded results across the four modules:

- ToT: goal reached with trajectory score 0.85 in 5 of 12 expansions; Game-of-24 solve rate rose from 0/12 at budget 10 to 11/12 at budget 200 for DFS.
- MCTS: PUCT starter values 1.25 and 1.75 reproduced; exploitation-to-exploration crossover at c_puct of about 0.74; dangerous plunge received zero visits.
- PRM: ORM false positive (1.00) caught by PRM min (0.12); geometric mean stable over 1,000 steps.
- Pruner: reward-hacked step penalised from 0.96 to 0.192 and severed at step 2.

Test-time compute lets a model with fixed weights solve problems beyond a single forward pass by generating candidate steps, scoring them, and choosing where to spend the next unit of compute. Search only helps if the signal guiding it can be trusted. An outcome-only verifier lets flawed branches survive and absorb budget, and step scores themselves can be gamed. Inference-time scaling is therefore only as reliable as its process verifier, which must handle both honest reasoning errors and deliberate reward hacking.

## 8. Verification and reproduction

Each module runs its own verification harness and self-checks when executed directly. The recorded run of all four modules passed: the ToT harness and 8 self-checks, the MCTS harness and 12 self-checks, the PRM reduction, marker-precedence and rollout boundary checks, and the pruner's verification and edge-case tests. The full terminal output is reproduced in Section 4 of `mission-07-doc.md`.

From the repository root:

```powershell
Set-Location .\mission-07
python .\tot_solver.py
python .\mcts_protocol.py
python .\prm_evaluator.py
python .\horizon_pruner.py
```

Run `python .\tot_solver.py --trace` to also print the step-by-step search trace. The Markdown report and its PDF contain the same report text.
