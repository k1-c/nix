{ pkgs, lib, ... }:

# Composio CLI を公式 GitHub Release のプリビルトバイナリから導入する。
#
# 背景:
#   - 旧 CLI の `composio-core` (npm) は deprecated。
#   - 新 CLI の `@composio/cli` (npm) は名前だけ存在し npm に未公開 (404)。
#   - 公式は `curl -fsSL https://composio.dev/install | bash` で
#     GitHub Releases (`ComposioHQ/composio`, タグ `@composio/cli@X.Y.Z`) の
#     プリビルト zip を取得する仕組み。本ファイルはそれを Nix で再現する。
#
# 運用:
#   - bump 時は version と sources の sha256 を更新。
#     最新タグ: curl -s 'https://api.github.com/repos/ComposioHQ/composio/releases?per_page=20' \
#               | grep '"tag_name"' | grep -E '@composio/cli@[0-9]+\.[0-9]+\.[0-9]+"' | head -1
#     checksums: https://github.com/ComposioHQ/composio/releases/download/@composio/cli@<ver>/checksums.txt
#     hex → SRI: nix hash convert --hash-algo sha256 --to sri <hex>
#
# 仕組み:
#   - バイナリ本体 + 周辺アセット (acp-adapters, local-tools-binaries, *.mjs) を
#     1 ディレクトリにまとめて $out/libexec/composio に配置する。バイナリは
#     /proc/self/exe からアセット位置を解決するため、$out/bin/composio は
#     symlink にして libexec 内の本体を直接指す。
#   - ELF interpreter は `/lib64/ld-linux-x86-64.so.2` のままにする。
#     nix-ld (modules/programs.nix で有効化済) が解決する。
let
  version = "0.2.31";

  sources = {
    "x86_64-linux" = {
      asset = "composio-linux-x64.zip";
      hash = "sha256-yYA9DJa2EgsfJs8y/rrPJ25VvJAw6NQnVYNthIOG0+4=";
    };
    "aarch64-linux" = {
      asset = "composio-linux-aarch64.zip";
      hash = "sha256-a0t7cojyynRS45g9MlhSBO+mufx9YMYp7sk9Z2Qcf00=";
    };
    "x86_64-darwin" = {
      asset = "composio-darwin-x64.zip";
      hash = "sha256-rF4de0QRmaJraCqDfw6a4GJe/LDhpIBGoT9f9AgUxOI=";
    };
    "aarch64-darwin" = {
      asset = "composio-darwin-aarch64.zip";
      hash = "sha256-6sqiPnMF4pKOuJStv2lnW+H3x+dHiJ4YpJ4E1se1vv4=";
    };
  };

  src = sources.${pkgs.stdenv.hostPlatform.system} or
    (throw "composio: unsupported platform ${pkgs.stdenv.hostPlatform.system}");

  composio = pkgs.stdenv.mkDerivation {
    pname = "composio";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://github.com/ComposioHQ/composio/releases/download/@composio/cli@${version}/${src.asset}";
      inherit (src) hash;
    };

    nativeBuildInputs = [ pkgs.unzip ];

    # zip 内には `composio-<target>/` の単一トップディレクトリがあるため
    # `--strip-components=1` 相当の挙動を unpackPhase で実現する。
    unpackPhase = ''
      runHook preUnpack
      mkdir -p source
      unzip -q $src -d source.tmp
      shopt -s dotglob
      mv source.tmp/*/* source/
      rmdir source.tmp/* source.tmp
      runHook postUnpack
    '';

    sourceRoot = "source";

    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;          # bun ビルド済みバイナリは strip すると壊れることがある
    dontPatchELF = true;       # interpreter は nix-ld に任せる

    installPhase = ''
      runHook preInstall

      mkdir -p $out/libexec/composio $out/bin
      cp -R . $out/libexec/composio/
      chmod +x $out/libexec/composio/composio
      ln -s $out/libexec/composio/composio $out/bin/composio

      runHook postInstall
    '';

    meta = {
      description = "Composio CLI — connect AI agents to 1000+ tools";
      homepage = "https://composio.dev";
      license = lib.licenses.elastic20;
      mainProgram = "composio";
      platforms = lib.attrNames sources;
      sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    };
  };
in
{
  home.packages = [ composio ];
}
