{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules
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
