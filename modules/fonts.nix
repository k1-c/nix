{ pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      # defaultFonts.serif が "Noto Serif CJK JP" を指すので実体が要る。
      # 入れ忘れていると fc-match serif が次の候補 (Noto Color Emoji) に落ちる。
      noto-fonts-cjk-serif
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
        # monospace を明示しないと、ターミナルの CJK フォールバックが
        # プロポーショナルの "Noto Sans CJK JP" に落ちる。
        # Ghostty はフォールバックフェイスを「等幅送り幅 → セル幅」に合わせて
        # スケールするため、等幅送り幅を持たないフェイスだとスケールが効かず、
        # 漢字 (1000 units) がセル 2 個分 (JetBrainsMono 600 x 2 = 1200 units) の
        # 中に素のサイズで置かれる = 日本語だけ約 83% に縮んで隙間が空く。
        # "Noto Sans Mono CJK JP" は M=500 / 漢字=1000 なので x1.2 されて
        # 漢字がちょうど 2 セルに収まる。
        monospace = [
          "JetBrainsMono Nerd Font"
          "Noto Sans Mono CJK JP"
          "Noto Color Emoji"
        ];
        serif = [
          "Noto Serif CJK JP"
          "Noto Color Emoji"
        ];
        sansSerif = [
          "Noto Sans CJK JP"
          "Noto Color Emoji"
        ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
