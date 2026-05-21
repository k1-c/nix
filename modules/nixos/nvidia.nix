{ config, lib, pkgs, ... }:

{
  services.xserver.videoDrivers = [ "nvidia" ];

  # NVIDIA RTX 3070 (Ampere/GA104) のシングル GPU 運用前提。
  # モニタは NVIDIA HDMI に直結、iGPU には何も繋がっていないので PRIME 不要。
  # Niri (Wayland) を安定して動かすため、proprietary kernel module ではなく
  # open kernel module を使う (Turing+ で必須化されつつある)。
  hardware.nvidia = {
    open = lib.mkForce true;       # hosts/nixos/hardware-configuration.nix の `open = false` を上書き
    modesetting.enable = true;     # hardware-configuration.nix で既に true
    nvidiaSettings = true;
    powerManagement.enable = true; # suspend / resume の安定性向上
    # NOTE: hardware.nvidia.package を上書きしてはいけない (誤って `.open` 単体を
    # 指定すると userspace passthru `useProfiles` 等が欠ける)。
    # NixOS の nvidia module は open=true の時、フル package (proprietary) を
    # cfg.package に保ちつつ、extraModulePackages を `nvidia_x11.open` に切替える。
  };

  # NVIDIA + Wayland (Niri) 安定化の定番カーネルパラメータ。
  # nvidia-drm.fbdev=1 は driver 545+ で導入された新フレームバッファ経路。
  # ブートロード時の黒画面リスクを減らす。
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
  ];

  environment.sessionVariables = {
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
    NVD_BACKEND = "direct";
    # NVIDIA + Wayland でカーソル消失 / 起動直後ブラックアウトを防ぐ。
    # Niri 初回ログインで真っ黒になった経験から有効化。
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  # VA-API 経由のハードウェアデコード (ブラウザ等で利用)。
  hardware.graphics.extraPackages = with pkgs; [
    nvidia-vaapi-driver
  ];
}
