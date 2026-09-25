{ pkgs, lib, inputs, ... }:

# linear-tui (k1-c/linear-tui) — Linear.app の TUI クライアント。
#
# 背景:
#   - 自作。crates.io と GitHub Releases に出しているが nixpkgs 未収録なので
#     ここでソースからビルドする (MIT / Cargo.lock 同梱 / git 依存なし)。
#   - rust-version = 1.85 なので nixos-25.11 の rustc (1.91.1) で足りる。
#     herdr-reviewr.nix と違って rust-overlay は要らない。
#
# 運用:
#   - ソースは flake input `linear-tui` (リリースタグ pin, flake = false)。
#     .github/workflows/update-linear-tui.yml が毎日最新リリースを見て、
#     flake.nix のタグと flake.lock を更新して main に push する。手動 bump は不要。
#     手で上げるなら flake.nix の url のタグを書き換えて `nix flake update linear-tui`。
#   - version は上流の Cargo.toml から、依存は Cargo.lock から直接読むので
#     src hash / cargoHash の更新は要らない (Cargo.lock に git 依存が入ったら
#     cargoLock.outputHashes が必要になる)。
#
# 仕組み:
#   - reqwest 0.12 が default-tls (native-tls → openssl) なので openssl と
#     pkg-config が要る。rustls 版に寄せるなら上流の feature を変えること。
#   - OAuth ログインは `open` crate でブラウザを起動する = xdg-open を PATH から引くので
#     wrapper で足す。
#
# 認証・設定 (宣言的にしない理由):
#   - config.rs は ~/.config/linear-tui/config.toml を fs::write で上書きする。
#     OAuth のトークン保存と自動リフレッシュもここを書き換えるため、home.file で
#     store の読み取り専用シンボリックリンクにすると認証が壊れる。
#     初回だけ手で叩く:
#       linear-tui auth set-oauth <client-id> <client-secret> && linear-tui auth login
#       (または linear-tui auth token <personal-api-key>)
#   - API キーは秘密情報なのでこのリポジトリには置かない。
let
  src = inputs.linear-tui;

  linear-tui = pkgs.rustPlatform.buildRustPackage {
    pname = "linear-tui";
    inherit ((lib.importTOML "${src}/Cargo.toml").package) version;
    inherit src;

    cargoLock.lockFile = "${src}/Cargo.lock";

    nativeBuildInputs = [ pkgs.pkg-config pkgs.makeWrapper ];
    buildInputs = [ pkgs.openssl ];
    # snapshot のテストが一時ディレクトリで git init / worktree add を叩く。
    nativeCheckInputs = [ pkgs.git ];

    postInstall = ''
      wrapProgram $out/bin/linear-tui \
        --prefix PATH : ${lib.makeBinPath [ pkgs.xdg-utils ]}
    '';

    meta = {
      description = "A TUI client for Linear.app";
      homepage = "https://github.com/k1-c/linear-tui";
      license = lib.licenses.mit;
      mainProgram = "linear-tui";
      platforms = lib.platforms.unix;
    };
  };
in
{
  home.packages = [ linear-tui ];
}
