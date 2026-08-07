# Model routing (Claude Code)

Chair: Opus 5 at xhigh effort (session defaults via /model + /effort). Adaptive thinking scales down on routine turns, so xhigh is a ceiling, not a floor; drop the session to /effort high only if interactive latency becomes a problem. The chair drives AND implements — most sessions are small direct iterations, and cached chair re-reads (~$0.50/MTok) are cheaper than any cold subagent handoff, so doing the work in the main loop is usually both better and cheaper.

## Delegation gate

Spawn a subagent only when one of these holds; otherwise the work stays in the main loop:

- Implementation touching ≥3 files or ≥10 minutes of chair work, AND with a done-condition checkable by command (`tsgo`, `bun test`, lint) — `model: "sonnet"` for conventional/mechanical work, `model: "opus"` for a genuinely independent hard track. A sweep whose only verifier is the chair reading the diff is not worth delegating: verification would cost what doing it costs.
- Read-only scouting across ≥5 files whose contents the chair will NOT need in context afterward — `model: "haiku"` (grep-shaped) or `"sonnet"` (needs judgment). Scouts report facts with citations; they do not certify completeness or make design calls.

Rules: always pass `model` explicitly; max 3 concurrent implementers, each with `isolation: "worktree"` (the primary checkout is shared with other agents); verification stays in the main loop; every delegate prompt demands a deliverable contract back — assumptions, scope inspected, files touched, checks run, unresolved risks.

## Codex (gpt-5.6-sol high, via `codex exec` or the codex-rescue agent) — its value is independence, not rescue

Triggers:

1. Confident Claude-family consensus on a high-impact decision → ask Codex to falsify it, WITHOUT showing it the Claude rationale on the first pass (anchoring destroys the independence you're paying for).
2. Boundary-heavy correctness: lifecycle interleavings, tRPC contract evolution, Prisma migrations/backfills, authorization checks, analytics SQL grain.
3. First conceptual debugging failure — when observed behavior contradicts the working model, switch families immediately; when the patch was merely incomplete, stay with Opus.
4. Security review: the chair leads and implements; Codex gets a fresh threat-model + diff review.

Handoffs are batched, compact dossiers (goal and non-goals, constraints, exact diff, tests run, known uncertainties, plus "find counterexamples — do not redesign"). Cross-family calls share no prompt cache — never ping-pong small questions.

## Fable 5 — earned consultant, called not seated

Empirical note (2026-07-30, blind bake-off adjudicated by Codex against the code): Opus 5 clearly out-reviewed Fable 5 on a reactive-state diff — more verified unique catches, deeper data-flow tracing. Fable superiority is not assumed; its consults are narrow, upstream, and earned:

- Pre-implementation enumeration on high-reversal-cost or genuinely ambiguous designs: demand a bounded artifact (states × events × transitions, invariants, forbidden transitions, unresolved decisions) — never "think deeply about this". Pass absolute file paths and instruct it to read primary sources rather than trust the chair's framing; enumeration survives bad framing, verdicts don't.
- Adjudicating disagreements that rest on differing product or architecture assumptions (reveal the competing rationales only at this stage).
- Chairing long unattended autonomous runs (multi-hour migrations, overnight work) — a session-start decision, made by the user.

Never send security content to Fable (cyber-domain classifiers can refuse benign security work). Re-run a bake-off before widening its role.
