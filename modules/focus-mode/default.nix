# Focus モード: Google Chrome で許可リスト外のサイトへの遷移をブロックする。
#
# 仕組み
#   - Chrome Enterprise Policy (URLBlocklist ["*"] + URLAllowlist) を
#     /etc/opt/chrome/policies/managed/focus-mode.json に置く/消すことで切り替える。
#     root 所有のポリシーはブラウザの UI から変更できない (拡張機能と違って
#     その場で無効化できない)。判定はページ遷移 (メインフレーム / iframe) 単位なので、
#     CDN などのサブリソースまで許可リストに書く必要はない。
#   - ON/OFF の状態は Nix 構成に持たない。system.autoUpgrade が毎日
#     github:k1-c/nix から rebuild するので、構成に持つと手元の切り替えと競合する。
#     状態は /var/lib/focus-mode/ に置き、再起動しても Focus は続く
#     (再起動で抜けられないように)。
#   - focus-mode-sync.timer が 30 秒ごとに状態とポリシーを突き合わせる
#     (終了時刻・解除予約の処理と、rebuild 後の許可リストの反映)。
#
# 摩擦の設計 (wheel 持ちの自分のマシンなので、sudo で何でも外せる前提)
#   - focus on / cancel: パスワード不要 (縛りを強める方向なので)
#   - focus off: sudo + OFF_DELAY 後に解除 (衝動が過ぎるのを待つ)
#   - focus allow: sudo のみ (正当な用途ですぐ足したい場面が多いので待ちなし)
#
# 対象は Google Chrome のみ。chromium (drawio の headless export に使う) や
# terminal-browser などの他ブラウザは対象外。
{ lib, pkgs, ... }:

let
  stateDir = "/var/lib/focus-mode";
  policyFile = "/etc/opt/chrome/policies/managed/focus-mode.json";

  # allowlist.txt: 1 行 1 エントリ。# 以降はコメント。
  allowlist = lib.pipe ./allowlist.txt [
    builtins.readFile
    (lib.splitString "\n")
    (map (line: lib.trim (lib.head (lib.splitString "#" line))))
    (lib.filter (line: line != ""))
  ];

  inherit
    (pkgs.callPackage ./package.nix {
      inherit allowlist stateDir policyFile;
      defaultDuration = "90m";
      offDelaySec = 10 * 60;
    })
    ctl
    focus
    ;
in
{
  assertions = [
    {
      # URLAllowlist は 1000 件を超えた分が黙って無視される。
      # focus allow の一時追加ぶんを残しておく。
      assertion = lib.length allowlist <= 900;
      message = "modules/focus-mode/allowlist.txt が多すぎます (${toString (lib.length allowlist)} 件、上限 900)";
    }
  ];

  environment.systemPackages = [ focus ];

  # 既定の wheel ルール (mkOrder 600) より後ろに並ぶので、こちらが優先される。
  security.sudo.extraRules = [
    {
      groups = [ "wheel" ];
      commands =
        map
          (args: {
            command = "${ctl}/bin/focus-mode-ctl ${args}";
            options = [ "NOPASSWD" ];
          })
          [
            "on"
            "on *"
            "cancel"
          ];
    }
  ];

  systemd.tmpfiles.rules = [ "d ${stateDir} 0755 root root -" ];

  systemd.services.focus-mode-sync = {
    description = "Reconcile Focus mode state with the Chrome policy";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${ctl}/bin/focus-mode-ctl sync";
      # 30 秒ごとに走るので、systemd 自身の Starting/Finished (info) は落とし、
      # 終了時のメッセージだけ notice で残す。
      SyslogLevel = "notice";
      LogLevelMax = "notice";
    };
  };

  systemd.timers.focus-mode-sync = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:*:0/30";
      AccuracySec = "1s";
    };
  };
}
