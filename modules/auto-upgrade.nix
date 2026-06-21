{
  system.autoUpgrade = {
    enable = true;
    flake = "github:k1-c/nix";
    flags = [
      "-L"
      "--recreate-lock-file"
    ];
    dates = "weekly";
    randomizedDelaySec = "45min";
    allowReboot = false;
  };
}
