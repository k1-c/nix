{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./nvidia.nix
    ./packages.nix
    ../../modules
  ];

  networking.hostName = "daiv";

  # MouseComputer Z790-S01 (i9-13900KF) は Intel VMD (Volume Management Device) が
  # 有効で、NVMe が VMD 配下 (PCI domain 10000) に見える。initrd に vmd が無いと
  # ルートが見つからず起動しないので、hardware-configuration.nix を
  # nixos-generate-config で作り直しても消えないよう、ここでも明示する。
  # BIOS 側で VMD を切ってはいけない (同じ機体の Windows が VMD 前提で
  # インストールされており、切ると Windows が起動不能になる)。
  boot.initrd.availableKernelModules = [ "vmd" ];

  # 同じ機体の別 NVMe (nvme0n1) に Windows 11 が入っている。Windows の ESP は
  # 別ディスクなので systemd-boot は自動では拾わないが、ファームウェアの
  # ブートメニューからは常に選べる (efibootmgr に "Windows Boot Manager" がある)。
  # systemd-boot のメニューにも出したい場合は、下の EFI Shell を起動して
  # `map -c` で Windows の ESP のハンドル (HD0b / FS1 など) を調べ、
  # windows エントリのコメントを外して埋める。
  boot.loader.systemd-boot.edk2-uefi-shell.enable = true;
  # boot.loader.systemd-boot.windows."11" = {
  #   title = "Windows 11";
  #   efiDeviceHandle = "FIXME"; # EFI Shell の `map -c` で確認したハンドル
  # };

  # メモリ 32GB。Ubuntu 時代は 8GB の swap を常に使い切っていたので大きめに取る。
  # README の手順 1 は swap パーティションを切らないので swap ファイルにする。
  swapDevices = [
    {
      device = "/swap";
      size = 16 * 1024; # MiB
    }
  ];

  # Steam / Proton が要求する値 (Ubuntu 24.04 の既定と同じ)。
  boot.kernel.sysctl."vm.max_map_count" = 1048576;

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

  # 初回インストール時の OS バージョン。flake の nixpkgs が nixos-25.11 なので
  # 25.11 で入れたことになる (ISO が 26.05 でも、システムを組み立てるのは flake 側)。
  # NOTE: 既存システムを update する時は変更しない (state versions 不整合の元)。
  system.stateVersion = "25.11";
}
