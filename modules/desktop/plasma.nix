{ pkgs, ... }:

let
  klassy = pkgs.callPackage ./klassy.nix { };
  kwinEffectsForceBlur = pkgs.callPackage ./kwin-effects-forceblur.nix { };
in
{
  # SDDM 上で Plasma セッションを選択可能にする。
  # defaultSession = "plasma" は modules/desktop/common.nix で設定済みで、
  # これは Plasma 6 の Wayland セッション (X11 側は "plasmax11") を指す。
  services.desktopManager.plasma6.enable = true;

  # KWin の Wayland セッションで使う追加エフェクト。
  # Liquid Glass 構成:
  #   - klassy: 半透明タイトルバー + 角丸を内包する window decoration。
  #     Plasma の角丸 effect (kde-rounded-corners) は Klassy と機能重複かつ
  #     描画干渉しやすいので削除した。
  #   - kwin-effects-forceblur: Chrome/Electron 等の blur 非対応アプリにも強制 blur を適用。
  environment.systemPackages = [
    klassy
    kwinEffectsForceBlur
    # smart-video-wallpaper-reborn の FadePlayer.qml が import QtMultimedia するため、
    # システム側に QML モジュールを置いて plasmashell の QML import path から見えるようにする。
    # 無いと壁紙 QML が読み込み失敗し、desktopcontainment ごと死んで Plasma panel が描画されない。
    pkgs.kdePackages.qtmultimedia
  ];
}
