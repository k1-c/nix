{
  services.swaync = {
    enable = true;
    settings = {
      positionX = "right";
      positionY = "top";
      control-center-width = 380;
      notification-window-width = 360;
      notification-icon-size = 48;
      timeout = 8;
      timeout-low = 4;
      timeout-critical = 0;
      fit-to-screen = true;
    };
    style = ''
      * { font-family: "JetBrainsMono Nerd Font", "Noto Sans CJK JP", sans-serif; }
      .notification-row, .control-center {
        background: rgba(20, 20, 30, 0.85);
        color: #e6e6e6;
        border-radius: 12px;
      }
      .notification { padding: 8px; }
    '';
  };
}
