{ ... }:

{
  # mise 本体は home/k1nix/packages.nix で導入。
  # ここではグローバル設定 (~/.config/mise/config.toml) のみを管理する。
  # tools の追加・更新時はこのファイルを編集してリビルドする。
  xdg.configFile."mise/config.toml".source = ./files/mise-config.toml;

  # mise の挙動を NixOS 向けに固定するための環境変数による二重防御。
  # config.toml が無い/読まれない経路 (短命シェル, CI コンテナ等) でも
  # ソースビルドが走らないようにする保険。env 名は `mise settings` の
  # canonical key を大文字化したもの (検証済み: MISE_NODE_COMPILE は効く、
  # MISE_NODE__COMPILE は効かない)。
  # ・MISE_ALL_COMPILE=0: Node/Ruby/Python/Erlang 等まとめて prebuilt 強制
  # ・MISE_NODE_COMPILE=0: node 個別の保険
  # ・MISE_EXPERIMENTAL=1: idiomatic_version_file など mise の新機能を有効化
  home.sessionVariables = {
    MISE_ALL_COMPILE = "0";
    MISE_NODE_COMPILE = "0";
    MISE_EXPERIMENTAL = "1";
  };
}
