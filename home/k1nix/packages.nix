{ pkgs, pkgs-unstable, ... }:

{
  home.packages = (with pkgs; [
    # File / text tools
    eza
    bat
    fd
    fzf
    ripgrep
    jq
    # Plasma (X11) セッション用の clipboard ツール。Niri 側は wl-clipboard を home/k1nix/desktop/cliphist.nix で導入。
    xclip
    xsel
    wl-clipboard
    openssl

    # macOS-style clipboard shims.
    # WAYLAND_DISPLAY があれば wl-copy/wl-paste、無ければ xsel にフォールバック。
    (writeShellScriptBin "pbcopy" ''
      if [ -n "$WAYLAND_DISPLAY" ]; then
        exec ${wl-clipboard}/bin/wl-copy "$@"
      else
        exec ${xsel}/bin/xsel --clipboard --input "$@"
      fi
    '')
    (writeShellScriptBin "pbpaste" ''
      if [ -n "$WAYLAND_DISPLAY" ]; then
        exec ${wl-clipboard}/bin/wl-paste "$@"
      else
        exec ${xsel}/bin/xsel --clipboard --output "$@"
      fi
    '')

    # macOS-style `open` shim. zsh の shellAliases は対話シェル限定で
    # Neovim の :! やプラグインから呼ばれる非対話シェルでは効かないため、
    # 実バイナリとして PATH に置く。
    (writeShellScriptBin "open" ''
      exec ${xdg-utils}/bin/xdg-open "$@"
    '')

    # Dev tools
    gitui
    ghq
    peco
    lazygit

    # Image / PDF processing (プロジェクトの check-libs タスクが gm/gs を要求)
    graphicsmagick   # provides `gm`
    ghostscript      # provides `gs`

    # Build toolchain (needed by lazy.nvim build steps, e.g. telescope-fzf-native)
    gcc
    gnumake

    # X / utilities
    xdotool

    # Containers (CLI; daemon enabled via modules/docker.nix)
    docker-compose

    # Cloud CLIs (vercel / wrangler は mise 経由で導入。home/k1nix/mise.nix を参照)
    awscli2
    google-cloud-sdk

    # Node (for coc.nvim, ccusage, etc. — mise may also provide it)
    nodejs_22

    # Python
    python3

    # Apps
    obsidian
    ulauncher

    # GUI helpers
    kdePackages.kate
  ]) ++ (with pkgs-unstable; [
    # nixos-25.11 の mise が古く [settings] node_compile に未対応のため unstable を採用
    mise
    # nixos-25.11 の gh は古いため unstable を採用
    gh
  ]);
}
