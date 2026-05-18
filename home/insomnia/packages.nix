{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # File / text tools
    eza
    bat
    fd
    fzf
    ripgrep
    jq
    xclip
    xsel

    # Dev tools
    gitui
    ghq
    peco
    lazygit
    mise

    # Build toolchain (needed by lazy.nvim build steps, e.g. telescope-fzf-native)
    gcc
    gnumake

    # X / utilities
    xdotool

    # Containers (CLI; daemon enabled via modules/nixos/docker.nix)
    docker-compose

    # Node (for coc.nvim, ccusage, etc. — mise may also provide it)
    nodejs_22

    # Apps
    obsidian
    ulauncher

    # GUI helpers
    kdePackages.kate
  ];
}
