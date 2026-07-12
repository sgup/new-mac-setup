<!-- Shared universal rules (branch discipline, secrets) live in the canonical
     agent-context file (dotfiles repo), also read by Codex via ~/.codex/AGENTS.md. Edit there. -->
@~/.dotfiles/AGENTS.md

## Picking the right models for workflows and subagents

Rankings, higher = better on every axis. Affordability reflects what I actually pay, not list price — higher = cheaper for me (OpenAI's generous limits make gpt-5.6-sol near-free; Fable is the scarce/expensive one). Intelligence is how hard a problem you can hand the model unsupervised. Taste covers UI/UX, code quality, API design, and copy.

| model       | affordability | intelligence | taste |
|-------------|---------------|--------------|-------|
| gpt-5.6-sol | 9             | 8            | 5     |
| opus-4.8    | 4             | 8            | 8     |
| fable-5     | 2             | 9            | 9     |

Play each model to its strength:

- **gpt-5.6-sol is the default workhorse — usage is basically free, so use it liberally and in volume.** Route anything with a clear spec or objective correctness criterion to it first: implementation against a plan, debugging loops, migrations, data analysis, test writing, research/exploration, log spelunking. The `~/.codex/config.toml` default is **medium reasoning effort**: a 2026-07-10 bake-off had 5.6-sol@low already matching opus-4.8@xhigh on subtle-bug hunts (strict-weak-ordering sort bug, swallowed-CancellationError race) in 11–24s/run, so medium clears the bar for most delegated work with headroom. Bump per-call to `-c model_reasoning_effort="high"` for the hardest problems; drop to `low` for cheap mechanical passes. Free usage changes the playbook — don't ration it:
  - Fire off Codex `--background` jobs for long loops instead of holding the main session on them.
  - When a problem is gnarly, run 2–3 independent Codex attempts/diagnoses in parallel and keep the best, rather than one careful attempt.
  - Add a Codex review pass to essentially everything (it's read-only and free); its taste is mediocre, so treat its style opinions as advisory, its bug reports as signal.
- **fable-5 is scarce — spend it on judgment, not tokens.** In a Fable session, Fable's job is orchestration, decomposition, final integration, and the calls that need the best taste+intelligence: architecture decisions, user-facing polish that ships, resolving disagreement between delegated results, and the rare problem too hard to hand off. If Fable is producing bulk implementation tokens, the routing is wrong. Caveat for Fable *subagents* in automated pipelines: it can leak conversational meta-commentary into output that must be machine-consumable — state the output contract hard ("final message is ONLY X").
- **opus-4.8 is the delegated middle: taste-critical work that can't go to Codex.** Use it for delegated UI/copy/API-design work (taste ≥ 7 bar), plan/code reviews, and anything needing Claude-native tooling — Workflow `agent()` phases, worktree isolation, multi-file edits inside this harness — where the Codex plugin's shape doesn't fit.
- Anything user-facing (UI, copy, API design) needs taste ≥ 7 — so gpt-5.6-sol can draft it, but opus-4.8/fable-5 must shape or rewrite it before it ships.
- Reviews of plans/implementations: fable-5 or opus-4.8 for the tasteful pass, plus gpt-5.6-sol as a free extra independent perspective (reviews are read-only, so Codex works fine for them).
- These are defaults, not limits. You have standing permission to override them: if a cheaper model's output doesn't meet the bar, rerun or redo the work with a smarter model without asking. Judge the output, not the price tag. Escalating costs less than shipping mediocre work. When axes conflict for anything that ships, intelligence > taste > affordability.
- Never use Haiku. Never use Sonnet 5 either — it burns usage too fast for what it delivers (removed from the table on purpose; don't re-route to it as a "cheap middle option").
- Subagents and Workflow `agent()` phases inherit the session model unless you pass `model` explicitly. When the main session is fable-5, always set `model` on delegated work so bulk doesn't silently burn Fable quota — gpt-5.6-sol for mechanical, opus-4.8 for everything else delegated.

Mechanics: gpt-5.6-sol is handled natively via the `codex` plugin (openai-codex marketplace) inside Claude Code, which adopts my user-level configuration from `~/.codex/config.toml`. Avoid writing custom bash wrappers; use the plugin's built-in commands and skills:
- `/codex:review` — non-destructive, read-only code-quality assessment. Supports `--base <ref>` for branch analysis and `--scope auto|working-tree|branch`.
- `/codex:adversarial-review` — skeptical design review that pressure-tests tradeoffs, auth, and reliability. Append focus text at the end to steer it.
- `/codex:rescue` — subcontract active debugging, multi-file refactoring, or implementation loops to Codex when a second pass is needed. (A 2026-07-08 read-only-sandbox regression blocked writes; config was fixed same day and a write probe passed — if patches start getting rejected with "writing is blocked by read-only sandbox" again, check `~/.codex/config.toml` sandbox/approval settings.)
- `/codex:status` / `/codex:result` / `/codex:cancel` — check, fetch, or abort async jobs when running heavy tasks with `--background`.

Claude models (opus-4.8, fable-5) run via the Agent/Workflow `model` parameter.

Using gpt-5.6-sol inside workflows and subagents:
- Subagents and automated workflows should call the plugin's native slash commands or its exposed `codex-cli-runtime` skill to delegate directly, rather than raw terminal wrappers.
- Do NOT pair the `codex:codex-rescue` agent type with `isolation: "worktree"`: the rescue agent is a fire-and-forget forwarder that exits as soon as the background Codex job launches, and an unchanged worktree is garbage-collected at agent exit — deleting the directory out from under the still-running job. Wrap the Codex call in a `general-purpose` agent that stays alive until the job completes (poll `codex-companion.mjs status` from the worktree cwd, then fetch `result`).
- For closed-loop quality assurance, keep the review gate on via `/codex:setup --enable-review-gate`. This installs a stop hook that automatically challenges my outputs with Codex before finalizing, keeping broken code or weak design assumptions from reaching the main session unvetted.
