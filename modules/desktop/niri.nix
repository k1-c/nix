{ pkgs, inputs, ... }:

{
  # niri-flake が提供する NixOS module を経由して、SDDM のセッション一覧に
  # "Niri" を追加する。home-manager 側の programs.niri.settings がユーザー設定。
  programs.niri = {
    enable = true;
    # niri-stable (25.08) は Nix sandbox 内で Rust テストが SIGABRT する既知問題があるため
    # niri-flake の packages.<system>.niri-unstable を直接参照する。
    package = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;
  };

  # NOTE: 以前ここで systemd.user.services.polkit-gnome-authentication-agent-1 を
  # 起動していたが、Plasma 並行運用下では KDE 側 polkit agent と重複登録になり
  # "An authentication agent already exists for the given subject" でループする。
  # KDE polkit agent は Plasma セッション以外でも生きているので、追加しない方針。
  # Niri 単独運用に切り替える時に再導入を検討する。

  environment.systemPackages = with pkgs; [
    wl-clipboard
    grim
    slurp
    wf-recorder
    brightnessctl
    playerctl
    pamixer
  ];
}
