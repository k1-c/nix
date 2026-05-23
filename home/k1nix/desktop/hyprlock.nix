{
  # Niri 配下でも hyprlock は単体動作する。NVIDIA で問題が出るようなら gtklock に切替予定。
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = true;
        grace = 0;
      };
      background = [
        {
          path = "screenshot";
          blur_passes = 3;
          blur_size = 8;
        }
      ];
      input-field = [
        {
          size = "260, 48";
          position = "0, -80";
          halign = "center";
          valign = "center";
          monitor = "";
          dots_center = true;
          fade_on_empty = true;
          placeholder_text = "<i>Password...</i>";
          rounding = 12;
          outer_color = "rgba(136, 192, 208, 0.7)";
          inner_color = "rgba(30, 30, 46, 0.6)";
          font_color = "rgb(230, 230, 230)";
        }
      ];
      label = [
        {
          text = "$TIME";
          font_size = 64;
          position = "0, 120";
          halign = "center";
          valign = "center";
          color = "rgba(230, 230, 230, 0.95)";
        }
      ];
    };
  };
}
