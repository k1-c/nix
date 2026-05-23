{ pkgs, lib, ... }:

let
  mod = "SUPER";
in
{
  # Hyprland はリッチに振る方針。Niri は最小機能性重視、Hyprland は見た目・体験重視。
  # NVIDIA + Wayland 用の env (WLR_NO_HARDWARE_CURSORS / GBM_BACKEND 等) は
  # hosts/insomnia/nvidia.nix でシステム全体に設定済み。dwarf では NVIDIA 無しで素直に動く。

  # ディスプレイ設定 GUI。配置・解像度・スケール・回転を GUI で調整して
  # ~/.config/hypr/monitors.conf と workspaces.conf に書き出してくれる。
  home.packages = with pkgs; [ nwg-displays ];

  # nwg-displays の出力先ファイルを事前に空で用意しておく。
  # hyprland の `source = ...` は対象ファイルが存在しないとパースエラーになるので、
  # 初回 switch 時点で必ず存在することを activation で保証する。
  home.activation.ensureHyprDisplayConfigs =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p "$HOME/.config/hypr"
      [ -e "$HOME/.config/hypr/monitors.conf" ]   || run touch "$HOME/.config/hypr/monitors.conf"
      [ -e "$HOME/.config/hypr/workspaces.conf" ] || run touch "$HOME/.config/hypr/workspaces.conf"
    '';

  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      "$mod" = mod;

      # ─── 起動時に立ち上げるサービス ────────────────────────────────────
      # waybar / swaync / cliphist / walker は home-manager の systemd user unit が
      # graphical-session.target 連動で勝手に起動するので exec-once しない (二重起動防止)。
      # start-wallpaper は mpvpaper (動画) → swaybg (画像/単色) の順でフォールバックするラッパー。
      # 配置場所は ~/.config/wallpaper/animated.{mp4,webm,...} / static.{png,jpg,...}。
      exec-once = [
        "start-wallpaper"
        "fcitx5 -d --replace"
      ];

      monitor = ",preferred,auto,1";

      # nwg-displays が書き出すモニタ/ワークスペース設定を読み込む。
      # 個別の monitor = 指定があれば上のワイルドカードより優先される。
      source = [
        "~/.config/hypr/monitors.conf"
        "~/.config/hypr/workspaces.conf"
      ];

      input = {
        kb_layout = "us";
        follow_mouse = 0;            # focus-follows-mouse 無効 (Niri と揃える)
        accel_profile = "flat";
        touchpad = {
          natural_scroll = true;
          tap-to-click = true;
          disable_while_typing = true;
        };
      };

      general = {
        gaps_in = 6;
        gaps_out = 12;
        border_size = 2;
        "col.active_border" = "rgba(88c0d0ff) rgba(81a1c1ff) 45deg";
        "col.inactive_border" = "rgba(3b4252aa)";
        layout = "dwindle";
        resize_on_border = true;
      };

      decoration = {
        rounding = 10;
        active_opacity = 1.0;
        inactive_opacity = 0.95;
        blur = {
          enabled = true;
          size = 6;
          passes = 2;
          new_optimizations = true;
          xray = false;
        };
        shadow = {
          enabled = true;
          range = 20;
          render_power = 3;
          color = "rgba(00000088)";
        };
      };

      animations = {
        enabled = true;
        bezier = [
          "easeOutCubic, 0.33, 1.0, 0.68, 1.0"
          "easeOutBack,  0.34, 1.56, 0.64, 1.0"
        ];
        animation = [
          "windows,           1, 4, easeOutCubic, slide"
          "windowsOut,        1, 4, easeOutCubic, slide"
          "border,            1, 6, default"
          "fade,              1, 4, default"
          "workspaces,        1, 5, easeOutCubic, slide"
          "specialWorkspace,  1, 5, easeOutBack,  slidevert"
        ];
      };

      dwindle = {
        preserve_split = true;
        pseudotile = true;
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        focus_on_activate = true;
        animate_manual_resizes = true;
      };

      # IME (fcitx5) と XDG 関連 env。
      # XDG_CURRENT_DESKTOP=Hyprland にしておくと xdg-desktop-portal-hyprland が
      # 確実に選択され、screencast / global shortcut が安定する。
      env = [
        "QT_QPA_PLATFORM,wayland"
        "MOZ_ENABLE_WAYLAND,1"
        "XMODIFIERS,@im=fcitx"
        "GTK_IM_MODULE,fcitx"
        "QT_IM_MODULE,fcitx"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"
      ];

      bind = [
        # アプリ起動
        "$mod,       Return, exec, walker"
        "$mod,       T,      exec, ghostty"
        "$mod,       D,      exec, walker"  # 旧バインドの互換用 (慣れたら削除可)
        "$mod,       L,      exec, hyprlock"
        "$mod SHIFT, M,      exec, nwg-displays"
        # cliphist は walker でなく fuzzel --dmenu に通す。walker の clipboard module は
        # 自前 store を使うので、systemd 経由で常時走っている cliphist のヒストリと合わない。
        "$mod,       V,      exec, cliphist list | fuzzel --dmenu | cliphist decode | wl-copy"

        # ウィンドウ操作
        "$mod,       Q,      killactive,"
        "$mod,       F,      fullscreen, 1"   # maximize 相当 (gap/border 残す)
        "$mod SHIFT, F,      fullscreen, 0"   # 完全フルスクリーン
        "$mod,       Space,  togglefloating,"
        "$mod,       P,      pseudo,"
        "$mod,       J,      togglesplit,"

        # フォーカス
        "$mod,       Left,   movefocus, l"
        "$mod,       Right,  movefocus, r"
        "$mod,       Up,     movefocus, u"
        "$mod,       Down,   movefocus, d"

        # ウィンドウ移動
        "$mod SHIFT, Left,   movewindow, l"
        "$mod SHIFT, Right,  movewindow, r"
        "$mod SHIFT, Up,     movewindow, u"
        "$mod SHIFT, Down,   movewindow, d"

        # ワークスペース
        "$mod,       1,      workspace, 1"
        "$mod,       2,      workspace, 2"
        "$mod,       3,      workspace, 3"
        "$mod,       4,      workspace, 4"
        "$mod SHIFT, 1,      movetoworkspace, 1"
        "$mod SHIFT, 2,      movetoworkspace, 2"
        "$mod SHIFT, 3,      movetoworkspace, 3"
        "$mod SHIFT, 4,      movetoworkspace, 4"

        # special workspace (scratchpad)
        "$mod,       grave,  togglespecialworkspace, scratch"
        "$mod SHIFT, grave,  movetoworkspace, special:scratch"

        # スクリーンショット (hyprshot)
        ",           Print,  exec, hyprshot -m output"
        "$mod,       Print,  exec, hyprshot -m window"
        "SHIFT,      Print,  exec, hyprshot -m region"
      ];

      # マウスでウィンドウ移動/リサイズ
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      # 音量・輝度 (リピート可能)
      bindel = [
        ",XF86AudioRaiseVolume,  exec, pamixer -i 5"
        ",XF86AudioLowerVolume,  exec, pamixer -d 5"
        ",XF86MonBrightnessUp,   exec, brightnessctl set +5%"
        ",XF86MonBrightnessDown, exec, brightnessctl set 5%-"
      ];
      bindl = [
        ",XF86AudioMute, exec, pamixer -t"
        ",XF86AudioPlay, exec, playerctl play-pause"
        ",XF86AudioNext, exec, playerctl next"
        ",XF86AudioPrev, exec, playerctl previous"
      ];

      windowrulev2 = [
        # PiP は常に float / 最前面
        "float, title:^(Picture-in-Picture)$"
        "pin,   title:^(Picture-in-Picture)$"
        # ミニウィンドウ系は float
        "float, class:^(pavucontrol)$"
        "float, class:^(nm-connection-editor)$"
        # スクリーンショットのフラッシュはアニメ無しでチラつきを抑える
        "noanim, class:^(hyprshot)$"
      ];

      workspace = [
        "1, default:true"
      ];
    };
  };

  # NOTE: home/k1nix/desktop/waybar.nix は Niri 想定の niri/workspaces, niri/window を
  # 使っているため、Hyprland セッション下ではこれらのモジュールが空表示になる。
  # 完全対応するには hyprland/workspaces, hyprland/window モジュールに分岐させる必要あり。
  # Phase 2 で waybar を DE 中立な構成 (clock/network/battery のみ) に整理する予定。
}
