{ pkgs, ... }:

{
  # VSCode本体のみ。Extensionsは marketplace から入れる前提（dotfilesでは60+を
  # 使っているがnixpkgsの vscode-extensions で揃わないものが多いため、ここでは
  # 同期せず必要に応じて追加していく方針）。
  programs.vscode = {
    enable = true;
  };
}
