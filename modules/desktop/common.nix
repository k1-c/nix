{ pkgs, ... }:

{
  # COSMIC (既定) / Plasma / Hyprland を SDDM で切り替えて並行運用する前提の共通設定。
  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
    exportConfiguration = true;
  };

  services.displayManager = {
    sddm = {
      enable = true;
      # Plasma 6 を有効にすると SDDM の greeter が kwin_wayland 経由 (Wayland) に
      # なるが、NVIDIA + open module + nvidia-drm.fbdev=1 の組み合わせで
      # KWin Wayland が "Atomic modeset test failed" で固まり、greeter が
      # 一切表示されなくなる (gen 20 の症状)。X11 greeter に固定して回避する。
      wayland.enable = false;
    };
    # 既定は COSMIC (全ホスト共通)。ブラックアウト等でセッションが死んでも、再ログイン時は
    # 必ず COSMIC が初期選択になるように固定する。Plasma / Hyprland を使いたい時は
    # SDDM のセッション選択で手動で切り替える。セッション名は cosmic-session の
    # wayland-sessions/cosmic.desktop に由来する。
    defaultSession = "cosmic";
  };

  # Chromium / Electron 系 (google-chrome / chromium / slack / vscode 等) を
  # Wayland ネイティブ (Ozone) で起動させる。これが無いと X11/XWayland に
  # フォールバックし、Google Meet 等の画面共有でウィンドウ・全画面が
  # xdg-desktop-portal 経由で列挙されず「タブ共有しか出てこない」状態になる。
  # Wayland ネイティブ起動なら kde portal + PipeWire の共有ピッカーが効く。
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Wayland セッション (Hyprland / AGS / fuzzel / swaync など) で必須になる layer-shell や
  # screencast / file-chooser portal をまとめてここで有効化する。
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
  };

  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;
  programs.dconf.enable = true;

  # Wayland セッション (Hyprland 等) で使う共通ユーティリティ。
  environment.systemPackages = with pkgs; [
    wl-clipboard
    grim
    slurp
    wf-recorder
    brightnessctl
    playerctl
    pamixer
  ];
}
