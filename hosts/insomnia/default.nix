{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./nvidia.nix
    ../../modules
  ];

  networking.hostName = "insomnia";

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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "25.11";
}
