{ pkgs, ... }:

let
  # 動画があれば mpvpaper、無ければ静止画 swaybg、それも無ければ単色フォールバック。
  # ファイル配置 (どちらも自動検出):
  #   動画: ~/.config/wallpaper/animated.{mp4,webm,mkv,mov,gif}
  #   画像: ~/.config/wallpaper/static.{png,jpg,jpeg}
  # NVIDIA では hwdec=auto-safe で nvidia-vaapi-driver 経由のデコードに乗る。
  startWallpaper = pkgs.writeShellScriptBin "start-wallpaper" ''
    set -eu
    DIR="$HOME/.config/wallpaper"
    mkdir -p "$DIR"
    for ext in mp4 webm mkv mov gif; do
      vid="$DIR/animated.$ext"
      if [ -f "$vid" ]; then
        exec ${pkgs.mpvpaper}/bin/mpvpaper \
          -o "no-audio loop hwdec=auto-safe panscan=1.0 vo=gpu-next" \
          '*' "$vid"
      fi
    done
    for ext in png jpg jpeg; do
      img="$DIR/static.$ext"
      if [ -f "$img" ]; then
        exec ${pkgs.swaybg}/bin/swaybg -i "$img" -m fill
      fi
    done
    exec ${pkgs.swaybg}/bin/swaybg -c '#1e1e2e'
  '';
in
{
  # 元々 services.hyprpaper を使っていたが、壁紙ファイル未設定だと黒画面になる罠があった。
  # Phase 2 では mpvpaper (動画) を最優先、画像 → 単色のフォールバックで一本化する。
  # 起動は Hyprland exec-once から start-wallpaper を呼ぶ (home/k1nix/desktop/hyprland.nix)。
  home.packages = with pkgs; [
    swaybg
    mpvpaper
    startWallpaper
  ];
}
