# Global agent context (shared)

Canonical shared instructions for every coding agent (Claude Code, Codex, Antigravity, …).
Tools reach this file via their native entry point:
- Codex: `~/.codex/AGENTS.md` → symlink to this file.
- Claude Code: `~/.claude/CLAUDE.md` → `@` imports this file (Claude-only content stays in CLAUDE.md).

Put only *universal* rules here. Tool-specific orchestration (e.g. Claude's model-routing
table, codex-plugin mechanics) stays in that tool's own file.

## Branch discipline: never switch the checked-out branch

I often have multiple agents working out of the same checkout. Switching branches (`git checkout <branch>`, `git switch`, or anything else that changes which branch the working directory has checked out) yanks the files out from under every other agent mid-task. So:

- **Always work on whatever branch the current working directory already has checked out.** Commit to it directly if that fits the task.
- **If the work needs isolation or a different branch, use a worktree** (`git worktree add`; in Claude Code, EnterWorktree / `isolation: "worktree"`) — never repoint the primary checkout.
- This applies to subagents too: pass the same rule along when delegating anything that touches git.
- Detaching HEAD, `git checkout <ref> -- <path>` restores into the working tree, and hard resets have the same clobbering effect — treat them the same way unless I explicitly ask.
- **Stage by explicit path.** Never `git add -A`, `git add .`, `git add -u`, or `git commit -a` in the shared checkout — the tree may contain other agents' in-flight work, and a blanket stage sweeps it into your commit. List the files you actually changed.
- **Never `git stash`, `git clean`, or blanket `git restore`/`git checkout .`** in the shared checkout — those destroy or hide other agents' uncommitted work. If you need a clean tree, that's what a worktree is for.

## Secrets

Secrets live in 1Password Environments and get injected at runtime: `op run --environment <envId> -- <cmd>`. Never write a secret into any file inside a repo — **including gitignored ones** (a gitignored `.dev.vars` once shipped as a publicly served deploy asset). Never echo/print secret values into logs, commit messages, or tool output; reference them by env var name.
