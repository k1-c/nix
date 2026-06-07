{ pkgs, lib, ... }:

# Prisma 6.2.1 (credit-eval-pipeline で使用中) の prisma-engines を自前ビルドして、
# NixOS で動作するエンジンバイナリのパスを環境変数で expose する。
#
# 背景:
#   - Prisma は NixOS を検出すると "linux-nixos" platform 用の prebuilt を
#     binaries.prisma.sh から取りに行くが、そのバイナリは公式に存在しない (404)。
#   - nixpkgs の prisma-engines は最新追従で、6.x シリーズでは 6.0.1 → 6.3.0 と
#     直接ジャンプしているため 6.2.x が nixpkgs に存在しない。
#   - そのため、プロジェクトで使っている engine commit を rev に固定して
#     `rustPlatform.buildRustPackage` を直接呼び自前ビルドする。
#     (pkgs.prisma-engines.overrideAttrs では cargoDeps の vendor 名が
#      古い version で固定されてしまい再計算されないため不可)
#
# 運用:
#   - プロジェクトの prisma を bump したら、以下の version / rev / hash /
#     cargoHash を更新する。
#   - rev は package.json の prisma version に紐付く engine commit。
#     確認方法: pnpm install 時のエラーメッセージ、または
#     `cat node_modules/.pnpm/@prisma+engines-version@*/.../package.json`
#   - 初回ビルドは Rust のフルビルドで 10〜20 分。cachix 化推奨。
let
  prismaEngines = pkgs.rustPlatform.buildRustPackage (finalAttrs: {
    pname = "prisma-engines";
    version = "6.2.1";

    src = pkgs.fetchFromGitHub {
      owner = "prisma";
      repo = "prisma-engines";
      rev = "4123509d24aa4dede1e864b46351bf2790323b69";
      hash = "sha256-G+FFwi+USsg3+SiHcYLfy/s+4f1P20fS6Tdem8Zgw8U=";
    };

    # rev=4123509d... に対応する cargo vendor の hash。
    # 更新方法: 一旦 cargoHash = ""; に戻して nix build → 出力に
    # `got: sha256-...` が出るので貼り替える。
    cargoHash = "sha256-xmfJA6JDFc9fk7smrc+cNoqOcl8g7WkfSjp2QJ1Zgm4=";

    # 以下は nixpkgs 6.18.0 の prisma-engines_6/package.nix と同じ設定。
    OPENSSL_NO_VENDOR = 1;

    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ pkgs.openssl ];

    preBuild = ''
      export OPENSSL_DIR=${lib.getDev pkgs.openssl}
      export OPENSSL_LIB_DIR=${lib.getLib pkgs.openssl}/lib

      export SQLITE_MAX_VARIABLE_NUMBER=250000
      export SQLITE_MAX_EXPR_DEPTH=10000

      export GIT_HASH=${finalAttrs.src.rev};
    '';

    cargoBuildFlags = [
      "-p" "query-engine"
      "-p" "query-engine-node-api"
      "-p" "schema-engine-cli"
      "-p" "prisma-fmt"
    ];

    postInstall = ''
      mv $out/lib/libquery_engine${pkgs.stdenv.hostPlatform.extensions.sharedLibrary} \
         $out/lib/libquery_engine.node
    '';

    doCheck = false;

    meta = {
      description = "Prisma engines pinned to 6.2.1 for credit-eval-pipeline";
      homepage = "https://www.prisma.io/";
      license = lib.licenses.asl20;
      platforms = lib.platforms.unix;
      mainProgram = "prisma";
    };
  });
in
{
  home.packages = [ prismaEngines ];

  # prisma CLI / Prisma Client が参照する環境変数。
  # https://www.prisma.io/docs/orm/reference/environment-variables-reference
  home.sessionVariables = {
    PRISMA_SCHEMA_ENGINE_BINARY = "${prismaEngines}/bin/schema-engine";
    PRISMA_QUERY_ENGINE_BINARY = "${prismaEngines}/bin/query-engine";
    PRISMA_QUERY_ENGINE_LIBRARY = "${prismaEngines}/lib/libquery_engine.node";
    PRISMA_FMT_BINARY = "${prismaEngines}/bin/prisma-fmt";

    # NixOS では prisma の postinstall で engine をダウンロードしようとして
    # 404 になるため、ダウンロードをスキップする。
    PRISMA_SKIP_POSTINSTALL_GENERATE = "1";

    # `prisma generate` 実行時、engine 本体とは別に @prisma/engines が
    # `binaries.prisma.sh/.../linux-nixos/*.sha256` を取りに行く checksum 検証が
    # 走る。NixOS にはそのファイルが無く 404 になるため、エンジン実体を
    # 自前供給している我々は checksum 不在を無視させる。
    PRISMA_ENGINES_CHECKSUM_IGNORE_MISSING = "1";
  };
}
