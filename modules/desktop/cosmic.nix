{ lib, pkgs-cosmic, ... }:

let
  # COSMIC は cosmic-comp / cosmic-panel / cosmic-applets などが private な
  # Wayland protocol と設定スキーマで会話するため、世代を混ぜると起動しない。
  # 「一式まとめて unstable 側 (1.6.0) に揃える」のが前提で、下のリストは
  # nixpkgs の cosmic module が参照するパッケージ名を並べたもの。
  # glib / playerctl / pulseaudio / networkmanagerapplet 等の汎用パッケージは
  # 25.11 のまま使う (差し替えると system 全体に波及して closure が膨らむ)。
  cosmicPkgNames = [
    "cosmic-app-library"
    "cosmic-applets"
    "cosmic-bg"
    "cosmic-comp"
    "cosmic-edit"
    "cosmic-files"
    "cosmic-greeter"
    "cosmic-icons"
    "cosmic-idle"
    "cosmic-initial-setup"
    "cosmic-launcher"
    "cosmic-monitor"
    "cosmic-notifications"
    "cosmic-osd"
    "cosmic-panel"
    "cosmic-player"
    "cosmic-randr"
    "cosmic-reader"
    "cosmic-screenshot"
    "cosmic-session"
    "cosmic-settings"
    "cosmic-settings-daemon"
    "cosmic-sound-theme"
    "cosmic-store"
    "cosmic-term"
    "cosmic-wallpapers"
    "cosmic-workspaces-epoch"
    "xdg-desktop-portal-cosmic"
    # cosmic-launcher は pop-launcher を IPC で叩くので世代を合わせる。
    "pop-launcher"
    "pop-icon-theme"
  ];
in
{
  # module 本体は nixpkgs 25.11 側 (services.desktopManager.cosmic) をそのまま使い、
  # パッケージだけ unstable の 1.6.0 に差し替える方式。
  # unstable 側の module を disabledModules + imports で持ち込む手も試したが、
  # あちらは security.polkit.enablePkexecWrapper (25.11 に存在しない option) を
  # 定義するため評価できない。25.11 module ↔ 1.6.0 パッケージの差分は
  #   - cosmic-applibrary → cosmic-app-library のリネーム (下の overlay で吸収)
  #   - cosmic-monitor / cosmic-reader / cosmic-sound-theme の新設
  #     (25.11 module は知らないので environment.systemPackages に手で足す)
  # だけなので、こちらの向きの方が壊れる箇所が少ない。
  nixpkgs.overlays = [
    (final: prev:
      lib.genAttrs cosmicPkgNames (name: pkgs-cosmic.${name})
      // {
        # 25.11 の module は旧名で参照するので別名を張る。
        cosmic-applibrary = pkgs-cosmic.cosmic-app-library;
      })
  ];

  services.desktopManager.cosmic.enable = true;

  # 1.6.0 で追加され、25.11 の module がまだ知らないもの。
  environment.systemPackages = [
    pkgs-cosmic.cosmic-monitor
    pkgs-cosmic.cosmic-reader
    pkgs-cosmic.cosmic-sound-theme
  ];

  # NOTE: cosmic-greeter は入れない。SDDM のセッション一覧に "COSMIC" が
  # 増えるだけで、defaultSession は modules/desktop/common.nix の "plasma"
  # のまま。COSMIC はログイン時に明示的に選ぶ運用にする。
  #
  # NOTE: Frosted Glass (COSMIC 1.3+) はコンパイル時フラグではなく実行時設定。
  # 有効化は COSMIC セッションにログインしてから
  # Settings → Desktop → Appearance で、パネル / メニュー / ウィンドウ /
  # オーバービュー / OSD ごとに frost の厚みと不透明度を調整する。
  #
  # NOTE: cosmic-comp は unstable 側の mesa にリンクするが、実際の GPU driver は
  # system 側 (25.11) の /run/opengl-driver から来る世代混在構成。mind は
  # Intel iGPU なので EGL/GBM の ABI 差で問題が出にくい前提で入れている。
  # NVIDIA 機 (insomnia) に広げる時はここが最初の疑い所。
}
