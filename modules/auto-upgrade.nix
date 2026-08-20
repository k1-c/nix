{
  system.autoUpgrade = {
    enable = true;
    flake = "github:k1-c/nix";
    flags = [
      "-L"
      "--recreate-lock-file"
    ];
    # daily: claude-code など速く動くツールを追随させる。--recreate-lock-file が
    # 毎回全 input（nix-claude-code 含む）を最新へ解決する。差分が無い日は no-op。
    dates = "daily";
    randomizedDelaySec = "45min";
    allowReboot = false;
  };
}
