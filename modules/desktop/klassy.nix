{ pkgs }:

# Klassy - Plasma 6 用の高機能 window decoration / Qt style / 色テーマ統合パッケージ。
# 半透明タイトルバー・角丸・blur 領域指定をネイティブに持ち、Liquid Glass の中核を担う。
#
# 上流の install.sh は `cmake -DKDE_INSTALL_USE_QT_SYS_PATHS=ON -DCMAKE_INSTALL_PREFIX=/usr`
# で system に直書きするスクリプト。Nix では当然そのままは使わず、
# ECM の規約に従って $out 配下にインストールさせる (Qt の plugin path は
# environment.systemPackages 経由で自動的に統合される)。
#
# BUILD_QT5=OFF: Plasma 6 環境では Qt5 部分は不要かつ Qt5 KF5 が無いと build エラーになる。
pkgs.stdenv.mkDerivation rec {
  pname = "klassy";
  version = "6.5.3";

  src = pkgs.fetchFromGitHub {
    owner = "paulmcauley";
    repo = "klassy";
    rev = "v${version}";
    hash = "sha256-2M1SGmYSEnZ1AlsOvhrM25oQi8mz/H8df4pzyFYybN8=";
  };

  nativeBuildInputs = with pkgs; [
    cmake
    pkg-config
    gettext
    kdePackages.extra-cmake-modules
    kdePackages.wrapQtAppsHook
  ];

  buildInputs = with pkgs.kdePackages; [
    qtbase
    qtdeclarative
    qtsvg
    qttools
    kdecoration
    kcmutils
    kcoreaddons
    kconfig
    kconfigwidgets
    kguiaddons
    ki18n
    kiconthemes
    kwindowsystem
    kcolorscheme
    frameworkintegration
    kirigami
  ];

  cmakeFlags = [
    "-DBUILD_QT5=OFF"
    "-DBUILD_QT6=ON"
    "-DBUILD_TESTING=OFF"
    # KDE_INSTALL_USE_QT_SYS_PATHS は ON にすると Qt の system prefix へ書きに行こうとして失敗するので OFF (default)
  ];

  meta = with pkgs.lib; {
    description = "Highly customizable window decoration, Qt style and color theme for Plasma 6 with translucency and rounded corners";
    homepage = "https://github.com/paulmcauley/klassy";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
  };
}
