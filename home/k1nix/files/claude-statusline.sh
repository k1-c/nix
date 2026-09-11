#!/bin/bash
# Claude Code Enhanced Status Line
# Line 1: Repo | Branch | Linear issue  (OSC 8 hyperlinks — clickable)
# Line 2: Model | Context | In/Out | Remaining | ETA | Compression
# Line 3: Rate limits (5h session / 7d week) — same data as /usage
#
# CLAUDE_STATUSLINE_LINKS=0 disables the hyperlinks (plain text),
# CLAUDE_STATUSLINE_LINKS=1 forces them on for a terminal not in the allowlist.

CLAUDE_DIR="$HOME/.claude"
SESSION_FILE="$CLAUDE_DIR/.sl_session.json"
LAST_STATE_FILE="$CLAUDE_DIR/.sl_last_state.json"
COMPRESS_FILE="$CLAUDE_DIR/.sl_compress.json"
LINEAR_FLOW_HOME="${LINEAR_FLOW_HOME:-$CLAUDE_DIR/linear-flow}"

# Field separator for the jq -> bash handoff: US (0x1f).
# A non-whitespace IFS keeps empty fields aligned (whitespace IFS collapses them).
US=$'\037'

input=$(cat)

# Extract everything in one jq pass — this script runs on every render.
IFS="$US" read -r model total_input total_output context_size used_pct session_id \
  rl_5h_pct rl_5h_reset rl_7d_pct rl_7d_reset \
  repo_host repo_owner repo_name cwd project_dir <<< "$(printf '%s' "$input" | jq -r '[
    (.model.display_name // "Unknown"),
    (.context_window.total_input_tokens // 0),
    (.context_window.total_output_tokens // 0),
    (.context_window.context_window_size // 200000),
    (.context_window.used_percentage // 0),
    (.session_id // "unknown"),
    (.rate_limits.five_hour.used_percentage // ""),
    (.rate_limits.five_hour.resets_at // ""),
    (.rate_limits.seven_day.used_percentage // ""),
    (.rate_limits.seven_day.resets_at // ""),
    (.workspace.repo.host // ""),
    (.workspace.repo.owner // ""),
    (.workspace.repo.name // ""),
    (.workspace.current_dir // .cwd // ""),
    (.workspace.project_dir // "")
  ] | map(tostring) | join("\u001f")')"

[ -z "$cwd" ] && cwd="$PWD"

current_used=$(awk "BEGIN {printf \"%.0f\", ($used_pct * $context_size) / 100}")
remaining_tokens=$((context_size - current_used))
[ "$remaining_tokens" -lt 0 ] && remaining_tokens=0
current_time=$(date +%s)

# Format number with k/M suffix
fmt() {
  local n=$1
  if [ "$n" -ge 1000000 ] 2>/dev/null; then
    awk "BEGIN {printf \"%.1fM\", $n/1000000}"
  elif [ "$n" -ge 1000 ] 2>/dev/null; then
    awk "BEGIN {printf \"%.1fk\", $n/1000}"
  else
    echo "${n:-0}"
  fi
}

# Build a 10-segment progress bar for a percentage
mkbar() {
  local pct=$1 filled empty i bar=""
  filled=$((pct / 10))
  [ "$filled" -gt 10 ] && filled=10
  [ "$filled" -lt 0 ] && filled=0
  empty=$((10 - filled))
  for ((i=0; i<filled; i++)); do bar+="█"; done
  for ((i=0; i<empty; i++)); do bar+="░"; done
  echo "$bar"
}

# Zone emoji for a percentage
zone() {
  local pct=$1
  if [ "$pct" -ge 90 ]; then echo "🔴"
  elif [ "$pct" -ge 70 ]; then echo "🟠"
  elif [ "$pct" -ge 50 ]; then echo "🟡"
  else echo "🟢"
  fi
}

# ---------------------------------------------------------------------------
# Line 1: repo / branch / Linear issue, as clickable OSC 8 hyperlinks
# ---------------------------------------------------------------------------

# Terminals known to render OSC 8 hyperlinks
links=0
case "${TERM_PROGRAM:-}" in
  ghostty|WezTerm|iTerm.app|vscode|Hyper|rio|tmux) links=1 ;;
esac
[ -n "${KITTY_WINDOW_ID:-}" ] && links=1
[ -n "${WT_SESSION:-}" ] && links=1
[ "${TERM:-}" = "xterm-kitty" ] && links=1
case "${CLAUDE_STATUSLINE_LINKS:-}" in
  0|off|false) links=0 ;;
  1|on|true)   links=1 ;;
esac

# link <url> <text> — OSC 8 hyperlink, or plain text when unsupported.
# The URL must be pure ASCII: raw UTF-8 inside the escape breaks width accounting.
link() {
  local url=$1 text=$2
  if [ "$links" = 1 ] && [ -n "$url" ]; then
    printf '\033]8;;%s\a%s\033]8;;\a' "$url" "$text"
  else
    printf '%s' "$text"
  fi
}

# Repo root + branch in a single git call
git_top=""
branch=""
if git_out=$(git -C "$cwd" --no-optional-locks rev-parse --show-toplevel --abbrev-ref HEAD 2>/dev/null); then
  git_top=$(printf '%s\n' "$git_out" | sed -n '1p')
  branch=$(printf '%s\n' "$git_out" | sed -n '2p')
fi
detached=0
if [ "$branch" = "HEAD" ]; then
  detached=1
  branch=$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
fi

# Web host: the payload reports the remote's host, which may be an ssh alias
# (e.g. github-dynagon). Resolve it via ~/.ssh/config, then fall back to GitHub.
web_host="$repo_host"
case "$web_host" in
  *.*) ;;
  "")  ;;
  *)
    if [ -r "$HOME/.ssh/config" ]; then
      resolved=$(awk -v want="$web_host" '
        /^[ \t]*#/ { next }
        tolower($1) == "host" { inhost = 0; for (i = 2; i <= NF; i++) if ($i == want) inhost = 1; next }
        inhost && tolower($1) == "hostname" { print $2; exit }
      ' "$HOME/.ssh/config" 2>/dev/null)
      [ -n "$resolved" ] && web_host="$resolved"
    fi
    web_host="${web_host#ssh.}"
    case "$web_host" in *.*) ;; *) web_host="github.com" ;; esac
    ;;
esac

repo_url=""
if [ -n "$web_host" ] && [ -n "$repo_owner" ] && [ -n "$repo_name" ]; then
  repo_url="https://$web_host/$repo_owner/$repo_name"
fi

case "$web_host" in
  *gitlab*)    tree_seg="/-/tree/"; commit_seg="/-/commit/" ;;
  *bitbucket*) tree_seg="/src/";    commit_seg="/commits/" ;;
  *)           tree_seg="/tree/";   commit_seg="/commit/" ;;
esac

# Linear binding: bindings are keyed by sha256 of the absolute workdir, so try
# the session's cwd, the repo/worktree root, and the project dir.
binding_file=""
for d in "$cwd" "$git_top" "$project_dir"; do
  [ -n "$d" ] || continue
  h=$(printf '%s' "$d" | sha256sum 2>/dev/null) || continue
  h=${h%% *}
  f="$LINEAR_FLOW_HOME/bindings/${h:0:16}.json"
  if [ -f "$f" ]; then
    binding_file="$f"
    break
  fi
done

li_id=""
li_url=""
li_title=""
if [ -n "$binding_file" ]; then
  # Truncate the title in jq: it counts codepoints, mawk's substr counts bytes.
  IFS="$US" read -r li_id li_url li_title <<< "$(jq -r '[
      (.issue.identifier // ""),
      (.issue.url // ""),
      ((.issue.title // "") | if length > 26 then .[0:26] + "…" else . end)
    ] | map(tostring) | join("\u001f")' "$binding_file" 2>/dev/null)"
fi

# Stored issue URLs embed a raw UTF-8 slug; rebuild the canonical ASCII form
# (https://linear.app/<workspace>/issue/<ID>), which Linear resolves anyway.
li_url_ascii=""
if [ -n "$li_id" ]; then
  case "$li_url" in
    *"/issue/"*) li_url_ascii="${li_url%%/issue/*}/issue/$li_id" ;;
  esac
fi

dim=$'\033[2m'
rst=$'\033[0m'

seg_repo=""
if [ -n "$repo_owner" ] && [ -n "$repo_name" ]; then
  seg_repo="📁 $(link "$repo_url" "$repo_owner/$repo_name")"
elif [ -n "$project_dir" ]; then
  seg_repo="📁 ${project_dir##*/}"
fi

seg_branch=""
if [ -n "$branch" ]; then
  branch_url=""
  if [ -n "$repo_url" ] && [[ "$branch" =~ ^[A-Za-z0-9._/-]+$ ]]; then
    if [ "$detached" = 1 ]; then
      branch_url="$repo_url$commit_seg$branch"
    else
      branch_url="$repo_url$tree_seg$branch"
    fi
  fi
  if [ "$detached" = 1 ]; then
    seg_branch="🔗 $(link "$branch_url" "$branch")"
  else
    seg_branch="🌿 $(link "$branch_url" "$branch")"
  fi
fi

if [ -n "$li_id" ]; then
  seg_issue="🎫 $(link "$li_url_ascii" "$li_id${li_title:+ $li_title}")"
else
  seg_issue="${dim}🎫 未バインド${rst}"
fi

line1=""
for s in "$seg_repo" "$seg_branch" "$seg_issue"; do
  [ -n "$s" ] || continue
  [ -n "$line1" ] && line1+=" │ "
  line1+="$s"
done

# Session & burn rate tracking (for ETA)
eta_str="--"
br_val=0

if [ -f "$LAST_STATE_FILE" ]; then
  last_sid=$(jq -r '.sid // ""' "$LAST_STATE_FILE" 2>/dev/null)
  last_tok=$(jq -r '.tok // 0' "$LAST_STATE_FILE" 2>/dev/null)

  if [ "$session_id" != "$last_sid" ] || [ "$current_used" -lt "${last_tok:-0}" ]; then
    printf '{"ts":%d,"tok":0}' "$current_time" > "$SESSION_FILE"
    printf '{"sid":"%s","count":0,"last_used":%d}' "$session_id" "$current_used" > "$COMPRESS_FILE"
  fi
else
  printf '{"ts":%d,"tok":0}' "$current_time" > "$SESSION_FILE"
  printf '{"sid":"%s","count":0,"last_used":%d}' "$session_id" "$current_used" > "$COMPRESS_FILE"
fi

# Detect context compression (used_tokens drops significantly within same session)
compress_count=0
if [ -f "$COMPRESS_FILE" ]; then
  c_sid=$(jq -r '.sid // ""' "$COMPRESS_FILE" 2>/dev/null)
  c_count=$(jq -r '.count // 0' "$COMPRESS_FILE" 2>/dev/null)
  c_last=$(jq -r '.last_used // 0' "$COMPRESS_FILE" 2>/dev/null)

  if [ "$session_id" = "$c_sid" ]; then
    compress_count=$c_count
    if [ "$c_last" -gt 0 ] && [ "$current_used" -gt 0 ]; then
      drop=$((c_last - current_used))
      threshold=$((c_last / 5))
      if [ "$drop" -gt "$threshold" ] && [ "$drop" -gt 10000 ]; then
        compress_count=$((compress_count + 1))
      fi
    fi
    printf '{"sid":"%s","count":%d,"last_used":%d}' "$session_id" "$compress_count" "$current_used" > "$COMPRESS_FILE"
  fi
fi

# Update last state
printf '{"sid":"%s","tok":%d,"ts":%d}' "$session_id" "$current_used" "$current_time" > "$LAST_STATE_FILE"

# Calculate burn rate & ETA
if [ -f "$SESSION_FILE" ]; then
  s_start=$(jq -r '.ts' "$SESSION_FILE" 2>/dev/null || echo "$current_time")
  elapsed=$((current_time - s_start))
  if [ "$elapsed" -gt 10 ] && [ "$current_used" -gt 0 ]; then
    br_val=$(awk "BEGIN {v=($current_used * 60.0) / $elapsed; printf \"%.0f\", v}")
    if [ "$br_val" -gt 0 ] 2>/dev/null; then
      eta_sec=$(awk "BEGIN {printf \"%.0f\", ($remaining_tokens * 60.0) / $br_val}")
      if [ "$eta_sec" -ge 3600 ] 2>/dev/null; then
        eta_str="$(awk "BEGIN {printf \"%.1f\", $eta_sec/3600}")h"
      elif [ "$eta_sec" -ge 60 ] 2>/dev/null; then
        eta_str="$(awk "BEGIN {printf \"%.0f\", $eta_sec/60}")min"
      else
        eta_str="${eta_sec}s"
      fi
    fi
  fi
fi

# Format a reset timestamp: HH:MM if within 24h, otherwise M/D HH:MM
fmt_reset() {
  local ts=$1
  [ -z "$ts" ] && { echo "--"; return; }
  if [ $((ts - current_time)) -lt 86400 ]; then
    date -d "@$ts" +%H:%M
  else
    date -d "@$ts" +%-m/%-d\ %H:%M
  fi
}

# Rate limit segments (same data as /usage)
if [ -n "$rl_5h_pct" ]; then
  rl_5h_str="$(zone "$rl_5h_pct") 5h: $(mkbar "$rl_5h_pct") ${rl_5h_pct}% (→$(fmt_reset "$rl_5h_reset"))"
else
  rl_5h_str="5h: --"
fi
if [ -n "$rl_7d_pct" ]; then
  rl_7d_str="$(zone "$rl_7d_pct") 7d: $(mkbar "$rl_7d_pct") ${rl_7d_pct}% (→$(fmt_reset "$rl_7d_reset"))"
else
  rl_7d_str="7d: --"
fi

# Context zone indicator
pct_int=$(awk "BEGIN {printf \"%.0f\", ${used_pct:-0}}" 2>/dev/null || echo "0")
perf="$(zone "$pct_int")"

# Output (3 lines)
# Line 1: Repo / branch / Linear issue (clickable)
# Line 2: Session context status
# Line 3: Rate limit usage (session / weekly)
prefix=""
[ -n "$line1" ] && prefix="$line1"$'\n'

printf "%s🤖 %s │ 📊 %s/%s %s %d%% %s │ ⬇%s ⬆%s │ 💡残%s │ ⏳~%s │ 🔄%d回\n⏱ %s │ %s" \
  "$prefix" \
  "$model" \
  "$(fmt $current_used)" \
  "$(fmt $context_size)" \
  "$(mkbar "$pct_int")" \
  "$pct_int" \
  "$perf" \
  "$(fmt $total_input)" \
  "$(fmt $total_output)" \
  "$(fmt $remaining_tokens)" \
  "$eta_str" \
  "$compress_count" \
  "$rl_5h_str" \
  "$rl_7d_str"
