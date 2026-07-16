{ pkgs, ... }:

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

  # Plasma Wayland では waylandFrontend により GTK_IM_MODULE が未設定になり、
  # GTK アプリ (Ghostty) が Wayland text-input 経路を使う。これが Ghostty 側で
  # 不安定で mozc が時々効かなくなる (ghostty-org/ghostty#12124)。
  # fcitx5-gtk 経由に逃がして安定させる。QT は waylandFrontend のまま触らない。
  environment.sessionVariables.GTK_IM_MODULE = "fcitx";
}
