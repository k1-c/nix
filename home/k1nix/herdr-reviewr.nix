{ config, pkgs, pkgs-unstable, lib, inputs, ... }:

# herdr-reviewr (persiyanov.reviewr) — herdr のペインでエージェントの diff をレビューし、
# 行コメントをそのままエージェントの入力に送り返すプラグイン。
#
# 背景:
#   - nixpkgs 未収録。公式は `herdr plugin install persiyanov/herdr-reviewr` だが、
#     その場合 herdr-plugin.toml の [[build]] が
#       bash herdr/install.sh
#     を走らせて GitHub Releases の prebuilt を $HERDR_PLUGIN_ROOT/bin に展開する。
#     terminal-browser.nix と同じく nix 管理外の実体が増えるので、[[build]] を落とした
#     ローカルプラグインとして link する。
#   - 本体は MIT の Rust で Cargo.lock 同梱・git 依存なし。prebuilt (musl) でも動くが、
#     ソースビルドなら bump が version と 2 つの hash だけで済むのでこちらを採る。
#
# 運用:
#   - bump 時は version / hash / cargoHash を更新する。
#     hash:      nix-prefetch-url --unpack https://github.com/persiyanov/herdr-reviewr/archive/refs/tags/v<ver>.tar.gz \
#                  | xargs nix hash convert --hash-algo sha256 --to sri
#     cargoHash: いったん lib.fakeHash に差し替えて build し、エラーの got を写す。
#   - 上流の rust-toolchain.toml の channel が上がったら rustChannel も合わせる。
#     合っていないと cargo が Cargo.toml の rust-version で弾く。
#
# 仕組み:
#   - rust-toolchain.toml は 1.97.0 を要求するが、nixos-25.11 の rustc は 1.91.1、
#     nixpkgs-unstable でも 1.95.0 で足りない。herdr 本体が使う rust-overlay も lock が
#     古く 1.96.1 止まりなので、flake.nix に自前で足した rust-overlay から 1.97.0 を取る。
#   - herdr はプラグインのコマンドを最小 PATH で起動する。pane.sh は jq/git が
#     /usr/bin:/bin にある前提で PATH を組み立てるが NixOS には無いので store のパスに
#     差し替える。UI 本体も git (diff) と gh (PR タブ) を PATH から引くので wrapper で足す。
let
  version = "0.39.0";

  # 上流 rust-toolchain.toml の channel と一致させること。
  rustChannel = "1.97.0";

  src = pkgs.fetchFromGitHub {
    owner = "persiyanov";
    repo = "herdr-reviewr";
    tag = "v${version}";
    hash = "sha256-QD+hqFt1zpzGiJELJwwyJy4s6ASbIdOYnsw2S1qIaHs=";
  };

  rustToolchain = (pkgs.extend inputs.rust-overlay.overlays.default)
    .rust-bin.stable.${rustChannel}.minimal;

  rustPlatform = pkgs.makeRustPlatform {
    cargo = rustToolchain;
    rustc = rustToolchain;
  };

  herdr = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # pane.sh と UI が PATH から引く外部コマンド。gh は PR タブ専用だが、packages.nix と
  # 同じ理由 (nixos-25.11 の gh は古い) で unstable 版を使う。
  runtimePath = lib.makeBinPath [ pkgs.git pkgs.jq pkgs-unstable.gh herdr ];

  herdr-reviewr = rustPlatform.buildRustPackage {
    pname = "herdr-reviewr";
    inherit version src;

    cargoHash = "sha256-0r3IaTblNPhquK0Swj/yEESYGOEOYTDlTLHHGmtE3h0=";

    nativeBuildInputs = [ pkgs.makeWrapper ];

    # テストは実物の外部コマンドを叩く。git.rs は `git init` を実行し、
    # tests/pane_actions.rs は herdr/pane.sh をそのまま走らせるので jq が要る
    # (無いと cfg_field が全部失敗して "normalized configuration is unreadable")。
    nativeCheckInputs = [ pkgs.git pkgs.jq ];

    # tests/pane_actions.rs は CARGO_MANIFEST_DIR を「実在する git worktree」として
    # pane.sh に渡す (`git -C <cwd> rev-parse --show-toplevel` が通る前提)。上流 CI の
    # checkout では成り立つが、nix のサンドボックスは tarball 展開で .git が無いため
    # 「not a git repo: '/build/source'」で落ちる。テスト用にここだけ git 化する。
    preCheck = ''
      git init -q .
    '';

    postInstall = ''
      wrapProgram $out/bin/herdr-reviewr --prefix PATH : ${runtimePath}
    '';

    meta = {
      description = "A code review + file viewer sidebar for herdr";
      homepage = "https://github.com/persiyanov/herdr-reviewr";
      license = lib.licenses.mit;
      mainProgram = "herdr-reviewr";
      platforms = lib.platforms.unix;
    };
  };

  # herdr が読むプラグインルート。herdr-plugin.toml の [[panes]] は
  #   exec "$HERDR_PLUGIN_ROOT/bin/herdr-reviewr"
  # を起動するので、bin/ にビルド済みバイナリを置いた形に組み直す。
  # install.sh はここには入れない ([[build]] ごと落とすため不要)。
  reviewrPlugin = pkgs.runCommand "herdr-reviewr-plugin-${version}" { } ''
    mkdir -p $out/bin $out/herdr
    install -m644 ${src}/herdr-plugin.toml $out/herdr-plugin.toml
    install -m755 ${src}/herdr/pane.sh $out/herdr/pane.sh
    ln -s ${herdr-reviewr}/bin/herdr-reviewr $out/bin/herdr-reviewr

    # prebuilt の取得は nix 側で済んでいるので [[build]] を落とす。
    # (`herdr plugin link` は [[build]] を実行しない仕様だが、store を書き換えに来る
    #  経路自体を残さない。上流で形が変わったら --replace-fail で気付ける)
    substituteInPlace $out/herdr-plugin.toml \
      --replace-fail '[[build]]
command = ["bash", "herdr/install.sh"]
' ""

    # herdr はプラグインのコマンドを最小 PATH で起動する。/usr/bin:/bin に jq/git が
    # 無い NixOS では cfg_field の jq が全部失敗して "configuration unreadable" になる。
    substituteInPlace $out/herdr/pane.sh \
      --replace-fail 'export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:''${PATH:-}"' \
                     'export PATH="${runtimePath}:''${PATH:-}"'
  '';

  # 手で link し直すとき用の安定パス。`herdr plugin link` に渡しても結局
  # canonicalize されて store の実体が記録されるので (下の activation 参照)、
  # nix からは reviewrPlugin を直接渡す。home.file に置くのは、この安定パスを
  # 人間に提供するためと、generation から derivation を参照して GC から守るため。
  herdrPluginDir = "${config.home.homeDirectory}/.local/share/herdr-plugins/reviewr";
in
{
  # herdr の外からも `herdr-reviewr <repo>` で単体起動できる。
  home.packages = [ herdr-reviewr ];

  home.file.".local/share/herdr-plugins/reviewr".source = reviewrPlugin;

  # herdr 側のプラグイン登録だけは ~/.config/herdr/plugins.json への書き込みなので
  # 宣言的にできない。
  #
  # 「未登録なら link」では不足する。`herdr plugin link` は渡されたパスを canonicalize して
  # 実体を記録するので (src/app/api/plugins/manifest.rs の load_plugin_manifest)、登録された
  # plugin_root は常に store の実パスになる。version を上げても登録自体は残っているため
  # 再 link されず、古い store パスを指したまま GC で消えて壊れる。
  # 記録されたルートが今の derivation と一致するかで判定する。
  #
  # link は plugin_id をキーにした insert なので (handle_plugin_link)、上書きに unlink は要らない。
  # list / link はどちらもサーバ停止中でもオフライン経路で動く。
  home.activation.herdrReviewrPlugin =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      want=${reviewrPlugin}
      have=$(${herdr}/bin/herdr plugin list --plugin persiyanov.reviewr --json 2>/dev/null \
        | ${pkgs.jq}/bin/jq -r '.result.plugins[]? | select(.plugin_id == "persiyanov.reviewr") | .plugin_root' \
        2>/dev/null) || have=""

      if [ "$have" != "$want" ]; then
        run ${herdr}/bin/herdr plugin link "$want" > /dev/null \
          || echo "herdr-reviewr: herdr plugin link に失敗しました。herdr 起動後に手動で実行してください: herdr plugin link ${herdrPluginDir}" >&2
      fi
    '';
}
