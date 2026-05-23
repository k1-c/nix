{ pkgs }:

# Better Blur (旧 kwin-effects-forceblur) - 全ウィンドウに強制的に blur を適用する KWin effect。
# KWin 標準の Blur はアプリ側が _KDE_NET_WM_BLUR_BEHIND_REGION (X11) or
# org_kde_kwin_blur (Wayland) を要求した時のみ効くが、Chrome/Electron 系は要求しない。
# これを入れると Chrome を含むあらゆるウィンドウが Liquid Glass に乗る。
#
# KWin の plugin 検索パスは Qt6 plugin path に依存するので、
# environment.systemPackages 経由で入れれば自動的に検出される。
pkgs.stdenv.mkDerivation rec {
  pname = "kwin-effects-forceblur";
  version = "1.5.0";

  src = pkgs.fetchFromGitHub {
    owner = "taj-ny";
    repo = "kwin-effects-forceblur";
    rev = "v${version}";
    hash = "sha256-DrEPXNLEOXaOmx07RCH4H+u8SLKHtZXihd+Wjg/ZV1U=";
  };

  nativeBuildInputs = with pkgs; [
    cmake
    pkg-config
    kdePackages.extra-cmake-modules
    kdePackages.wrapQtAppsHook
  ];

  buildInputs = with pkgs; [
    libepoxy
    xorg.libxcb
  ] ++ (with pkgs.kdePackages; [
    qtbase
    qtdeclarative
    qttools          # Qt6UiTools (kcfg → UI 自動生成に必要)
    kwin
    kdecoration
    kcmutils
    kconfig
    kconfigwidgets
    kcoreaddons
    kcrash
    kguiaddons
    kglobalaccel
    ki18n
    kio
    knotifications
    kwindowsystem
    plasma-workspace
    kdeclarative
  ]);

  meta = with pkgs.lib; {
    description = "KWin effect that applies blur to all windows regardless of compositor hints";
    homepage = "https://github.com/taj-ny/kwin-effects-forceblur";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
  };
}
