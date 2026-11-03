# focus-mode-ctl: Focus モードの状態管理と Chrome ポリシーの書き出し。
# 冒頭の変数 (STATE_DIR POLICY_FILE BASE_ALLOWLIST DEFAULT_DURATION
# OFF_DELAY_SEC REQUIRE_ROOT) は package.nix が前置する。
#
# 状態 ($STATE_DIR):
#   until   Focus の終了時刻 (epoch 秒)。これがあって現在時刻より後なら ON
#   off-at  解除予約の時刻 (epoch 秒)。focus off で作り、focus cancel で消す
#   extra   この Focus 中だけの追加許可 (1 行 1 ホスト)。Focus 終了時に消す
# ポリシーファイル ($POLICY_FILE) は状態から導出する。sync が両者を突き合わせる。

until_file="$STATE_DIR/until"
off_at_file="$STATE_DIR/off-at"
extra_file="$STATE_DIR/extra"

die() {
  echo "focus: $*" >&2
  exit 1
}

usage() {
  cat <<EOF
使い方: focus [コマンド]
  (なし) | status          状態を表示
  on [時間]                Focus を開始 (既定 $DEFAULT_DURATION)。実行中なら終了時刻を延ばす。パスワード不要
  off                      $((OFF_DELAY_SEC / 60)) 分後に解除する予約をする (sudo)
  cancel                   解除予約を取り消す。パスワード不要
  allow <URL|ドメイン>...  この Focus 中だけ許可を足す (sudo)
  list                     いま効いている許可リストを表示

時間の書式: 90 (分) / 90m / 2h / 1h30m
恒久的な許可リスト: nix リポジトリの modules/focus-mode/allowlist.txt
EOF
}

require_root() {
  if [[ $REQUIRE_ROOT == 1 ]] && ((EUID != 0)); then
    die "root 権限が必要です (focus コマンド経由で実行してください)"
  fi
}

# epoch 秒のファイルを読む。無い・壊れているときは空文字。
read_epoch() {
  local v=""
  if [[ -f $1 ]]; then v=$(<"$1"); fi
  if [[ $v =~ ^[0-9]+$ ]]; then printf '%s' "$v"; fi
}

is_active() {
  local now end_at off_at
  now=$(date +%s)
  end_at=$(read_epoch "$until_file")
  off_at=$(read_epoch "$off_at_file")
  [[ -n $end_at ]] || return 1
  ((now < end_at)) || return 1
  [[ -z $off_at ]] || ((now < off_at))
}

# epoch 秒 → "15:30" (今日以外は "11/04 15:30")
fmt_time() {
  if [[ $(date -d "@$1" +%F) == "$(date +%F)" ]]; then
    date -d "@$1" +%H:%M
  else
    date -d "@$1" '+%m/%d %H:%M'
  fi
}

# 秒 → "1h05m" / "12m" (分は切り上げ)
fmt_duration() {
  local total=$((($1 + 59) / 60))
  if ((total >= 60)); then
    printf '%dh%02dm' $((total / 60)) $((total % 60))
  else
    printf '%dm' "$total"
  fi
}

# "90" / "90m" / "2h" / "1h30m" → 秒
parse_duration() {
  local s=${1,,} h=0 m=0
  if [[ -z $s || ! $s =~ ^(([0-9]+)h)?(([0-9]+)(m|min)?)?$ ]]; then
    die "時間の書式が不正です: $1 (例: 90m, 2h, 1h30m)"
  fi
  if [[ -n ${BASH_REMATCH[2]} ]]; then h=$((10#${BASH_REMATCH[2]})); fi
  if [[ -n ${BASH_REMATCH[4]} ]]; then m=$((10#${BASH_REMATCH[4]})); fi
  local secs=$((h * 3600 + m * 60))
  ((secs >= 60)) || die "1 分以上を指定してください"
  echo "$secs"
}

# URL かドメインからホスト名を取り出す
normalize_host() {
  local s=${1,,}
  s=${s#*://}
  s=${s%%[/?#]*}
  s=${s##*@}
  if [[ $s =~ ^(.*):[0-9]+$ ]]; then s=${BASH_REMATCH[1]}; fi
  if [[ ! $s =~ ^\.?[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)*$ ]]; then
    die "ドメインとして解釈できません: $1"
  fi
  echo "$s"
}

write_policy() {
  local dir tmp extra=/dev/null
  dir=$(dirname "$POLICY_FILE")
  # Chrome は managed/ 内のファイルをすべて読むので、書きかけのファイルは
  # 1 つ上に置いて rename で差し替える。
  tmp="$(dirname "$dir")/.focus-mode.json.tmp"
  mkdir -p "$dir"
  if [[ -f $extra_file ]]; then extra=$extra_file; fi
  jq -n --slurpfile base "$BASE_ALLOWLIST" --rawfile extra "$extra" '{
    URLBlocklist: ["*"],
    URLAllowlist: ($base[0] + ($extra | split("\n") | map(select(. != ""))) | unique)
  }' >"$tmp"
  chmod 0644 "$tmp"
  # timer から 30 秒ごとに呼ばれるので、変化が無ければ触らない
  # (Chrome にポリシーの再読み込みを無駄に起こさせない)。
  if [[ -f $POLICY_FILE ]] && cmp -s "$tmp" "$POLICY_FILE"; then
    rm -f "$tmp"
  else
    mv -f "$tmp" "$POLICY_FILE"
  fi
}

deactivate() {
  local was_on=0
  if [[ -f $POLICY_FILE ]]; then was_on=1; fi
  rm -f "$POLICY_FILE" "$until_file" "$off_at_file" "$extra_file"
  if ((was_on)); then echo "Focus モードを終了しました"; fi
}

cmd_sync() {
  require_root
  if is_active; then write_policy; else deactivate; fi
}

cmd_status() {
  if ! is_active; then
    echo "Focus: OFF"
    return
  fi
  local now end_at off_at n
  now=$(date +%s)
  end_at=$(read_epoch "$until_file")
  off_at=$(read_epoch "$off_at_file")
  echo "Focus: ON  ($(fmt_time "$end_at") まで / 残り $(fmt_duration $((end_at - now))))"
  if [[ -n $off_at ]]; then
    echo "解除予約: $(fmt_time "$off_at") (取り消し: focus cancel)"
  fi
  if [[ -s $extra_file ]]; then
    n=$(grep -c . "$extra_file" || true)
    echo "一時追加: $n 件 (focus list で表示)"
  fi
}

cmd_list() {
  echo "# 恒久 (allowlist.txt)"
  jq -r '.[]' "$BASE_ALLOWLIST"
  if is_active && [[ -s $extra_file ]]; then
    echo
    echo "# 一時追加 (この Focus 中のみ)"
    cat "$extra_file"
  fi
}

cmd_on() {
  require_root
  (($# <= 1)) || die "使い方: focus on [時間 (例: 90m, 2h, 1h30m)]"
  local secs now end_at cur
  secs=$(parse_duration "${1:-$DEFAULT_DURATION}")
  now=$(date +%s)
  end_at=$((now + secs))
  if is_active; then
    # 延長のみ。短くはしない (focus on 1m で抜けられないように)
    cur=$(read_epoch "$until_file")
    if ((cur > end_at)); then end_at=$cur; fi
  else
    rm -f "$extra_file" # 前回の一時追加を持ち越さない
  fi
  mkdir -p "$STATE_DIR"
  echo "$end_at" >"$until_file"
  rm -f "$off_at_file"
  write_policy
  cmd_status
}

cmd_off() {
  require_root
  (($# == 0)) || die "使い方: focus off"
  is_active || die "Focus モードは有効ではありません"
  local now end_at off_at target
  now=$(date +%s)
  end_at=$(read_epoch "$until_file")
  off_at=$(read_epoch "$off_at_file")
  if [[ -n $off_at ]]; then
    echo "すでに $(fmt_time "$off_at") に解除する予約があります"
    return
  fi
  target=$((now + OFF_DELAY_SEC))
  if ((target >= end_at)); then
    echo "終了時刻 ($(fmt_time "$end_at")) のほうが早いので、そのまま終了を待ちます"
    return
  fi
  echo "$target" >"$off_at_file"
  echo "$(fmt_time "$target") に解除します。取り消すには: focus cancel"
}

cmd_cancel() {
  require_root
  (($# == 0)) || die "使い方: focus cancel"
  if [[ -f $off_at_file ]]; then
    rm -f "$off_at_file"
    echo "解除予約を取り消しました"
  else
    echo "解除予約はありません"
  fi
}

cmd_allow() {
  require_root
  (($# >= 1)) || die "使い方: focus allow <URL またはドメイン>..."
  is_active || die "Focus モードは有効ではありません (恒久的に足すなら allowlist.txt を編集してください)"
  local arg host
  for arg in "$@"; do
    host=$(normalize_host "$arg")
    if jq -e --arg h "$host" 'any(. == $h)' "$BASE_ALLOWLIST" >/dev/null ||
      grep -qxF "$host" "$extra_file" 2>/dev/null; then
      echo "許可済み: $host"
    else
      echo "$host" >>"$extra_file"
      echo "追加: $host"
    fi
  done
  write_policy
}

cmd=${1:-status}
if (($# > 0)); then shift; fi
case $cmd in
on) cmd_on "$@" ;;
off) cmd_off "$@" ;;
cancel) cmd_cancel "$@" ;;
allow) cmd_allow "$@" ;;
status) cmd_status ;;
list) cmd_list ;;
sync) cmd_sync ;;
help | -h | --help) usage ;;
*)
  usage >&2
  exit 1
  ;;
esac
