{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos
  ];

  networking.hostName = "dwarf";

  # dwarf には NVIDIA GPU が無いため hosts/insomnia 側の nvidia.nix は import しない。
  # iGPU (Intel) 経由で hardware.graphics.enable はデフォルトで有効になる。
  hardware.graphics.enable = true;

  users.users.k1nix = {
    isNormalUser = true;
    description = "k1nix";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.zsh;
  };

  # 初回インストール時の OS バージョン。
  # NOTE: 既存システムを update する時は変更しない (state versions 不整合の元)。
  system.stateVersion = "25.11";
}
