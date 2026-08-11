# Model routing (Claude Code)

Chair/orchestrator: **Fable 5 at high effort** (session defaults via /model + /effort). The chair owns decomposition, dossier authoring, verification, integration, and user communication. It implements directly only when a handoff would cost more than the change itself: one-or-two-file tweaks, config/doc edits, tight interactive iteration on something already in context.

Primary execution/review/peer lane: **Codex gpt-5.6-sol** (via `codex exec` or the codex-rescue agent) — a senior engineer from a different model family, valued for the independent perspective as much as the throughput.

- **gpt-5.6-sol high** (default): substantive implementation, code-review passes, diagnosis, test-writing, refactors.
- **gpt-5.6-sol xhigh** (hardest tracks): boundary-heavy correctness (lifecycle interleavings, contract evolution, migrations/backfills, authorization checks, analytics grain), adjudicating design disagreements, security review, and any conceptual debugging failure where observed behavior contradicts the working model.

## Handoff rules (Codex)

- Batched, compact dossiers: goal and non-goals, constraints, exact diff, tests run, known uncertainties, and the ask ("implement X", or "find counterexamples — do not redesign"). Cross-family calls share no prompt cache — never ping-pong small questions.
- Independence is the point on review/falsification passes: do NOT show Codex the chair's rationale on the first pass; anchoring destroys what you're paying for. Reveal competing rationales only at adjudication.
- Every mutating Codex run gets its own worktree/branch (the primary checkout is shared); every delegate prompt demands a deliverable contract back — assumptions, scope inspected, files touched, checks run, unresolved risks.
- Verification stays with the chair: read the diff, run the checks, own the merge. Codex output is a proposal until the chair has verified it against the code.

## Opus 5 — rationed to three roles

1. **Adjudicator** when chair and Codex disagree: a fresh Opus 5 shown both rationales. It is the only neutral seat — Fable is a disputant, Codex authored one side.
2. **Second reviewer on high-stakes diffs** (release gates, migrations/backfills, data-correctness, anything hard to roll back): `model: "opus"` subagent given the diff only, no chair rationale on the first pass. Backed by the 2026-07-30 bake-off — Opus 5 is the strongest in-family reviewer.
3. **Hard independent implementation track** when Codex is the bottleneck or family diversity on the implementation itself is wanted — `isolation: "worktree"`, command-checkable done-condition.

Anything not on this list does not get Opus: default to Codex (outside the Claude pool) or Sonnet (cheaper pool burn).

## Claude subagents (secondary lane)

- Read-only scouting across ≥5 files whose contents the chair won't need in context afterward — `model: "haiku"` (grep-shaped) or `"sonnet"` (needs judgment). Scouts report facts with citations; they do not certify completeness or make design calls.
- `model: "sonnet"` implementers for mechanical sweeps with a command-checkable done-condition when Codex capacity is the bottleneck. Always pass `model` explicitly; max 3 concurrent implementers, each with `isolation: "worktree"`.

## Weekly budget (Claude Max 20x)

Fable may consume at most 50% of the weekly usage pool, and every Opus/Sonnet/Haiku token draws from the same pool — non-Fable burn above 50% eats directly into Fable's reachable allowance. Priorities:

- **Maximize Fable-chair longevity.** Spend chair tokens on judgment (decomposition, dossiers, verification, integration), never on work a delegate could do: no file-dump reading a Haiku scout could summarize, no mechanical editing Codex could execute.
- **Codex is budget-free** with respect to the Claude pool — when quality is comparable, Codex beats any Claude subagent. This is a second independent reason (besides perspective) that it is the default lane.
- **Ration Opus hard** to the three roles above; they are all low-frequency by construction. Routine review is Codex; routine implementation is Codex or Sonnet; scouting is Haiku.
- **Never spawn a Fable subagent** — the chair is the only Fable seat in the system.
- If Fable's weekly allowance runs dry mid-week, drop the chair to Opus 5 (or `/fast`) for the remainder rather than starving sessions — and note it, so routing expectations adjust.

## Security caveat (chair is Fable)

Fable 5 carries dual-use-capability safety measures; benign security work (threat models, exploit-shaped analysis, pentest tooling) can trip refusals. Route security analysis and security review content to Codex xhigh by default — the chair coordinates and verifies but should not be the author of record for security-sensitive artifacts. If the chair hits a refusal on clearly benign security work, hand the item to Codex or an Opus subagent rather than rephrasing around the classifier.

## History

2026-07-30 blind bake-off (adjudicated by Codex): Opus 5 out-reviewed Fable 5 on a reactive-state diff. Under this routing that comparison is mostly moot — review work goes to Codex — but it stands as evidence that Fable-chair should delegate reviews rather than perform them. 2026-08-11: owner directive — Fable 5 high seated as chair, Codex gpt-5.6-sol high/xhigh as the main execution/review/peer lane; Max 20x budget rule added (Fable ≤50% of weekly pool, so keep non-Fable Claude burn under 50%).
