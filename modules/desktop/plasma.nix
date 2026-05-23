{ pkgs, ... }:

{
  # SDDM 上で Plasma セッションを選択可能にする。
  # defaultSession = "plasma" は modules/desktop/common.nix で設定済みで、
  # これは Plasma 6 の Wayland セッション (X11 側は "plasmax11") を指す。
  services.desktopManager.plasma6.enable = true;

  # KWin の Wayland セッションで使う追加エフェクト。
  # 角丸はビルトインに無いので kde-rounded-corners を入れて、
  # KWin の effect 一覧に出るようにしておく (有効化は home/k1nix/desktop/plasma.nix 側で)。
  environment.systemPackages = with pkgs; [
    kde-rounded-corners
  ];
}
