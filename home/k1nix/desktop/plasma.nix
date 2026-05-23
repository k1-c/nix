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
        # Desktop Entry Spec の Exec 値では ' と | は予約文字なのでダブルクォートで囲む。
        command = ''sh -c "cliphist list | fuzzel --dmenu | cliphist decode | wl-copy"'';
      };
    };

    # --- KWin: Liquid Glass 用のエフェクトとパネル透過 ---
    # plasma-manager の typed options で網羅されていない領域は configFile で直書きする。
    configFile = {
      kwinrc = {
        # 標準 Blur は KDE 対応アプリのみに効く。Chrome/Electron 等を含む
        # 全ウィンドウに適用するため forceblur (Better Blur) を有効化。
        # 両方有効でも forceblur 側が優先される。background contrast はガラス感の補助。
        Plugins = {
          blurEnabled = true;
          forceblurEnabled = true;
          contrastEnabled = true;
          # 視覚的に重くなりがちな effect は無効化。
          wobblywindowsEnabled = false;
          magiclampEnabled = false;
        };

        # Blur effect の強度 (標準 Blur 側)。NVIDIA + Wayland でも問題ない範囲。
        "Effect-blur" = {
          BlurStrength = 12;
          NoiseStrength = 4;
        };

        # forceblur (Better Blur) の設定。ブラー強度と角丸の連動を強めにする。
        "Effect-forceblur" = {
          BlurStrength = 15;
          NoiseStrength = 4;
          # KDE 既定で blur しているウィンドウも上書きして強制適用。
          BlurMatching = true;
          BlurNonMatching = true;
          # 一部の重い窓 (動画再生等) は除外したい場合はここに windowClass を列挙。
          WindowClasses = "";
          # 角丸 (Klassy の角丸量と揃える)。
          RoundedCorners = true;
          CornerRadius = 10;
        };

        # ウィンドウ装飾を Klassy に切替。半透明タイトルバー + 角丸を内包する。
        # 細かい opacity / border 等は plasma の System Settings → Window Decorations →
        # Klassy の "Configure Klassy" GUI から、もしくは klassyrc を configFile で直書きする。
        "org.kde.kdecoration2" = {
          library = "org.kde.klassy";
          theme = "Klassy";
        };
      };

      # Klassy 本体の設定。タイトルバーに半透明 + blur 領域を設定して Liquid Glass にする。
      # 設定キーは Klassy 上流の kdecoration/config/breezeconfigwidget.ui を参照。
      klassyrc = {
        Common = {
          # アクティブ/非アクティブ両方のタイトルバーを半透明化。
          OpaqueMaximizedTitleBars = false;
          # タイトルバーの不透明度 (0-100)。低いほどガラス感が強い。
          ActiveTitleBarOpacity = 60;
          InactiveTitleBarOpacity = 50;
          # タイトルバーに対しても blur 領域を要求 (KWin が blur する)。
          BlurTransparentTitleBars = true;
        };
        Windeco = {
          # 角丸の半径 (px)。Effect-forceblur 側の CornerRadius と揃える。
          CornerRadius = 10;
          DrawBackgroundGradient = false;
        };
      };

      # マウスカーソルテーマ (Plasma 既定)。
      kcminputrc = {
        Mouse.cursorTheme = "breeze_cursors";
      };
    };
  };
}
