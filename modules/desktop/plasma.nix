{
  # SDDM 上で Plasma セッションを選択可能にする。
  # Niri が安定したらこのファイルの import を default.nix から外す。
  services.desktopManager.plasma6.enable = true;
}
