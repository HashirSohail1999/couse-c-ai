# Mission 06: Solution Report

**Contributors:** Syed Hashir Sohail, Yasan Malik, Usman tariq qureshi, Sufyan Khalid

**Group:** sustkever (Group 17)

**Course:** Conversational AI, Winter Semester 2026/27
**Prepared:** 16 November 2026

## 1. Objective and scope

Mission 06 restores AURA's Autonomous Warp State Machine and Deliberation Loop in the Eta Carinae scenario. The solution replaces impulsive repeated actions with a deterministic execution graph, validated tool calls, trajectory evaluation, and an emergency cycle breaker. All runtime components use Python's standard library.

This report covers the briefing, final implementations, starter variants, integrated notebook, and separate Part 3 notebook. Results below were verified locally on 16 November 2026. The nebula environment, sensor outputs, jump records, and rewards are simulations; they do not establish safety for a physical navigation system.

The notebook's station mapping is:

- Syed Hashir Sohail: Systems Architect, state machine.
- Yasan Malik: Communications & Protocol Officer, tool dispatcher.
- Usman tariq qureshi: Data & Payload Specialist, trajectory logger and sentinel module.
- Sufyan Khalid: Security & Ethics Sentinel, integrated warp pilot and safety decisions.

The mission is credited to all four contributors. Existing AI-assistance disclosures remain in the source files; independent human-review sign-offs are not inferred from passing checks.

## 2. Deliverables and execution flow

- `01_Agent_State_Machine.py`: seven-state agent, transition graph, budget, history, and self-tests.
- `02_Tool_Protocol_Dispatcher.py`: three tools, argument contracts, safe dispatch, and 19 protocol checks.
- `03_MDP_Trajectory_Logger.py`: trajectories, discounted returns, empirical transition probabilities, CSV loading, and checks.
- `03_Infinite_Loop_Sentinel.py`: state-action hashes, consecutive repetition detection, Floyd cycle analysis, and emergency reports.
- `04_System2_Warp_Pilot.py`: safety deliberation, module integration, mission simulation, and integration tests.
- `ps06_solution.ipynb`: complete walkthrough, escape and anomaly demonstrations, four required master suites, and per-module suites.
- `ps06_part3_data_payload.ipynb`: detailed trajectory, return, transition-matrix, and sentinel examples.
- `*_starter.py`: earlier teaching variants. Final `.py` files are the primary implementations.

The integrated pilot advances the agent to DELIBERATING, evaluates a proposed action, checks its state-action history, advances to ACTING, and dispatches an approved or corrected tool request. It stores the decision and resulting observation, logs the reward and next environment state, then advances through OBSERVING and REFLECTING. A successful warp completes the mission; a budget limit or security tripwire forces HALTED.

The briefing assigns cycle detection to the Security & Ethics role, while the README and starter filenames place its module under Part 3. The final pilot imports that module, so both trajectory evaluation and cycle detection are present despite the different role labels.

## 3. Part 1: Deterministic agent state machine

`AgentState` contains exactly IDLE, PERCEIVING, DELIBERATING, ACTING, OBSERVING, REFLECTING, and HALTED. The `Agent` dataclass stores current state, transition count, maximum budget, memory, completion status, halt reason, and transition history. Mutable histories are allocated independently for each agent.

The transition graph is:

```text
IDLE -> PERCEIVING -> DELIBERATING -> ACTING
     -> OBSERVING -> REFLECTING
REFLECTING -> DELIBERATING, or HALTED when mission_completed
HALTED -> terminal
```

Each ordinary `step()` call performs one graph transition. The budget accepts only integers from 1 through 20, excluding booleans. Once N transitions have been consumed, the next call halts without increasing `step_count`. With N=20, a never-completing agent therefore performs 20 transitions and halts on call 21. Further calls on HALTED change nothing.

Perception input is retained in memory. Normal completion records its reason, and the public state field supports the pilot's emergency halt. The self-tests verify the exact enum and graph, reflection looping and completion, one transition per call, terminal behavior, budget enforcement and validation, independent instance histories, and external forced halting.

## 4. Part 2: Tool protocol and error boundary

The dispatcher exposes `navigate_warp_vector(x, y, z)`, `adjust_plasma_shields(intensity)`, and `query_sensor_array(target)`. Navigation returns formatted vector coordinates; shield adjustment enforces integer intensity from 0 to 100; the sensor function returns canned scenario observations.

`ActionDispatcher` accepts a dictionary or a JSON string decoding to an object. It rejects unknown tools, missing required arguments, extra arguments, incorrect primitive types, boolean values masquerading as numbers, and non-finite numeric coordinates. This is a small validator for the contracts used here, rather than a complete general-purpose JSON Schema implementation.

Validation and tool execution share an exception boundary. Success returns an `Observation:` string. Failure returns a `Tool Execution Error:` string that the caller can retain in context. For example, negative shield intensity becomes a caught ValueError observation; malformed JSON becomes a JSONDecodeError observation. The process continues so the next deliberation can respond to the failure.

All 19 dispatcher checks pass locally, including valid requests and invalid payload cases.

## 5. Part 3: Trajectory logging and empirical returns

`TrajectoryLogger.start_episode(s0)` opens an episode. Each `log_step(action, reward, next_state)` records one transition, and `end_episode()` freezes the result into a `Trajectory`. For T actions, a valid trajectory has T rewards and T+1 states. The logger rejects invalid episode ordering and non-finite rewards.

The evaluator computes:

```text
G_0 = sum(gamma^t * reward_t), gamma = 0.95
G_t = reward_t + gamma * G_(t+1)
```

Backward accumulation avoids repeatedly calculating powers. For the briefing's rewards `[10, 0, -5, 20]`:

```text
G_0 = 10 + 0.95^2 * (-5) + 0.95^3 * 20 = 22.635
Returns to go = [22.635, 13.3, 14.0, 20.0]
```

`TransitionModel` estimates `P(next_state | state, action)` by dividing each transition count by the total count for its state-action pair. Every observed row sums to one. An unobserved pair has no estimate and raises KeyError instead of being assigned zero probability.

The repository has no supplied historical jump CSV. Its 56-jump `JUMP_LOG` is explicitly a hand-written mock. Example estimates are 0.60 for reaching escape_corridor from dust_lane with warp_high_shields, and 0.80 for hull_breach from plasma_shear with warp_low_shields. These are arithmetic demonstrations, not measured astronomical probabilities. A real CSV can be loaded with columns `state,action,next_state`.

The separate Part 3 notebook also compares illustrative reflex and deliberate episodes. At gamma=0.95 their returns are -85.25 and 87.3975; these depend on their chosen rewards and differ from the integrated pilot's escape reward sequence.

## 6. Cycle detection and emergency tripwire

The sentinel hashes serialized state, action, and arguments with SHA-256. Sorted JSON keys make dictionary order irrelevant; including environment state helps distinguish the same action in different situations. A counter provides expected constant-time duplicate lookup after serialization and hashing.

The simple `check_loop()` interface detects consecutive identical steps. The extended `observe()` additionally reconstructs a deterministic successor relation and applies Floyd's tortoise and hare algorithm. Its report includes the hash, consecutive count, total visits, cycle start and length, tripwire flag, and reason.

The breaker fires on three identical consecutive steps, or on a detected deterministic cycle when the current state-action has appeared three times. For `[s1, s2, s3, s1, s2, s3, ...]`, the cycle starts at index 0, has length 3, and triggers at attempt 7. The integrated caller forces HALTED and records a critical `SECURITY VIOLATION`.

Floyd's algorithm assumes a deterministic successor relation. If the observed history gives one state-action different successors, this branch declines a cycle verdict; the consecutive-repeat rule remains available. The implementation stores history and rebuilds its successor map, so the overall monitoring cost is not constant memory or constant time per observation. Only the duplicate counter lookup has that expected complexity.

Sentinel checks cover stable hashes, argument and state changes, consecutive repeats, 300 random deterministic trajectories checked against a reference detector, the required three-state cycle, non-looping histories, critical logging, and halting the actual Part 1 agent.

## 7. Part 4: System 2 safety and integrated outcomes

`System2DeliberationEngine` rejects unauthorized actions and invalid shield values, raises low shield requests to the 60% safety margin, and blocks warp until shields are ready and the escape corridor has been scanned. Corrections preserve the caller's original argument dictionary. Successful observations update the engine's knowledge of shields and the corridor.

The escape plan scans the corridor, raises shields, then navigates along `[-0.85, 0.52, 0.05]`. Verified results are:

- Final agent state: HALTED, with mission_completed=True.
- State transitions: 14 of the permitted 20.
- Tool observations and logged trajectory actions: 3.
- Rewards: `[-1.0, -1.0, 20.0]`; discounted return: 16.1.
- Security violations: none.

The anomaly demonstration feeds repeated mock state-actions to the sentinel. It halts at attempt 7, before the required step-10 threshold, and retains the violation. Anomaly attempts are sentinel observations; they should not be confused with the successful mission's state-transition count.

The policy is deterministic and uses simulated tools; there is no remote LLM or external ship-control connection. The tests establish the demonstrated software behavior within this environment.

## 8. Verification and reproduction

All five final Python modules ran successfully in the available Python 3.15 environment. Every code cell in `ps06_solution.ipynb` was also executed in order in a fresh Python namespace. Its four required master suites passed: state-machine termination, safe protocol errors, the 22.635 return, and cycle-triggered halting before step 10. The notebook's additional per-part suites passed as well.

The notebook was validated by executing its Python cell sources; saved outputs were preserved. This checks the code path without claiming a fresh Jupyter-kernel run or independently signed human review. Logged critical violations in the anomaly tests are expected test outcomes.

From the repository root:

```powershell
Set-Location .\mission-06
python .\01_Agent_State_Machine.py
python .\02_Tool_Protocol_Dispatcher.py
python .\03_MDP_Trajectory_Logger.py
python .\03_Infinite_Loop_Sentinel.py
python .\04_System2_Warp_Pilot.py
```

Open `ps06_solution.ipynb` in a Python Jupyter environment and run all cells for the integrated walkthrough. To use a real jump history, run the logger with `--jumps path_to_jumps.csv`. The Markdown report and its PDF contain the same report text.
