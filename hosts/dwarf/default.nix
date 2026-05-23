{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules
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
    # 初回ログイン用パスワード。`passwd` で変更したら、このオプションは効かなくなる
    # (initialPassword は /etc/shadow に未設定の時だけ書き込まれる)。
    # FIXME: 初回 install 後はこの行を消すか hashedPassword に置き換える。
    initialPassword = "password";
  };

  # 初回インストール時の OS バージョン。
  # NOTE: 既存システムを update する時は変更しない (state versions 不整合の元)。
  system.stateVersion = "25.11";
}
