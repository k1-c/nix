{ pkgs, ... }:

{
  # walker は GTK4 製のモダンなランチャー。
  # applications / runner / calc / clipboard / symbols(emoji) / finder / windows / websearch などを
  # モジュールとして持つ。fuzzel は cliphist 用に残しつつ、メイン launcher を walker に切替。
  #
  # 起動を瞬時にするため `--gapplication-service` で常駐させる。
  # 初回起動後、`walker` (引数なし) で UI が即表示される。
  home.packages = with pkgs; [ walker ];

  systemd.user.services.walker = {
    Unit = {
      Description = "Walker launcher (resident gapplication service)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.walker}/bin/walker --gapplication-service";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # walker は ~/.config/walker/config.toml が無くてもデフォルトで動く。
  # ここでは最小限の上書きと、Catppuccin Mocha 風の CSS だけ用意する。
  # walker のテーマ schema は版間で揺れがあるので、CSS だけで見た目を寄せる方針 (TOML は触らない)。
  xdg.configFile."walker/config.toml".text = ''
    close_when_open = true
    theme = "nix"
  '';

  # 付属の default theme をベースに、Catppuccin Mocha 寄りの色味へ。
  # theme TOML は default theme と同じレイアウトを使うので CSS のみ差し替える。
  xdg.configFile."walker/themes/nix.toml".text = ''
    [ui.anchor]
    top = false
    bottom = false
    left = false
    right = false
  '';

  xdg.configFile."walker/themes/nix.css".text = ''
    @define-color base    #1e1e2e;
    @define-color mantle  #181825;
    @define-color crust   #11111b;
    @define-color text    #cdd6f4;
    @define-color subtext #a6adc8;
    @define-color surface #313244;
    @define-color overlay #6c7086;
    @define-color blue    #89b4fa;
    @define-color sapph   #74c7ec;
    @define-color lav     #b4befe;
    @define-color mauve   #cba6f7;

    * {
      font-family: "JetBrainsMono Nerd Font", "Noto Sans CJK JP", sans-serif;
      font-size: 14px;
    }

    window {
      background: transparent;
    }

    #box {
      background-color: alpha(@base, 0.92);
      border: 2px solid alpha(@sapph, 0.65);
      border-radius: 14px;
      padding: 12px;
      min-width: 620px;
      box-shadow: 0 12px 32px alpha(@crust, 0.6);
    }

    #search, entry, #input {
      background-color: alpha(@surface, 0.55);
      color: @text;
      caret-color: @blue;
      border: none;
      border-radius: 10px;
      padding: 10px 14px;
      margin-bottom: 8px;
    }

    #list {
      background: transparent;
    }

    #list row,
    .item {
      padding: 8px 10px;
      margin: 2px 0;
      border-radius: 8px;
      color: @text;
    }

    #list row:selected,
    #list row:hover,
    .item:selected,
    .item:hover {
      background: alpha(@sapph, 0.18);
      color: @text;
    }

    .label, .title {
      color: @text;
    }
    .sub, .description {
      color: @subtext;
      font-size: 12px;
    }
    .activation-label {
      color: @lav;
      font-weight: bold;
    }
    .spinner {
      color: @blue;
    }
  '';
}
