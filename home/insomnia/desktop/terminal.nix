{
  # 軽量・どこでも動く前提で alacritty を採用。気が変わったら ghostty / kitty / wezterm に差し替え。
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        opacity = 0.92;
        padding = { x = 8; y = 8; };
      };
      font = {
        normal = { family = "JetBrainsMono Nerd Font"; style = "Regular"; };
        size = 11.0;
      };
      colors.primary = {
        background = "#1e1e2e";
        foreground = "#cdd6f4";
      };
    };
  };
}
