# focus コマンド一式。default.nix が本番のパスで呼ぶ。
# パスと requireRoot / sudoCommand を差し替えれば、一時ディレクトリ相手に root なしで
# 動作確認できる。
{
  lib,
  writeShellApplication,
  writeText,
  coreutils,
  diffutils,
  gnugrep,
  gnused,
  jq,

  allowlist,
  localAllowlist,
  stateDir,
  policyFile,
  defaultDuration,
  offDelaySec,
  requireRoot ? true,
  # pkgs.sudo と衝突して callPackage に上書きされるので sudo という名前にしない
  sudoCommand ? "/run/wrappers/bin/sudo",
}:

let
  baseAllowlist = writeText "focus-mode-allowlist.json" (builtins.toJSON allowlist);

  # 状態を書き換える処理はすべてこちら (root で動く)。
  ctl = writeShellApplication {
    name = "focus-mode-ctl";
    runtimeInputs = [
      coreutils
      diffutils
      gnugrep
      gnused
      jq
    ];
    text = ''
      STATE_DIR=${lib.escapeShellArg stateDir}
      POLICY_FILE=${lib.escapeShellArg policyFile}
      BASE_ALLOWLIST=${baseAllowlist}
      LOCAL_ALLOWLIST=${lib.escapeShellArg localAllowlist}
      DEFAULT_DURATION=${lib.escapeShellArg defaultDuration}
      OFF_DELAY_SEC=${toString offDelaySec}
      REQUIRE_ROOT=${if requireRoot then "1" else "0"}
    ''
    + builtins.readFile ./focus-mode-ctl.sh;
  };

  # ユーザーが叩く入口。書き換え系は sudo 経由で ctl に渡す。
  # sudoers 側 (default.nix) は ctl のストアパスに対して NOPASSWD を付けるので、
  # ここでも同じパスを直接呼ぶ。
  focus = writeShellApplication {
    name = "focus";
    text = ''
      case "''${1:-status}" in
      on | off | cancel | allow)
        if ((EUID != 0)); then
          exec ${sudoCommand} ${ctl}/bin/focus-mode-ctl "$@"
        fi
        ;;
      esac
      exec ${ctl}/bin/focus-mode-ctl "$@"
    '';
  };
in
{
  inherit ctl focus;
}
