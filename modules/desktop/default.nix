{
  imports = [
    ./common.nix
    ./screenshot.nix
    ./plasma.nix
    ./hyprland.nix
    # COSMIC を既定の DE にする (全ホスト共通)。unstable の 1.6.0 を使う事情は cosmic.nix 参照。
    ./cosmic.nix
  ];
}
