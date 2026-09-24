# 手書き版。まだ NixOS を入れていない段階で、Ubuntu 上の lspci / lsmod / lsblk の
# 調査結果から起こした。インストール時に
#   nixos-generate-config --root /mnt --show-hardware-config
# の出力と比較し、差分があればそちらを優先すること (README の手順 2)。
#
# ファイルシステムは README の手順 1 が付けるラベル (boot / nixos) で参照している。
# その手順どおりに mkfs でラベルを付ければ、UUID に書き換える必要は無い。
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  # vmd は hosts/daiv/default.nix 側でも指定している (このファイルを再生成しても
  # 消えないようにするため)。
  boot.initrd.availableKernelModules = [ "vmd" "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-label/boot";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  # i9-13900KF (Raptor Lake)。Meteor Lake 以降ではないので intel-npu は無い。
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  hardware.graphics.enable = true;
}
