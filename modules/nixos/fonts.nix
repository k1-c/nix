{ pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      terminus_font
      cantarell-fonts
      nerd-fonts.meslo-lg
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
    ];
    fontDir.enable = true;
    fontconfig = {
      defaultFonts = {
        serif = [
          "Noto Serif CJK JP"
          "Noto Color Emoji"
        ];
        sansSerif = [
          "Noto Sans CJK JP"
          "Noto Clor Emoji"
        ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
