{ pkgs, pkgs-unstable, ... }:

{
  programs.firefox.enable = true;

  # 1Password デスクトップアプリ。ブラウザ統合の setuid ラッパー・polkit ポリシー・
  # CLI 連携 (アプリでの生体認証アンロック) をまとめて有効化するため、
  # home.packages ではなく NixOS モジュールで導入する。
  # nixos-25.11 は版が古くなりがちなため、CLI (`op`) と同様 unstable を採用。
  programs._1password = {
    enable = true;
    # nixos-25.11 の op は 2.32.0 と古いため unstable を採用。
    package = pkgs-unstable._1password-cli;
  };
  programs._1password-gui = {
    enable = true;
    package = pkgs-unstable._1password-gui;
    # ブラウザ統合の system authentication を許可するユーザー。
    polkitPolicyOwners = [ "k1nix" ];
  };

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

      # Node.js prebuilt および npm のネイティブ addon (prebuild-install で
      # 落ちてくる .node バイナリ) が dlopen する代表的なライブラリ。
      # mise 経由の node や better-sqlite3 / keytar 等で必要になりやすい。
      libuv
      icu
      sqlite
      libsecret
    ];
  };
}
