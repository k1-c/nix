{ pkgs, ... }:

# Ubuntu 時代 (2026-09 の apt / snap 棚卸し) に入れていたアプリのうち、
# 共通モジュール (modules/) や home-manager (home/k1nix/) に無いもの。
#
# nixpkgs 未収録で別途対応が要るもの (この一覧には無い):
#   Amazon WorkSpaces client / claude-desktop / Modern CSV / MaxAutoClicker / azd / ghcup
{
  # Steam。32bit ライブラリや udev ルールをまとめて面倒見てくれるので
  # environment.systemPackages ではなくモジュールで入れる。
  programs.steam.enable = true;

  environment.systemPackages = with pkgs; [
    # デスクトップアプリ
    zoom-us
    obs-studio
    dbeaver-bin
    postman
    libreoffice
    kdePackages.okular
    spotify
    pinta
    filezilla
    clapper
    # openshot-qt は入れない: pyqtwebengine 経由で EOL の qtwebengine 5.15 (未修正 CVE 多数) を
    # 引き込み、nix flake check が insecure package として弾く。動画編集が要るなら Qt6 の kdenlive。
    appimage-run      # Logseq など AppImage 配布のものを動かす

    # クラウド / インフラ CLI
    ngrok
    httpie
    azure-cli
    azure-functions-core-tools
    ssm-session-manager-plugin
    pulumi-bin
    mosh
    wireguard-tools

    # システム
    nvtopPackages.full
    nvme-cli
    shellcheck
    figlet
    lolcat

    # 言語ツールチェイン (mise 管理外のもの)
    deno
    go
    rustup
    dotnet-sdk
  ];

  # Ubuntu 時代にターミナルで使っていた Nerd Font。
  fonts.packages = with pkgs; [
    nerd-fonts._0xproto
    nerd-fonts.ubuntu
  ];
}
