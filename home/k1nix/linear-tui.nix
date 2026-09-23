{ pkgs, lib, ... }:

# linear-tui (k1-c/linear-tui) — Linear.app の TUI クライアント。
#
# 背景:
#   - 自作。crates.io と GitHub Releases に出しているが nixpkgs 未収録なので
#     ここでソースからビルドする (MIT / Cargo.lock 同梱 / git 依存なし)。
#   - rust-version = 1.85 なので nixos-25.11 の rustc (1.91.1) で足りる。
#     herdr-reviewr.nix と違って rust-overlay は要らない。
#
# 運用:
#   - bump 時は version / hash / cargoHash を更新する。
#     hash:      nix-prefetch-url --unpack https://github.com/k1-c/linear-tui/archive/refs/tags/v<ver>.tar.gz \
#                  | xargs nix hash convert --hash-algo sha256 --to sri
#     cargoHash: いったん lib.fakeHash に差し替えて build し、エラーの got を写す。
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
  version = "0.1.3";

  linear-tui = pkgs.rustPlatform.buildRustPackage {
    pname = "linear-tui";
    inherit version;

    src = pkgs.fetchFromGitHub {
      owner = "k1-c";
      repo = "linear-tui";
      tag = "v${version}";
      hash = "sha256-T0WclBcg7XVVNoxhPrT1DLgeCa3zH9dWovtNkBCA+QE=";
    };

    cargoHash = "sha256-Om5tfeB2/87+NP8BKyNoJD8D+bfPaKHsQfY6R/sNy2M=";

    nativeBuildInputs = [ pkgs.pkg-config pkgs.makeWrapper ];
    buildInputs = [ pkgs.openssl ];

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
