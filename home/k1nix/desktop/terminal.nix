{ pkgs, ... }:

{
  # Phase 2 で ghostty (Mitchell Hashimoto 製の GPU 加速ターミナル) に移行。
  # home-manager 25.11 には programs.ghostty モジュールが無いので
  # ~/.config/ghostty/config を xdg.configFile で直書きする。
  home.packages = with pkgs; [ ghostty ];

  xdg.configFile."ghostty/config".text = ''
    # ─── 外観 ────────────────────────────────────────────────
    theme = Catppuccin Mocha
    background-opacity = 0.92
    window-padding-x = 8
    window-padding-y = 8
    window-decoration = false

    # ─── フォント ────────────────────────────────────────────
    font-family = JetBrainsMono Nerd Font
    font-size = 11

    # ─── 体験 ────────────────────────────────────────────────
    # Hyprland の blur が効くように background-blur を有効化
    background-blur = true
    cursor-style = block
    cursor-style-blink = true
    copy-on-select = clipboard
    confirm-close-surface = false
    mouse-hide-while-typing = true
    shell-integration = detect
    shell-integration-features = cursor,sudo,title
  '';
}
