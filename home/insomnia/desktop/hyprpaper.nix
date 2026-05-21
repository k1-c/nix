{ pkgs, ... }:

{
  # 以前は services.hyprpaper.enable を使っていたが、壁紙ファイル未設定で
  # "Monitor HDMI-A-3 does not have a target! A wallpaper will not be created."
  # となり背景が常に真っ黒だった。代わりに swaybg を niri spawn-at-startup から
  # 単色 (#1e1e2e) で起動する方針に変更 (home/insomnia/desktop/niri.nix 参照)。
  # 壁紙画像を使う運用に移る時はここで services.hyprpaper を復活させる。
  home.packages = with pkgs; [
    swaybg
  ];
}
