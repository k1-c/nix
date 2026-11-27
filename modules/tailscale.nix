{ config, pkgs, ... }:

let
  # Tailscale SSH を受け付けている間は、放置によるサスペンドを止める。
  #
  # サスペンドすると tailnet から外れ、接続中の SSH が切れて、復帰させるまで外から
  # 入り直せない。Tailscale SSH は tailscaled 自身が受けるので、SSH の待ち受けは
  # 「tailscaled が Running で、かつ RunSSH (tailscale set --ssh) が有効」と同じ意味になる。
  # この条件が成り立つ間だけ logind の sleep inhibitor (block) を持つ。
  #
  # 解除: `tailscale down` か `tailscale set --ssh=false` (30 秒以内に反映)。
  # 今すぐ 1 回だけ寝かせる: `sudo systemctl suspend -i`。
  # 確認: `systemd-inhibit --list` に "Tailscale SSH" の行が出る。
  #
  # ノート PC の蓋を閉じた時のサスペンドは止まらない (logind の
  # LidSwitchIgnoreInhibited が既定で yes のため)。持ち運びでは従来どおり眠る。
  inhibit = pkgs.writeShellApplication {
    name = "tailscale-ssh-sleep-inhibit";
    runtimeInputs = [ config.services.tailscale.package pkgs.coreutils pkgs.jq pkgs.systemd ];
    text = ''
      interval=30

      # tailscaled が起動途中・停止中で問い合わせに失敗した時は「受け付けていない」と扱う。
      accepting_ssh() {
        local state run_ssh
        state="$(tailscale status --json 2>/dev/null | jq -r '.BackendState' 2>/dev/null || true)"
        [ "$state" = Running ] || return 1
        run_ssh="$(tailscale debug prefs 2>/dev/null | jq -r '.RunSSH' 2>/dev/null || true)"
        [ "$run_ssh" = true ]
      }

      case "''${1:-watch}" in
        # 受け付けが始まるまで待ち、始まったら inhibitor を持った状態で hold を走らせる。
        # hold が抜ける (= 受け付けが終わる) と inhibitor も一緒に外れる。
        watch)
          while true; do
            if accepting_ssh; then
              echo "accepting Tailscale SSH: blocking sleep"
              systemd-inhibit --what=sleep --mode=block \
                --who="Tailscale SSH" --why="Accepting SSH connections over Tailscale" \
                "$0" hold || true
              echo "no longer accepting Tailscale SSH: sleep allowed"
            fi
            sleep "$interval"
          done
          ;;
        hold)
          while accepting_ssh; do sleep "$interval"; done
          ;;
      esac
    '';
  };
in
{
  services.tailscale.enable = true;

  systemd.services.tailscale-ssh-sleep-inhibit = {
    description = "Block sleep while accepting Tailscale SSH";
    wantedBy = [ "multi-user.target" ];
    # tailscaled を止めた時は問い合わせが失敗して inhibitor が外れ、起動し直せばまた持つ。
    # そのためユニット同士は順序だけを結び、停止を連動させない。
    after = [ "tailscaled.service" ];
    serviceConfig = {
      ExecStart = "${inhibit}/bin/tailscale-ssh-sleep-inhibit";
      Restart = "always";
      RestartSec = 5;
    };
  };
}
