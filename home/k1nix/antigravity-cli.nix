{ pkgs, pkgs-unstable, ... }:

# Antigravity CLI (`agy`) — Gemini 4 Argon をターミナルから使うための Google 公式 CLI。
#
# 背景:
#   - Gemini CLI (`gemini`) は 2026-06-18 に個人向け (無料 / Google AI Pro / Ultra) の
#     提供が終了し、Antigravity CLI に置き換わった。Gemini CLI 自体は残っているが
#     Google は「Gemini 4 Argon には最適化していない。Argon は Antigravity を使え」
#     としている (https://geminicli.com/)。
#   - Gemini 4 Argon は 2026-10-15 から Google AI Pro (無料トライアル除く) でも
#     Antigravity (デスクトップ / CLI) で使える。Argon 専用の週次クォータが別枠で付く。
#   - nixpkgs は `antigravity-cli` として収録済みだが、nixpkgs-unstable の pin は
#     1.2.16 で古い。`gemini-4-argon` を認識しない不具合 (google-antigravity/
#     antigravity-cli#1228) は 1.4.3 で直っているので、ここで最新版に差し替える。
#
# 運用:
#   - bump 時は version / buildId / hash を更新。
#     最新版:  curl -fsSL https://storage.googleapis.com/antigravity-public/antigravity-cli/latest
#     buildId: curl -fsSL https://storage.googleapis.com/antigravity-public/antigravity-cli/<ver>/manifest.json \
#                | jq -r '.platforms."linux-x64".url'   # .../<ver>-<buildId>/linux-x64/...
#     hash:    nix store prefetch-file --json --hash-type sha256 <url> | jq -r .hash
#   - `agy` は自身をバックグラウンドで自動更新しようとするが、store は書けないので
#     効かない。更新は上記の手順で行う。
#
# 使い方:
#   agy            # 初回は Google サインイン (ブラウザが開く)。資格情報は Secret Service に保存
#   agy models     # 契約プランで使えるモデル一覧
#   /model         # セッション内でモデル切替 (gemini-4-argon)。選択は次回以降も保持される
#   agy --model gemini-4-argon
#   設定: ~/.gemini/antigravity-cli/settings.json、MCP: ~/.gemini/config/mcp_config.json
let
  version = "1.5.3";
  buildId = "6604829099950080";

  sources = {
    "x86_64-linux" = {
      path = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha256-G0hQWZzOc6F/lP+0It87+VMVMbd9vdxAwaQ14MLBaAc=";
    };
    "aarch64-linux" = {
      path = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha256-LVAGDHsTJ5leXIHsWIKckcJWTruf7BZdP58TJewYhnU=";
    };
  };

  src = sources.${pkgs.stdenv.hostPlatform.system} or
    (throw "antigravity-cli: unsupported platform ${pkgs.stdenv.hostPlatform.system}");

  antigravity-cli = pkgs-unstable.antigravity-cli.overrideAttrs (old: {
    inherit version;
    src = pkgs.fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${version}-${buildId}/${src.path}";
      inherit (src) hash;
    };
  });
in
{
  home.packages = [ antigravity-cli ];
}
