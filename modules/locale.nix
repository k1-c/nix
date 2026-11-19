{ pkgs, lib, config, ... }:

let
  # Chrome (text-input-v3) + cosmic-comp で、一度パスワード欄にフォーカスすると
  # fcitx5 側の Password フラグが残り続け、以後 Chrome の全入力欄で mozc が強制的に
  # 外れる (fcitx/fcitx5#1676)。activate 時に content type を初期化する上流修正
  # (c23f127e, 5.1.23 に収録) を当てる。nixpkgs の fcitx5 が 5.1.23 以上になったら
  # このパッチと下の package 差し替えは削除する。
  fcitx5Patched = pkgs.fcitx5.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./patches/fcitx5-reset-content-type-on-activate.patch
    ];
  });
in
{
  time.timeZone = "Asia/Tokyo";

  i18n.defaultLocale = "ja_JP.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ja_JP.UTF-8";
    LC_IDENTIFICATION = "ja_JP.UTF-8";
    LC_MEASUREMENT = "ja_JP.UTF-8";
    LC_MONETARY = "ja_JP.UTF-8";
    LC_NAME = "ja_JP.UTF-8";
    LC_NUMERIC = "ja_JP.UTF-8";
    LC_PAPER = "ja_JP.UTF-8";
    LC_TELEPHONE = "ja_JP.UTF-8";
    LC_TIME = "ja_JP.UTF-8";
  };

  i18n.inputMethod = {
    type = "fcitx5";
    enable = true;
    fcitx5.waylandFrontend = true;
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-gtk
    ];
  };

  # overlay で pkgs.fcitx5 を差し替えると fcitx5-mozc まで再ビルドになるため、
  # ラッパーに渡す本体だけをパッチ版にする (アドオンは ABI 互換のまま流用)。
  i18n.inputMethod.package = lib.mkForce (
    pkgs.qt6Packages.fcitx5-with-addons.override {
      fcitx5 = fcitx5Patched;
      inherit (config.i18n.inputMethod.fcitx5) addons;
    }
  );

  # Plasma Wayland では waylandFrontend により GTK_IM_MODULE が未設定になり、
  # GTK アプリ (Ghostty) が Wayland text-input 経路を使う。これが Ghostty 側で
  # 不安定で mozc が時々効かなくなる (ghostty-org/ghostty#12124)。
  # fcitx5-gtk 経由に逃がして安定させる。QT は waylandFrontend のまま触らない。
  environment.sessionVariables.GTK_IM_MODULE = "fcitx";
}
