{ lib, pkgs, inputs, ... }:

let
  # プロンプト入力欄の下に出るツールバー（statusLine）。
  # 1行目: リポジトリ / ブランチ / linear-flow がバインドした Linear Issue（OSC 8 でクリック可能）
  # 2行目: モデル / コンテキスト使用量 / ETA
  # 3行目: レートリミット（5h / 7d）
  #
  # 実行時に PATH から使うもの: bash, jq, git, sha256sum (coreutils), awk, sed, date
  # awk/sed/coreutils は NixOS の system-path に常に入るので、明示するのは jq だけ。
  statusLine = {
    type = "command";
    command = "cat | bash ~/.claude/statusline.sh";
  };

  # コミットの Co-Authored-By trailer と PR 本文の署名を付けさせない（空文字で無効化）。
  attribution = {
    commit = "";
    pr = "";
  };

  # 応答言語。Claude Code はこの値をそのまま「常にこの言語で応答する」指示として
  # Claude に渡す（綴りの検証はされない）。コミットや PR を英語で書く作業が長く
  # 続いても、会話の言語が英語に流れないようにする。
  language = "japanese";
in
{
  programs.claude-code = {
    enable = true;
    package = inputs.nix-claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default;

    # settings は意図的に空のままにする。programs.claude-code.settings を設定すると
    # ~/.claude/settings.json が store への読み取り専用 symlink になり、Claude Code
    # 自身の書き込み（enabledPlugins / autoMode / feedbackSurveyState、/config や
    # /statusline）が全部失敗する。statusLine / attribution / language だけ下の activation でマージして入れる。
  };

  # store への symlink になる。変更するときは files/claude-statusline.sh を編集して
  # nixos-rebuild switch する（~/.claude/statusline.sh 側は読み取り専用になる）。
  # 既に手書きの ~/.claude/statusline.sh があるマシンでは初回の switch が
  # 衝突で止まるので、退避するか `home-manager switch -b backup` を使う。
  home.file.".claude/statusline.sh".source = ./files/claude-statusline.sh;

  # statusline が毎描画で使う（packages.nix にも入っているが依存として明示する）
  home.packages = [ pkgs.jq ];

  # statusLine / attribution / language の項だけを冪等にマージする。他のキーとファイルの権限は保つ。
  home.activation.claudeCodeSettings =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      claudeDir="$HOME/.claude"
      settings="$claudeDir/settings.json"
      desired=${lib.escapeShellArg (builtins.toJSON { inherit statusLine attribution language; })}

      run mkdir -p "$claudeDir"

      if [ -e "$settings" ] && ! ${pkgs.jq}/bin/jq -e . "$settings" > /dev/null 2>&1; then
        echo "claude-code: $settings が妥当な JSON ではないため statusLine / attribution / language の設定を見送りました" >&2
      else
        tmp="$(${pkgs.coreutils}/bin/mktemp)"

        if [ -s "$settings" ]; then
          ${pkgs.jq}/bin/jq --argjson d "$desired" '.statusLine = $d.statusLine | .attribution = ((.attribution // {}) + $d.attribution) | .language = $d.language' "$settings" > "$tmp"
        else
          ${pkgs.jq}/bin/jq -n --argjson d "$desired" '$d' > "$tmp"
        fi

        if ${pkgs.coreutils}/bin/cmp -s "$tmp" "$settings" 2> /dev/null; then
          : # 差分なし
        elif [ -n "''${DRY_RUN_CMD:-}" ]; then
          echo "would set statusLine / attribution / language in $settings"
        elif [ -e "$settings" ]; then
          # inode と権限を保つため、install ではなく上書きコピーする
          ${pkgs.coreutils}/bin/cat "$tmp" > "$settings"
        else
          ${pkgs.coreutils}/bin/install -m 644 "$tmp" "$settings"
        fi

        ${pkgs.coreutils}/bin/rm -f "$tmp"
      fi
    '';
}
