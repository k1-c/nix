{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules
    ../../modules/displaylink.nix
    # COSMIC (Frosted Glass 目的で unstable の 1.6.0 を使う) は mind 限定。
    # 他ホストは NVIDIA / 未検証なので modules/desktop/default.nix には入れない。
    ../../modules/desktop/cosmic.nix
  ];

  networking.hostName = "mind";
  hardware.graphics.enable = true;

  users.users.k1nix = {
    isNormalUser = true;
    description = "k1nix";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.zsh;
  };

  # 初回インストール時の OS バージョン。
  # NOTE: 既存システムを update する時は変更しない (state versions 不整合の元)。
  system.stateVersion = "26.05";
}
