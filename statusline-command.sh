#!/bin/bash

# Claude Code status line — information-rich, multi-line.
# Docs: https://code.claude.com/docs/en/statusline#display-multiple-lines
# (each `printf ...\n` below produces one status-line row)
#
# Palette mirrors ~/.p10k.zsh: blue=dir, grey=secondary/labels, cyan=accents.
# green/yellow/red are reused for progress-bar/diff-stat severity.
#
# All stdin fields are parsed with a single jq call (TSV) to keep this fast;
# every optional field is guarded so absent data collapses cleanly instead of
# leaving dangling separators.

input=$(cat)

# Fields are joined with the \x1f unit separator, NOT @tsv: tab is IFS
# whitespace, so consecutive tabs from empty fields collapse under `read`
# and shift every later value. \x1f is non-whitespace and splits exactly.
# The jq program lives in a plain variable because bash 3.2 (macOS stock)
# cannot parse a multi-line quoted $() inside a here-string.
jq_prog='[
    (.workspace.current_dir // .cwd // ""),
    (.workspace.project_dir // ""),
    (.workspace.git_worktree // ""),
    (.worktree.name // ""),
    (.model.display_name // ""),
    (.model.id // ""),
    (.effort.level // ""),
    (if .thinking.enabled == true then "true" elif .thinking.enabled == false then "false" else "" end),
    (.output_style.name // ""),
    (.context_window.used_percentage // ""),
    (.context_window.total_input_tokens // ""),
    (.context_window.context_window_size // ""),
    (.cost.total_cost_usd // ""),
    (.cost.total_duration_ms // ""),
    (.cost.total_lines_added // ""),
    (.cost.total_lines_removed // ""),
    (.rate_limits.five_hour.used_percentage // ""),
    (.rate_limits.five_hour.resets_at // ""),
    (.rate_limits.seven_day.used_percentage // ""),
    (.rate_limits.seven_day.resets_at // ""),
    (.session_name // ""),
    (.version // ""),
    (.pr.number // ""),
    (.pr.url // ""),
    (.pr.review_state // ""),
    (.agent.name // ""),
    (.session_id // ""),
    (.transcript_path // "")
  ] | map(tostring | explode | map(if . < 32 or (. >= 127 and . <= 159) then 32 else . end) | implode) | join("\u001f")'

parsed=$(printf '%s' "$input" | jq -r "$jq_prog")

IFS=$'\x1f' read -r \
  cwd project_dir git_worktree worktree_name \
  model_name model_id effort_level thinking_enabled output_style \
  ctx_pct ctx_input ctx_size \
  cost_usd cost_ms lines_added lines_removed \
  five_pct five_reset seven_pct seven_reset \
  session_name cc_version \
  pr_number pr_url pr_state \
  agent_name session_id transcript_path \
  <<< "$parsed"

[ -z "$cwd" ] && cwd="$PWD"

# --- p10k-derived palette (256-color) ---
# Real ESC bytes ($'…'), output with printf '%s': dynamic values (branch,
# session, PR state…) must never pass through '%b', which would interpret
# any backslashes they contain.
blue=$'\033[38;5;4m'
grey=$'\033[38;5;242m'
cyan=$'\033[38;5;6m'
green=$'\033[38;5;2m'
yellow=$'\033[38;5;3m'
red=$'\033[38;5;1m'
reset=$'\033[0m'

# Join non-empty args with $1 as separator (skips empty segments so absent
# fields never leave a dangling separator behind).
join() {
  local sep="$1"; shift
  local out=""
  for p in "$@"; do
    [ -n "$p" ] || continue
    out="${out:+$out$sep}$p"
  done
  printf '%s' "$out"
}

# Render a token count as e.g. "87k" (rounded to the nearest thousand).
to_k() {
  local n="${1%.*}"
  [ -z "$n" ] && { printf '?'; return; }
  printf '%dk' $(( (n + 500) / 1000 ))
}

##############################################################################
# Line 1 — directory, project/worktree context, git branch + status
##############################################################################
# Per-session accent: hash session_id onto a palette of distinct hues so
# concurrent sessions are visually distinguishable at a glance. The badge
# leads line 1; the same hue tints the session name on line 4.
session_color=""
session_hue=""
if [ -n "$session_id" ]; then
  hues=(39 208 135 41 203 214 51 201)
  h=$(printf '%s' "$session_id" | cksum)
  h="${h%% *}"
  session_hue="${hues[h % 8]}"
  session_color=$'\033[38;5;'"${session_hue}"$'m'
fi

dir="${cwd/#$HOME/~}"
l1_parts=()
# Session badge: two uppercase words on the session-color background.
# - A short explicit /rename name (≤2 words) is honored VERBATIM — instant,
#   deterministic, and it's what the user typed. (Running Haiku on a thin
#   1-word name just invites hallucination, e.g. "statusline"→"STUBS UPNEXT".)
# - A longer name is condensed to two words by Haiku; an unnamed session is
#   inferred from the transcript. Those go through a detached Haiku call
#   (statusline must stay fast → async + cached in ~/.claude/statusline-tags/
#   <session_id>); a plain swatch shows until the tag lands.
tag=""
name_words=0
[ -n "$session_name" ] && name_words=$(printf '%s' "$session_name" | wc -w | tr -d ' ')

if [ -n "$session_name" ] && [ "$name_words" -le 2 ]; then
  tag=$(printf '%s' "$session_name" | awk '{printf "%s", $1; if ($2 != "") printf " %s", $2}')
  tag=$(printf '%.21s' "$tag" | tr '[:lower:]' '[:upper:]')
elif [ -n "$session_id" ]; then
  tag_dir="$HOME/.claude/statusline-tags"
  tag_file="$tag_dir/$session_id"
  # Cache line 2 records the source (so a /rename invalidates it): "t" for the
  # transcript, "n<cksum>" for a long session_name.
  if [ -n "$session_name" ]; then
    src="$session_name"
    nk=$(printf '%s' "$session_name" | cksum); want_key="n${nk%% *}"
  else
    want_key="t"; src=""
    if [ -n "$transcript_path" ] && [ -s "$transcript_path" ]; then
      # First real user text in the transcript (first ~80 lines is plenty).
      src=$(head -80 "$transcript_path" 2>/dev/null | jq -r '
        select(.type == "user") | .message.content
        | if type == "string" then .
          else ([.[]? | select(.type == "text") | .text] | join(" ")) end
      ' 2>/dev/null | grep -m1 -v '^[[:space:]]*$' | cut -c1-600)
    fi
  fi
  if [ -s "$tag_file" ] && [ "$(sed -n 2p "$tag_file")" = "$want_key" ]; then
    tag=$(sed -n 1p "$tag_file" | tr -cd 'A-Z0-9 ' | tr -s ' ')
    tag="${tag:0:21}"
  else
    # A pending marker older than 5 min is an orphan from a killed job —
    # clear it so derivation can retry instead of being blocked forever.
    if [ -e "$tag_file.pending" ] && [ -n "$(find "$tag_file.pending" -mmin +5 2>/dev/null)" ]; then
      rm -f "$tag_file.pending"
    fi
    if [ -n "$src" ] && [ ! -e "$tag_file.pending" ]; then
      mkdir -p "$tag_dir"
      : > "$tag_file.pending"
      (
        # env -u: strip Claude Code's nesting markers so the child CLI's
        # nested-launch protection never rejects the call.
        word=$(env -u CLAUDECODE -u CLAUDE_CODE_ENTRYPOINT claude -p --model haiku "Below is the opening of a coding session. Reply with exactly two uppercase English words, each 3-10 letters, that best label what the session is about (like ICON PICKER or CALENDAR SYNC). Only the two words separated by one space, no punctuation.

---
$src" 2>/dev/null | tr -cd 'A-Za-z0-9 ' | tr '[:lower:]' '[:upper:]' | tr -s ' ')
        word="${word# }"; word="${word% }"
        word=$(printf '%s' "$word" | awk '{printf "%s", $1; if ($2 != "") printf " %s", $2}')
        word="${word:0:21}"
        # On failure fall back to the source's first two words so a broken
        # CLI never causes a re-derivation loop.
        [ -z "$word" ] && word=$(printf '%s' "$src" | tr -cd 'A-Za-z0-9 ' | tr '[:lower:]' '[:upper:]' | awk '{printf "%s", $1; if ($2 != "") printf " %s", $2}' | cut -c1-21)
        [ -n "$word" ] && printf '%s\n%s' "$word" "$want_key" > "$tag_file"
        rm -f "$tag_file.pending"
      ) >/dev/null 2>&1 </dev/null &
    fi
  fi
fi

# Mirror the two-word tag onto THIS session's cmux TAB (surface) title so
# concurrent sessions are tellable apart in the tab list. Defined here,
# invoked at the very end (after the status line is printed) so it never
# delays the visible output. Runs SYNCHRONOUSLY, not backgrounded: a detached
# `cmux` loses its socket when the parent exits ("Broken pipe"), so the call
# must complete while this script is still alive.
#
# The launch-time cmux env vars (CMUX_TAB_ID / CMUX_SURFACE_ID /
# CMUX_WORKSPACE_ID) go STALE when a surface is recreated (reconnect/restore)
# and `cmux identify` trusts them — so they point at the wrong tab. The only
# reliable key is the live controlling tty of the claude process: walk the
# process ancestry to it, then map tty -> (workspace, surface) via the tree.
cmux_set_tab_title() {
  [ -n "$tag" ] && [ -n "$session_id" ] || return 0
  [ -n "${CMUX_SOCKET_PATH}${CMUX_PANEL_ID}${CMUX_WORKSPACE_ID}${CMUX_BUNDLE_ID}" ] || \
    [ "$TERM_PROGRAM" = "ghostty" ] || return 0
  local cmux_bin marker sess_tty pp ap at ws sf
  cmux_bin="${CMUX_CLAUDE_HOOK_CMUX_BIN:-${CMUX_BUNDLED_CLI_PATH:-cmux}}"
  marker="$HOME/.claude/statusline-tags/$session_id.tabtitle"
  # Marker-guarded: only touch cmux when the tag actually changes (rare).
  [ "$(cat "$marker" 2>/dev/null)" = "$tag" ] && return 0
  command -v "$cmux_bin" >/dev/null 2>&1 || return 0
  mkdir -p "$HOME/.claude/statusline-tags"

  # Controlling tty = first ancestor with a real tty (claude / login shell).
  sess_tty=""; pp=$$
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    set -- $(ps -o ppid=,tty= -p "$pp" 2>/dev/null); ap="$1"; at="$2"
    case "$at" in ttys*|tty[0-9]*|pts/*) sess_tty="$at"; break ;; esac
    [ -z "$ap" ] && break
    [ "$ap" -le 1 ] 2>/dev/null && break
    pp="$ap"
  done
  [ -n "$sess_tty" ] || return 0

  # Map tty -> "<workspace ref>\t<surface ref>". cmux's own Claude hooks
  # (stop/feed/auto-name) share the socket around each turn, so retry.
  ws=""; sf=""
  for _ in 1 2 3; do
    read -r ws sf <<<"$("$cmux_bin" tree --all --json 2>/dev/null | jq -r --arg t "$sess_tty" '
      .windows[].workspaces[] as $w | $w.panes[].surfaces[]
      | select(.tty == $t) | "\($w.ref)\t\(.ref)"' 2>/dev/null | head -1)"
    [ -n "$sf" ] && break
    sleep 0.4
  done
  [ -n "$sf" ] || return 0

  for _ in 1 2 3; do
    if CMUX_QUIET=1 "$cmux_bin" rename-tab --workspace "$ws" --tab "$sf" "$tag" >/dev/null 2>&1; then
      # Record success only after it lands, so a failure retries next refresh.
      printf '%s' "$tag" > "$marker"
      printf 'tty=%s ws=%s sf=%s tag=%s rc=ok\n' "$sess_tty" "$ws" "$sf" "$tag" \
        > "$HOME/.claude/statusline-tags/cmux-debug.log" 2>/dev/null
      return 0
    fi
    sleep 0.4
  done
  printf 'tty=%s ws=%s sf=%s tag=%s rc=fail\n' "$sess_tty" "$ws" "$sf" "$tag" \
    > "$HOME/.claude/statusline-tags/cmux-debug.log" 2>/dev/null
  return 0
}

if [ -n "$session_color" ]; then
  if [ -n "$tag" ]; then
    l1_parts+=($'\033[48;5;'"${session_hue}"$'m\033[38;5;16m'" ${tag} ${reset}")
  else
    l1_parts+=("${session_color}▐█▌${reset}")
  fi
fi

# Model + effort, bold in a per-model color, right after the session chip.
if [ -n "$model_name" ]; then
  model_lc=$(printf '%s' "${model_id:-$model_name}" | tr '[:upper:]' '[:lower:]')
  case "$model_lc" in
    *fable*|*mythos*) model_color=$'\033[1;38;5;135m' ;;  # purple
    *opus*)           model_color=$'\033[1;38;5;208m' ;;  # orange
    *sonnet*)         model_color=$'\033[1;38;5;39m'  ;;  # blue
    *haiku*)          model_color=$'\033[1;38;5;41m'  ;;  # green
    *)                model_color=$'\033[1m'          ;;  # bold only
  esac
  model_label="$model_name"
  if [ -n "$effort_level" ]; then
    eff=$(printf '%s' "$effort_level" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')
    model_label="${model_label} (${eff})"
  fi
  # Fable at xhigh/max burns scarce quota fast — flag it loudly.
  case "$model_lc|$effort_level" in
    *fable*"|xhigh"|*fable*"|max"|*mythos*"|xhigh"|*mythos*"|max")
      model_color=$'\033[1;38;5;196m'
      model_label="⚠ ${model_label} ⚠"
      ;;
  esac
  l1_parts+=("${model_color}${model_label}${reset}")
fi

l1_parts+=("${blue}${dir}${reset}")

if [ -n "$project_dir" ] && [ "$project_dir" != "$cwd" ]; then
  l1_parts+=("${grey}proj:${project_dir/#$HOME/~}${reset}")
fi

wt="${worktree_name:-$git_worktree}"
[ -n "$wt" ] && l1_parts+=("${cyan}⎇ ${wt}${reset}")

# Single git call (porcelain v2 + branch) gets branch name, ahead/behind
# counts, and staged/modified/untracked counts together in one subprocess.
git_status=$(git -C "$cwd" --no-optional-locks status --porcelain=2 --branch 2>/dev/null)

if [ -n "$git_status" ]; then
  branch=""
  ahead=0
  behind=0
  staged=0
  modified=0
  untracked=0

  while IFS= read -r line; do
    case "$line" in
      "# branch.head "*)
        branch="${line#\# branch.head }"
        ;;
      "# branch.ab "*)
        ab="${line#\# branch.ab }"
        ahead="${ab%% *}"; ahead="${ahead#+}"
        behind="${ab##* }"; behind="${behind#-}"
        ;;
      "#"*) ;;
      1\ *|2\ *)
        xy="${line:2:2}"
        [ "${xy:0:1}" != "." ] && staged=$((staged + 1))
        [ "${xy:1:1}" != "." ] && modified=$((modified + 1))
        ;;
      "u "*)
        staged=$((staged + 1)); modified=$((modified + 1))
        ;;
      "? "*)
        untracked=$((untracked + 1))
        ;;
      *) ;;
    esac
  done <<< "$git_status"

  # Detached HEAD: show @commit, matching POWERLEVEL9K_VCS_COMMIT_ICON='@'.
  if [ "$branch" = "(detached)" ]; then
    branch="@$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)"
  fi

  if [ -n "$branch" ]; then
    # Branch in white; underlined when it's not main so being off the
    # default branch is impossible to miss.
    branch_style=$'\033[38;5;15m'
    [ "$branch" != "main" ] && branch_style=$'\033[38;5;15;4m'
    vcs="${branch_style}${branch}${reset}${grey}"
    dirty_total=$((staged + modified + untracked))
    [ "$dirty_total" -gt 0 ] && vcs="${vcs}*"

    arrows=""
    [ "$behind" -gt 0 ] && arrows="⇣"
    [ "$ahead" -gt 0 ] && arrows="${arrows}⇡"
    [ -n "$arrows" ] && vcs="${vcs}${cyan}${arrows}${reset}${grey}"

    count_parts=()
    [ "$staged" -gt 0 ] && count_parts+=("+${staged}")
    [ "$modified" -gt 0 ] && count_parts+=("~${modified}")
    [ "$untracked" -gt 0 ] && count_parts+=("?${untracked}")
    counts=$(join " " "${count_parts[@]}")
    [ -n "$counts" ] && vcs="${vcs} ${counts}"

    l1_parts+=("${grey}${vcs}${reset}")
  fi
fi

line1=$(join "  " "${l1_parts[@]}")

##############################################################################
# Line 2 — context usage bar + tokens, cost, duration, lines changed
##############################################################################
pct="$ctx_pct"
[ -z "$pct" ] && pct=0
pct=$(printf '%.0f' "$pct" 2>/dev/null); [ -z "$pct" ] && pct=0

if [ "$pct" -lt 70 ]; then
  bar_color=$green
elif [ "$pct" -lt 90 ]; then
  bar_color=$yellow
else
  bar_color=$red
fi

bar_width=10
filled=$((pct * bar_width / 100))
[ "$filled" -gt "$bar_width" ] && filled=$bar_width
[ "$filled" -lt 0 ] && filled=0
empty=$((bar_width - filled))

bar="["
for ((i = 0; i < filled; i++)); do bar+="█"; done
for ((i = 0; i < empty; i++)); do bar+="░"; done
bar+="]"

l3_parts=("${bar_color}${bar} ${pct}%${reset}")

if [ -n "$ctx_input" ] && [ -n "$ctx_size" ]; then
  l3_parts+=("${grey}$(to_k "$ctx_input")/$(to_k "$ctx_size")${reset}")
fi

if [ -n "$cost_usd" ]; then
  cost_fmt=$(printf '%.2f' "$cost_usd" 2>/dev/null)
  [ -n "$cost_fmt" ] && l3_parts+=("${grey}\$${cost_fmt}${reset}")
fi

if [ -n "$cost_ms" ]; then
  ms_int="${cost_ms%.*}"
  if [ -n "$ms_int" ]; then
    total_sec=$((ms_int / 1000))
    mins=$((total_sec / 60))
    secs=$((total_sec % 60))
    l3_parts+=("${grey}${mins}m${secs}s${reset}")
  fi
fi

diff_parts=()
[ -n "$lines_added" ] && diff_parts+=("${green}+${lines_added}${reset}")
[ -n "$lines_removed" ] && diff_parts+=("${red}-${lines_removed}${reset}")
[ "${#diff_parts[@]}" -gt 0 ] && l3_parts+=("$(join " " "${diff_parts[@]}")")

line3=$(join "  " "${l3_parts[@]}")

##############################################################################
# Line 4 — rate limits, session name, PR
##############################################################################
l4_parts=()

_fmt_epoch() { date -r "$1" +%H:%M 2>/dev/null || date -d "@$1" +%H:%M 2>/dev/null; }
rl_parts=()
if [ -n "$five_pct" ]; then
  five_fmt=$(printf '%.0f' "$five_pct" 2>/dev/null)
  five_time=""
  if [ -n "$five_reset" ]; then
    ft=$(_fmt_epoch "${five_reset%.*}")
    [ -n "$ft" ] && five_time=" (resets ${ft})"
  fi
  [ -n "$five_fmt" ] && rl_parts+=("5h:${five_fmt}%${five_time}")
fi
if [ -n "$seven_pct" ]; then
  seven_fmt=$(printf '%.0f' "$seven_pct" 2>/dev/null)
  seven_time=""
  if [ -n "$seven_reset" ]; then
    st=$(_fmt_epoch "${seven_reset%.*}")
    [ -n "$st" ] && seven_time=" (resets ${st})"
  fi
  [ -n "$seven_fmt" ] && rl_parts+=("7d:${seven_fmt}%${seven_time}")
fi
[ "${#rl_parts[@]}" -gt 0 ] && l4_parts+=("${cyan}$(join " · " "${rl_parts[@]}")${reset}")

if [ -n "$session_name" ]; then
  l4_parts+=("${grey}session:${session_color:-$grey}${session_name}${reset}")
fi

if [ -n "$pr_number" ]; then
  pr_label="PR #${pr_number}"
  [ -n "$pr_state" ] && pr_label="${pr_label} (${pr_state})"
  if [ -n "$pr_url" ]; then
    # OSC 8 hyperlink so the PR badge is clickable in supporting terminals.
    pr_label=$'\033]8;;'"$pr_url"$'\a'"$pr_label"$'\033]8;;\a'
  fi
  l4_parts+=("${cyan}${pr_label}${reset}")
fi

line4=$(join "  ·  " "${l4_parts[@]}")

##############################################################################
# Output — one printf per row; empty rows are omitted entirely.
##############################################################################
[ -n "$line1" ] && printf '%s\n' "$line1"
[ -n "$line3" ] && printf '%s\n' "$line3"
[ -n "$line4" ] && printf '%s\n' "$line4"

# Push the cmux tab title AFTER the status line is printed — this can take a
# few hundred ms on a tag change (rare), and doing it last keeps that off the
# visible-render path.
cmux_set_tab_title

# An empty optional line above must not surface as a non-zero exit —
# Claude Code blanks the status line when the script fails.
exit 0
