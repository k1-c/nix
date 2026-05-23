{ pkgs, lib, ... }:

let
  # Phase 1 はまず Plasma 並行運用の前提で「最小・floating多めの Plasma っぽい起点」に寄せる。
  # 慣れてきたら gaps / focus-ring / binds をリッチに育てる方針。
  mod = "Mod"; # Super key (niri では Mod = Super)
in
{
  programs.niri.settings = {
    input = {
      keyboard.xkb = {
        layout = "us";
      };
      touchpad = {
        tap = true;
        natural-scroll = true;
        dwt = true;
      };
      mouse.accel-profile = "flat";
      focus-follows-mouse.enable = false;
    };

    layout = {
      gaps = 8;
      border = {
        enable = false;
        width = 2;
      };
      focus-ring = {
        enable = true;
        width = 2;
      };
      preset-column-widths = [
        { proportion = 1.0 / 3.0; }
        { proportion = 1.0 / 2.0; }
        { proportion = 2.0 / 3.0; }
      ];
      default-column-width.proportion = 1.0 / 2.0;
    };

    prefer-no-csd = true;
    hotkey-overlay.skip-at-startup = true;

    # NVIDIA + Niri の "Page flip commit failed (EINVAL)" 黒画面ワークアラウンド。
    # ハードウェアカーソルプレーンと direct scanout を切ると NVIDIA driver が
    # 弾く atomic commit パターンを回避できる。動作確認後、片方ずつ外して検証可能。
    debug = {
      disable-cursor-plane = { };
      disable-direct-scanout = { };
    };

    # waybar / swaync / hyprpaper(swaybg) / cliphist は home-manager の
    # systemd user unit で graphical-session.target 連動で起動するので
    # ここでは spawn-at-startup しない (二重起動でエラーループになる)。
    # 最低限の即時起動だけここで:
    #  - swaybg: 単色背景 (壁紙画像が無い状態でも画面が真っ黒に見えない)
    #  - fcitx5: NixOS の i18n.inputMethod は session 起動を保証しない
    spawn-at-startup = [
      { command = [ "swaybg" "-c" "#1e1e2e" ]; }
      { command = [ "fcitx5" "-d" "--replace" ]; }
    ];

    environment = {
      # 注: DISPLAY=:0 を Niri (Wayland) で立てると XWayland 経由のアプリが
      # 壊れた接続を引くことがあるので未指定。
      QT_QPA_PLATFORM = "wayland";
      MOZ_ENABLE_WAYLAND = "1";
      XMODIFIERS = "@im=fcitx";
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
    };

    binds = {
      "${mod}+Return".action.spawn = "alacritty";
      "${mod}+D".action.spawn = "fuzzel";
      "${mod}+L".action.spawn = "hyprlock";
      "${mod}+Q".action = { close-window = { }; };

      "${mod}+Left".action  = { focus-column-left  = { }; };
      "${mod}+Right".action = { focus-column-right = { }; };
      "${mod}+Up".action    = { focus-window-up    = { }; };
      "${mod}+Down".action  = { focus-window-down  = { }; };

      "${mod}+Shift+Left".action  = { move-column-left  = { }; };
      "${mod}+Shift+Right".action = { move-column-right = { }; };
      "${mod}+Shift+Up".action    = { move-window-up    = { }; };
      "${mod}+Shift+Down".action  = { move-window-down  = { }; };

      "${mod}+1".action = { focus-workspace = 1; };
      "${mod}+2".action = { focus-workspace = 2; };
      "${mod}+3".action = { focus-workspace = 3; };
      "${mod}+4".action = { focus-workspace = 4; };

      "${mod}+Shift+1".action = { move-column-to-workspace = 1; };
      "${mod}+Shift+2".action = { move-column-to-workspace = 2; };
      "${mod}+Shift+3".action = { move-column-to-workspace = 3; };
      "${mod}+Shift+4".action = { move-column-to-workspace = 4; };

      "${mod}+F".action      = { maximize-column = { }; };
      "${mod}+Shift+F".action = { fullscreen-window = { }; };
      "${mod}+R".action      = { switch-preset-column-width = { }; };

      "Print".action = { screenshot = { }; };

      "XF86AudioRaiseVolume".action.spawn = [ "pamixer" "-i" "5" ];
      "XF86AudioLowerVolume".action.spawn = [ "pamixer" "-d" "5" ];
      "XF86AudioMute".action.spawn        = [ "pamixer" "-t" ];
      "XF86MonBrightnessUp".action.spawn   = [ "brightnessctl" "set" "+5%" ];
      "XF86MonBrightnessDown".action.spawn = [ "brightnessctl" "set" "5%-" ];
    };
  };
}
