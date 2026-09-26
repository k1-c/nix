{ pkgs, lib, ... }:

{
  # Phase 2 では軽量に waybar を使う。
  # Phase 3 で AGS/Astal に乗り換える際は本ファイル丸ごと差し替え予定。
  programs.waybar = {
    enable = true;
    # graphical-session.target 連動で起動する。
    # systemd 経由なら compositor の IPC が確実に上がってから waybar が起動して
    # hyprland/workspaces モジュールが繋がる。
    systemd.enable = true;
    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 28;
      spacing = 6;
      modules-left = [ "hyprland/workspaces" "hyprland/window" ];
      modules-center = [ "clock" ];
      modules-right = [ "pulseaudio" "network" "battery" "tray" ];

      "hyprland/workspaces" = {
        format = "{id}";
      };
      "hyprland/window" = {
        format = "{title}";
        max-length = 60;
      };
      clock = {
        format = "{:%Y-%m-%d %H:%M}";
      };
      battery = {
        format = "{capacity}% {icon}";
        format-icons = [ "" "" "" "" "" ];
      };
      network = {
        format-wifi = "{essid} ({signalStrength}%) ";
        format-ethernet = "{ifname} ";
        format-disconnected = "✗";
      };
      pulseaudio = {
        format = "{volume}% {icon}";
        format-muted = "muted";
        format-icons.default = [ "" "" "" ];
        on-click = "pavucontrol";
      };
      tray.spacing = 8;
    };
    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font", "Noto Sans CJK JP", sans-serif;
        font-size: 12px;
      }
      window#waybar {
        background: rgba(20, 20, 30, 0.65);
        color: #e6e6e6;
      }
      #workspaces button {
        padding: 0 8px;
        color: #b0b0b0;
        background: transparent;
        border-bottom: 2px solid transparent;
      }
      #workspaces button.active {
        color: #ffffff;
        border-bottom: 2px solid #88c0d0;
      }
      #clock, #battery, #network, #pulseaudio, #tray {
        padding: 0 8px;
      }
    '';
  };

  # COSMIC セッションでは cosmic-panel が同じ役割を担うので waybar は出さない。
  # セッションは SDDM でログイン時に選ぶ運用なので eval 時には判定できず、
  # unit 側の ConditionEnvironment で起動時に弾く
  # (cosmic-session が systemd user manager に XDG_CURRENT_DESKTOP=COSMIC を入れる)。
  # home-manager 側が既に ConditionEnvironment = "WAYLAND_DISPLAY" を string で
  # 定義しているため mkForce でリストに差し替える。同じ Condition* が複数行あると
  # systemd は AND で評価するので「Wayland かつ COSMIC ではない」条件になる。
  systemd.user.services.waybar.Unit.ConditionEnvironment = lib.mkForce [
    "WAYLAND_DISPLAY"
    "!XDG_CURRENT_DESKTOP=COSMIC"
  ];
}
