{ pkgs, lib, config, ... }:

let
  smartVideoWallpaper = pkgs.callPackage ./smart-video-wallpaper-reborn.nix { };
  pluginId = "luisbocanegra.smart.video.wallpaper.reborn";
  animatedPath = "${config.home.homeDirectory}/.config/wallpaper/animated.mp4";
in
{
  # Plasma 6 (Wayland) のユーザ側設定。Niri/Hyprland 用のリソースとは別 namespace で同居する。
  # walker.service は graphical-session.target に紐付いていて Plasma セッションでも常駐するので、
  # ここではキーバインドだけ与える (KRunner より優先)。

  home.packages = [
    smartVideoWallpaper
  ];

  # KWin がプラグインを探すパスは XDG_DATA_DIRS 経由で home.packages から自動で繋がる。
  # 動画壁紙プラグインはこれで右クリックメニューに登場する。

  programs.plasma = {
    enable = true;

    workspace = {
      # Liquid Glass の素地は Breeze Dark + KWin Blur + Background Contrast。
      # global theme で凝ったものを入れると Plasma update のたびに壊れがちなので、
      # 標準 Breeze をベースに configFile で fine-tuning する戦略。
      lookAndFeel = "org.kde.breezedark.desktop";
      colorScheme = "BreezeDark";
      iconTheme = "breeze-dark";

      # 動画壁紙プラグイン。VideoUrls は plugin が読む JSON 配列の文字列。
      # 単一ファイル指定だが、配列に複数 enabled=true で書けば shuffle/sequence 再生される。
      # 動画ファイルが存在しない場合は黒画面ではなく単色フォールバックされる挙動 (upstream 既定)。
      wallpaperCustomPlugin = {
        plugin = pluginId;
        config.General = {
          VideoUrls = ''[{"filename":"file://${animatedPath}","enabled":true}]'';
          FillMode = "2";        # PreserveAspectCrop
          MuteAudio = "true";
          BlurRadius = "0";
          PauseBatteries = "true"; # バッテリ駆動時は自動停止
        };
      };
    };

    # --- グローバルショートカット (KRunner より優先したい walker を Meta+Return に) ---
    hotkeys.commands = {
      "launch-walker" = {
        name = "Launch Walker";
        key = "Meta+Return";
        command = "walker";
      };
      "launch-walker-d" = {
        name = "Launch Walker (Meta+D)";
        key = "Meta+D";
        command = "walker";
      };
      # cliphist は walker でなく fuzzel --dmenu を使う (Hyprland 側と挙動を揃える)。
      "cliphist-pick" = {
        name = "Clipboard history (cliphist via fuzzel)";
        key = "Meta+V";
        command = "sh -c 'cliphist list | fuzzel --dmenu | cliphist decode | wl-copy'";
      };
    };

    # --- KWin: Liquid Glass 用のエフェクトとパネル透過 ---
    # plasma-manager の typed options で網羅されていない領域は configFile で直書きする。
    configFile = {
      kwinrc = {
        # ビルトインの Blur / Background Contrast を有効化。
        # KWin は _KDE_NET_WM_BLUR_BEHIND_REGION ヒントを持つ Qt/KDE アプリで自動的に効く。
        # GTK 側もパネル/通知/メニューなど多くの面でフロステッド表現になる。
        Plugins = {
          blurEnabled = true;
          contrastEnabled = true;
          # kde-rounded-corners が提供する KWin effect。upstream の CMakeLists.txt に従いプラグイン ID は "shapecorners"。
          shapecornersEnabled = true;
          # 視覚的に重くなりがちな effect は無効化。
          wobblywindowsEnabled = false;
          magiclampEnabled = false;
        };

        # Blur effect の強度。NVIDIA + Wayland でも問題ない範囲。
        "Effect-blur" = {
          BlurStrength = 12;
          NoiseStrength = 4;
        };

        # kde-rounded-corners (shapecorners) の角丸量・縁取り・影。
        "Effect-shapecorners" = {
          Size = 10;
          ShadowSize = 20;
          OutlineThickness = 1;
          DisabledForMaximized = true;
        };

        # ウィンドウ装飾を Breeze に固定 (theme が壊れたときの安全側)。
        "org.kde.kdecoration2" = {
          library = "org.kde.breeze";
          theme = "Breeze";
        };
      };

      # マウスカーソルテーマ (Plasma 既定)。
      kcminputrc = {
        Mouse.cursorTheme = "breeze_cursors";
      };
    };
  };
}
