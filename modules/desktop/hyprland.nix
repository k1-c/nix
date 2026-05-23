{ pkgs, ... }:

{
  # SDDM の Wayland セッション一覧に "Hyprland" を追加。
  # programs.hyprland が polkit / xwayland / wrapper をまとめて面倒見てくれる。
  # ユーザー側の binds / decoration / animation は home-manager の
  # wayland.windowManager.hyprland 設定で行う (home/k1nix/desktop/hyprland.nix)。
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Hyprland 専用 portal。screencast / global shortcut の挙動が Hyprland セッションで
  # 安定する。common.nix の gnome/gtk portal と併用しても、Hyprland セッション時は
  # XDG_CURRENT_DESKTOP=Hyprland によって自動でこちらが優先される。
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];

  # Hyprland 固有のユーティリティ。
  # Wayland 共通 (wl-clipboard / grim / slurp / pamixer 等) は
  # modules/desktop/niri.nix 側で既に入っているのでここでは扱わない。
  environment.systemPackages = with pkgs; [
    hyprpicker  # 画面の色を拾うピッカー (waybar クリック等から呼ぶ用途)
    hyprshot    # 領域・ウィンドウ単位 SS の Hyprland 用ラッパー
  ];
}
