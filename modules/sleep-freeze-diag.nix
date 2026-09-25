{ pkgs, ... }:

let
  # サスペンド時に「1 tasks refusing to freeze」で失敗する件の調査用フック (フェーズ 1: 記録のみ)。
  #
  # daiv / mind で放置サスペンドが毎回失敗し、失敗後の疑似 resume で画面が戻らない症状がある。
  # カーネルログでは Chromium 系 (Chrome 濃厚) の ThreadPoolServi スレッドが
  # zap_pid_ns_processes() で止まっていた。これは sandbox の PID namespace の init が
  # 終了途中で、namespace 内の他タスクの回収を待ち続けている状態で、freezer で凍結できない。
  # 何を待っているか (ptrace 中 / 外部の親が reap しない / D state) で kill すべき相手が
  # 変わるため、まずは状況を journal に残す。kill による対処はデータが揃ってから追加する。
  #
  # 確認: journalctl -t sleep-freeze-diag
  diag = pkgs.writeShellApplication {
    name = "sleep-freeze-diag";
    runtimeInputs = with pkgs; [ coreutils gnugrep gnused systemd ];
    text = ''
      mode="''${1:-pre}"
      marker=/run/sleep-freeze-diag.since

      # 調査対象のプロセスは途中で消えうるので、読めなくても失敗扱いにしない (set -e 対策)。
      field() { grep -m1 "^$2:" "/proc/$1/status" 2>/dev/null | cut -f2- | tr -s '\t ' ' ' || true; }
      cmdline() { { tr '\0' ' ' < "/proc/$1/cmdline"; } 2>/dev/null | cut -c1-200 || true; }

      task_line() {
        local t="$1"
        echo "  tid=$t name=$(field "$t" Name) state=$(field "$t" State)" \
          "tgid=$(field "$t" Tgid) ppid=$(field "$t" PPid) nspid=[$(field "$t" NSpid)]" \
          "tracer=$(field "$t" TracerPid) wchan=$(cat "/proc/$t/wchan" 2>/dev/null)"
        echo "    cmd: $(cmdline "$(field "$t" Tgid)")"
      }

      dump() {
        local t="$1" ns p tracer
        echo "=== stuck task $t ==="
        task_line "$t"
        echo "  kernel stack:"
        sed 's/^/    /' "/proc/$t/stack" 2>/dev/null || echo "    (unreadable)"

        echo "  ancestors:"
        p="$(field "$t" PPid)"
        while [ -n "$p" ] && [ "$p" -gt 1 ]; do
          echo "    $p $(field "$p" Name): $(cmdline "$p")"
          p="$(field "$p" PPid)"
        done

        ns="$(readlink "/proc/$t/ns/pid" 2>/dev/null || true)"
        echo "  pid namespace: ''${ns:-unknown}"
        [ -n "$ns" ] || return 0
        echo "  tasks in the same pid namespace:"
        for d in /proc/[0-9]*/task/[0-9]*; do
          [ "$(readlink "$d/ns/pid" 2>/dev/null)" = "$ns" ] || continue
          task_line "''${d##*/}"
          tracer="$(field "''${d##*/}" TracerPid)"
          if [ -n "$tracer" ] && [ "$tracer" != 0 ]; then
            echo "    traced by $tracer $(field "$tracer" Name): $(cmdline "$tracer")"
          fi
        done
      }

      case "$mode" in
        pre)
          date '+%Y-%m-%d %H:%M:%S' > "$marker"
          found=0
          for w in /proc/[0-9]*/task/[0-9]*/wchan; do
            [ "$(cat "$w" 2>/dev/null)" = zap_pid_ns_processes ] || continue
            t="''${w%/wchan}"; t="''${t##*/}"
            found=1
            dump "$t"
          done
          [ "$found" = 1 ] || echo "pre: no task in zap_pid_ns_processes"
          ;;
        post)
          since="$(cat "$marker" 2>/dev/null || echo '-10min')"
          klog="$(journalctl -k --no-pager -o cat --since "$since" || true)"
          # 失敗時は凍結できなかったタスクごとに "task:<comm> ... pid:<tid> tgid:..." が続く。
          pids=""
          if grep -q 'refusing to freeze' <<< "$klog"; then
            pids="$(sed -nE 's/^task:.* pid:([0-9]+) .*/\1/p' <<< "$klog" | sort -u || true)"
          fi
          if [ -z "$pids" ]; then
            echo "post: no freeze failure since $since"
            exit 0
          fi
          echo "post: freeze failed since $since, culprits: $(echo "$pids" | tr '\n' ' ')"
          for t in $pids; do
            if [ -d "/proc/$t" ]; then dump "$t"; else echo "=== task $t already gone ==="; fi
          done
          ;;
      esac
      exit 0
    '';
  };

  sleepUnits = [
    "systemd-suspend.service"
    "systemd-hibernate.service"
    "systemd-hybrid-sleep.service"
    "systemd-suspend-then-hibernate.service"
  ];
in
{
  # systemd-sleep が user.slice を凍結するより前 (sleep.target の手前) に検査する。
  systemd.services.sleep-freeze-diag-pre = {
    description = "Log tasks that would block suspend (pid namespace teardown)";
    wantedBy = [ "sleep.target" ];
    before = [ "sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${diag}/bin/sleep-freeze-diag pre";
      SyslogIdentifier = "sleep-freeze-diag";
      TimeoutStartSec = 20;
    };
  };

  # サスペンドが失敗しても Wants + After なので実行される (nvidia-resume と同じ形)。
  systemd.services.sleep-freeze-diag-post = {
    description = "Log tasks that refused to freeze during the last suspend attempt";
    wantedBy = sleepUnits;
    after = sleepUnits;
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${diag}/bin/sleep-freeze-diag post";
      SyslogIdentifier = "sleep-freeze-diag";
      TimeoutStartSec = 20;
    };
  };
}
