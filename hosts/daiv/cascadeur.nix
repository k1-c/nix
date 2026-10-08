{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, makeWrapper
, copyDesktopItems
, makeDesktopItem
, libglvnd
, freetype
, zlib
, bzip2
, xz
, sqlite
, ncurses
, libffi
, libxcrypt-legacy
, libuuid
, libpulseaudio
, xorg
}:

# Cascadeur (Nekki の物理ベース 3D アニメーションツール)。nixpkgs 未収録。
#
# 配布物:
#   公式サイトの Download はログイン必須に見えるが、実体は認証なしの CDN にある。
#   サイトの JS は GET /rest/download/build?platform=linux&buildId=<id> で
#     https://cascadeur.com/storage/builds/<version>/linux
#   を受け取り、それが下記 cdn の URL へ 302 する。
#   (2025.2.4 = buildId 99 までは cdn.cascadeur.com/builds/linux/<buildId>/ だった)
#
# 更新手順:
#   1. https://cascadeur.com/download の最新版の version を確認する
#   2. 下記 version を書き換え、
#        nix-prefetch-url <URL> | xargs nix hash convert --hash-algo sha256 --to sri
#      で得た hash に差し替える
#
# 中身は Qt 6.5.3 / Python 3.11 + PySide6 / libtorch / FBX SDK などを抱えた
# 自己完結型の tarball (展開後 1.3GB)。同梱の Qt をそのまま使い、
# autoPatchelfHook で interpreter と外部依存 (X11 / GL / glibc 周り) だけを固定する。
stdenv.mkDerivation (finalAttrs: {
  pname = "cascadeur";
  version = "2026.2.2";

  src = fetchurl {
    url = "https://cdn.cascadeur.com/storage/builds/${finalAttrs.version}/linux/cascadeur-linux.tgz";
    hash = "sha256-kWY4GEP6mZM3qV8eAH8IVPYMmxsHGGl+SN4GvNoaQ+Y=";
  };

  sourceRoot = "cascadeur-linux";

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    copyDesktopItems
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    libglvnd
    freetype
    zlib
    bzip2
    xz
    sqlite
    ncurses
    libffi
    libxcrypt-legacy
    libuuid
    libpulseaudio
  ] ++ (with xorg; [
    libX11
    libxcb
    libXau
    libXdmcp
    libXext
    libXi
    libXrender
    libXrandr
    libXfixes
    libXdamage
    libXcomposite
    libXcursor
    libXinerama
    libXtst
    libXScrnSaver
    libXv
    libXxf86vm
    libXpm
    libXmu
    libXaw
    libXt
    libICE
    libSM
    libxkbfile
    libfontenc
    xcbutil
    xcbutilwm
    xcbutilimage
    xcbutilkeysyms
    xcbutilrenderutil
    xcbutilcursor
  ]);

  # NEEDED に出ない (dlopen される) もの。GL は libglvnd 経由で
  # /run/opengl-driver/lib のドライバに解決される。
  runtimeDependencies = [
    libglvnd
  ];

  # 上流の tarball 自体に入っていないもの。Ubuntu でも解決できない (= 使われていない):
  #   - libQt6*: 同梱の QML プラグイン (Qt.labs.* / QtTest 等) と PySide6 の
  #     QtSql / QtDesigner / QtHelp 等が要求するが、対応する Qt ライブラリは同梱されていない。
  #     本体 (cascadeur / cascadeur_auth) が NEEDED に持つ Qt ライブラリは全部同梱済み。
  #   - libnsl / libtirpc: Python 標準の nis モジュール (3.13 で削除済みの NIS クライアント)
  #   - libclang: PySide6 のバインディング生成器 shiboken6_generator
  autoPatchelfIgnoreMissingDeps = [
    "libQt6*.so.6"
    "libnsl.so.2"
    "libtirpc.so.3"
    "libclang-16.so.16.0.6"
  ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/cascadeur $out/bin
    cp -R ./* $out/opt/cascadeur/

    # - 同梱の Qt プラグインは xcb しか無いので、Wayland セッションでも XWayland で動かす
    #   (QT_QPA_PLATFORM=wayland が入っていると起動しない)。
    # - NixOS はシステムの Qt (6.9 系) の plugins / qml を QT_PLUGIN_PATH 等で配るため、
    #   同梱の Qt 6.5.3 に別バージョンのプラグインを読ませないよう外す。
    #   同梱分の場所は qt.conf (Prefix=.) で解決される。
    # - fontconfig は libQt6Gui に静的リンクされていて、設定ファイルの既定パスが
    #   上流のビルド環境 (/res/etc/fonts) のまま。見つからないと組み込みの最小設定になり
    #   NixOS のシステムフォントが見えない (日本語 UI の CJK が化ける) ので明示する。
    makeWrapper $out/opt/cascadeur/cascadeur $out/bin/cascadeur \
      --set QT_QPA_PLATFORM xcb \
      --unset QT_PLUGIN_PATH \
      --unset QML2_IMPORT_PATH \
      --unset QML_IMPORT_PATH \
      --set-default FONTCONFIG_FILE /etc/fonts/fonts.conf

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "cascadeur";
      desktopName = "Cascadeur";
      genericName = "3D Animation";
      comment = finalAttrs.meta.description;
      exec = "cascadeur";
      categories = [ "Graphics" "3DGraphics" ];
    })
  ];

  meta = {
    description = "Physics-based 3D character animation software";
    homepage = "https://cascadeur.com/";
    license = lib.licenses.unfree;
    mainProgram = "cascadeur";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
