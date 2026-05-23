{ pkgs, ... }:

{
  # Phase 2 では軽量に waybar を使う。
  # Phase 3 で AGS/Astal に乗り換える際は本ファイル丸ごと差し替え予定。
  programs.waybar = {
    enable = true;
    # graphical-session.target 連動で起動する。
    # Niri 側の spawn-at-startup は意図的に外しているので二重起動しない。
    # systemd 経由なら niri IPC が確実に上がってから waybar が起動して
    # niri/workspaces モジュールが繋がる。
    systemd.enable = true;
    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 28;
      spacing = 6;
      modules-left = [ "niri/workspaces" "niri/window" ];
      modules-center = [ "clock" ];
      modules-right = [ "pulseaudio" "network" "battery" "tray" ];

      "niri/workspaces" = {
        format = "{index}";
      };
      "niri/window" = {
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
}
