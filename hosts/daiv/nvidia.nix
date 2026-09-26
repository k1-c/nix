{ config, lib, pkgs, ... }:

{
  services.xserver.videoDrivers = [ "nvidia" ];

  # NVIDIA RTX 5070 Ti (Blackwell / GB203) のシングル GPU 運用。モニタは NVIDIA の
  # DisplayPort に直結。CPU は i9-13900KF (末尾 F = iGPU 無し) なので PRIME や
  # iGPU 側の考慮は不要。
  # Blackwell は proprietary kernel module が対応しておらず、open kernel module が
  # 必須 (driver 570 以降)。Ubuntu 時代も nvidia-driver-580-open で運用していた。
  hardware.nvidia = {
    open = lib.mkForce true;       # nixos-generate-config が `open = false` を書いても上書きする
    modesetting.enable = true;
    nvidiaSettings = true;
    powerManagement.enable = true; # suspend / resume の安定性向上
    # NOTE: hardware.nvidia.package を上書きしてはいけない (hosts/insomnia/nvidia.nix 参照)。
  };

  # NVIDIA + Wayland (COSMIC / Hyprland) 安定化の定番カーネルパラメータ。
  # nvidia-drm.modeset=1 は Ubuntu 時代の GRUB_CMDLINE にも入れていた。
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
  ];

  environment.sessionVariables = {
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
    NVD_BACKEND = "direct";
    # NVIDIA + Wayland でカーソル消失 / 起動直後ブラックアウトを防ぐ (insomnia と同じ)。
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  # VA-API 経由のハードウェアデコード (ブラウザ等で利用)。
  hardware.graphics.extraPackages = with pkgs; [
    nvidia-vaapi-driver
  ];

  boot.blacklistedKernelModules = [ "nouveau" ];
}
