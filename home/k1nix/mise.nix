{ ... }:

{
  # mise 本体は home/k1nix/packages.nix で導入。
  # ここではグローバル設定 (~/.config/mise/config.toml) のみを管理する。
  # tools の追加・更新時はこのファイルを編集してリビルドする。
  xdg.configFile."mise/config.toml".source = ./files/mise-config.toml;
}
