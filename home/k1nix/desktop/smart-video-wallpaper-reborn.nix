{ pkgs }:

# Plasma 6 用の動画壁紙プラグイン。
# 右クリックメニュー →「壁紙を設定」で "Smart Video Wallpaper Reborn" を選択できるようになる。
# 動画パスは plasma-manager の wallpaperPlugin + plugin config で指定する
# (home/k1nix/desktop/plasma.nix を参照)。
#
# CMakeLists.txt が plasma_install_package で package/ を share/plasma/wallpapers/<id> に入れるが、
# プラグイン本体は QML/JS のみなので実行ビット周りだけ install フックで補正する。
pkgs.stdenv.mkDerivation rec {
  pname = "plasma-smart-video-wallpaper-reborn";
  version = "2.13.0";

  src = pkgs.fetchFromGitHub {
    owner = "luisbocanegra";
    repo = "plasma-smart-video-wallpaper-reborn";
    rev = "v${version}";
    hash = "sha256-X7HazOc+AMo4BGPGwYkledYJ5gYrm0vBeMU2aQMOG+Q=";
  };

  nativeBuildInputs = with pkgs.kdePackages; [
    extra-cmake-modules
    pkgs.cmake
  ];

  buildInputs = with pkgs.kdePackages; [
    plasma-workspace
    ki18n
  ];

  dontWrapQtApps = true;

  meta = with pkgs.lib; {
    description = "Plasma 6 wallpaper plugin that plays videos as wallpaper (mpv-based)";
    homepage = "https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
  };
}
