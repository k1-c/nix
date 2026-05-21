{
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = "JetBrainsMono Nerd Font:size=12";
        terminal = "alacritty";
        layer = "overlay";
        width = 40;
        lines = 12;
        prompt = "❯ ";
      };
      colors = {
        background = "1e1e2eee";
        text = "cdd6f4ff";
        selection = "313244ff";
        selection-text = "cdd6f4ff";
        border = "88c0d0ff";
      };
      border = {
        width = 1;
        radius = 8;
      };
    };
  };
}
