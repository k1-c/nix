{ pkgs, inputs, ... }:

{
  # Phase 2 で ghostty (Mitchell Hashimoto 製の GPU 加速ターミナル) に移行。
  # home-manager 25.11 には programs.ghostty モジュールが無いので
  # ~/.config/ghostty/config を xdg.configFile で直書きする。
  # pkgs.ghostty (1.3.1) ではなく upstream main を使う。
  # 理由は下の background-blur の NOTE 参照 (COSMIC の blur プロトコル対応が
  # リリース版に入っていない)。1.4.0 が nixpkgs に来たら with pkgs; [ ghostty ] に戻す。
  home.packages = [ inputs.ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default ];

  xdg.configFile."ghostty/config".text = ''
    # ─── 外観 ────────────────────────────────────────────────
    theme = Catppuccin Mocha
    # blur 前提の値。blur が効かないコンポジタだと透けすぎて読みにくいので、
    # upstream main を外して 1.3.1 に戻す時は 0.9 前後まで上げる。
    background-opacity = 0.6
    window-padding-x = 8
    window-padding-y = 8
    # `server` = xdg-decoration-unstable-v1 で WM に装飾を任せる。
    #   Plasma: KWin が Breeze タイトルバーを SSD で描く (移動/リサイズ可)。
    #   Hyprland: SSD を強く描かないので、結果的に従来の裸タイル見た目に近い。
    # `false` (= none) は Plasma で「ドラッグ領域ゼロ窓」になるので NG。
    window-decoration = server

    # ─── フォント ────────────────────────────────────────────
    font-family = JetBrainsMono Nerd Font
    font-size = 11

    # ─── 体験 ────────────────────────────────────────────────
    # blur を有効化 (ON/OFF のみ)。
    # Hyprland では radius として効くが、Plasma (KWin) では radius は無視されて
    # ON/OFF のみ。強度は home/k1nix/desktop/plasma.nix の Effect-blur / Effect-forceblur で制御。
    #
    # NOTE: blur の出どころはセッションごとに違う (実機で protocol / binary を確認済み)。
    #   COSMIC   : cosmic-comp 1.6.0 は ext_background_effect_manager_v1 のみ。
    #              client が blur region を要求する方式。
    #   Plasma   : KWin 6.5.6 は org_kde_kwin_blur のみ (ext は 6.7 から)。ただし
    #              plasma.nix の forceblur が BlurNonMatching=true で全窓を強制 blur
    #              するので、client 側がプロトコルを喋らなくても見た目は保たれる。
    #   Hyprland : 0.52.1 はどちらのプロトコルも実装せず、blur は完全に
    #              コンポジタ設定駆動。この行の有無に関係なく透過窓が blur される。
    # ghostty main は org_kde_kwin_blur を捨てて ext_background_effect に移行済みなので、
    # 上表の通り 4 セッションすべてで frosted glass になる。
    # (リリース版 1.3.1 は ext 未対応 = COSMIC だけ blur が効かない。flake.nix 参照)
    background-blur = true
    cursor-style = block
    cursor-style-blink = true
    copy-on-select = clipboard
    confirm-close-surface = false
    mouse-hide-while-typing = true
    shell-integration = detect
    shell-integration-features = cursor,sudo,title
  '';
}
