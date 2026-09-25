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
  # 別ディスクなので systemd-boot は自動では拾わない。
  # nixpkgs の boot.loader.systemd-boot.windows は EFI Shell のデバイスハンドル
  # (HD0b / FS1 など) を固定で要求するが、ハンドルは Shell 起動時に採番される
  # ので Linux 側からは分からず、ディスク構成が変わるとずれる。代わりに
  # Windows 起動専用の EFI Shell を置き、FS0: 〜 FS9: から bootmgfw.efi を
  # 探して最初に見つかったものを起動する。
  # EDK2 Shell は shell.efi と同じディレクトリの startup.nsh を最初に実行する
  # (ShellPkg/Application/Shell/Shell.c の LocateStartupScript)。
  # 通常の EFI Shell (efi/edk2-uefi-shell/) と同じ場所に置くと、そちらを
  # 開いた時まで Windows が起動してしまうので、ディレクトリを分けている。
  # -nointerrupt は startup.nsh 前の待ち時間を 0 にする。-nomap を付けると
  # FSn: が作られずに探索できないので付けない。
  boot.loader.systemd-boot.edk2-uefi-shell.enable = true;
  boot.loader.systemd-boot.extraFiles = {
    "efi/windows/shell.efi" = "${pkgs.edk2-uefi-shell}/shell.efi";
    "efi/windows/startup.nsh" = pkgs.writeText "startup.nsh" ''
      @echo -off
      for %i run (0 9)
        if exist FS%i:\EFI\Microsoft\Boot\bootmgfw.efi then
          FS%i:\EFI\Microsoft\Boot\bootmgfw.efi
        endif
      endfor
      echo "Windows Boot Manager (\EFI\Microsoft\Boot\bootmgfw.efi) not found on FS0-FS9"
    '';
  };
  boot.loader.systemd-boot.extraEntries."windows.conf" = ''
    title Windows 11
    efi /efi/windows/shell.efi
    options -nointerrupt -noversion
    sort-key o_windows
  '';

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
