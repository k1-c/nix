{ pkgs, ... }:

{
  programs.firefox.enable = true;

  # 汎用 Linux 向けの動的リンクバイナリ (oklch-color-picker, prebuilt language
  # servers, mise が落としてくる toolchain など) を NixOS でも実行できるようにする。
  # https://nix.dev/permalink/stub-ld
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      openssl
      glib
      gtk3
      nss
      nspr
      atk
      cups
      dbus
      libdrm
      libxkbcommon
      mesa
      expat
      libGL
      pango
      cairo
      xorg.libX11
      xorg.libXcomposite
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXrandr
      xorg.libxcb
      alsa-lib
    ];
  };
}
