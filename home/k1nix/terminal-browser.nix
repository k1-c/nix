{ config, pkgs, lib, inputs, ... }:

# terminal-browser (zenbu-labs) — ターミナルの中で動く実ブラウザ。
# herdr のペインを split して Chromium の描画を kitty graphics protocol で流す。
#
# 背景:
#   - 旧 `ogulcancelik/herdr-browser` は deprecated。後継がこれ。
#   - nixpkgs 未収録。公式は `curl -fsSL https://terminal-browser.sh/install | bash`
#     で prebuilt tarball (Electron + rust エンジン) を ~/.local/share に展開する
#     仕組み。本ファイルはそれを Nix で再現する。
#   - herdr 0.8.2 以上が必要。描画は herdr の pane.graphics.* API 経由で、split には
#     `herdr pane split --right-click pane` (0.8.2 で追加) を使う。0.7.5 では
#     split がエラーになり、描画も cell_size_unavailable で出ない。
#
# 運用:
#   - bump 時は version と hash を更新。
#     最新版と sha256 (hex): curl -fsSL https://terminal-browser.sh/install | head -12
#     hex → SRI: nix hash convert --hash-algo sha256 --to sri <hex>
#   - `terminal-browser upgrade` は store に書けないので失敗する。更新は上記の手順で行う。
#
# 仕組み:
#   - composio.nix と違い interpreter は autoPatchelfHook で store の glibc に固定する
#     (nix-ld 任せだと Electron が dlopen する libgbm 等を programs.nix 側に足し続ける
#     ことになるため)。GL/gbm/udev は dlopen されるので runtimeDependencies に入れる。
#   - chrome-sandbox は setuid にできないが、cli/src/sandbox.ts は unprivileged userns が
#     使えればそれで代替する。NixOS は AppArmor の userns 制限を入れていないのでそのまま動く。
let
  version = "0.11.1";

  # ページの既定拡大率。terminal-browser 本体に設定項目が無いので bundle を patch する。
  # 実行時は Ctrl + = / - / 0 でプリセット (… 0.9 / 1 / 1.1 / 1.25 / 1.5 …) を上下できるが
  # 値は保存されないので、起動時の初期値だけここで決める。
  defaultZoom = "1.1";

  sources = {
    "x86_64-linux" = {
      asset = "terminal-browser-linux-x64.tar.gz";
      hash = "sha256-sIMnZVqjGQJgzzSAcpS+fHxmhaomOaOTBVt8ZJ7rOko=";
    };
    "aarch64-linux" = {
      asset = "terminal-browser-linux-arm64.tar.gz";
      hash = "sha256-7zTGgzPENS5RB9W9bFz3/oQKBcmkijcIS5/GX8mGOFw=";
    };
  };

  src = sources.${pkgs.stdenv.hostPlatform.system} or
    (throw "terminal-browser: unsupported platform ${pkgs.stdenv.hostPlatform.system}");

  terminal-browser = pkgs.stdenv.mkDerivation {
    pname = "terminal-browser";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://terminal-browser.sh/install/dl/stable/v${version}/${src.asset}";
      inherit (src) hash;
    };

    sourceRoot = "terminal-browser";

    nativeBuildInputs = [ pkgs.autoPatchelfHook ];

    buildInputs = with pkgs; [
      stdenv.cc.cc.lib
      alsa-lib
      at-spi2-atk
      at-spi2-core
      atk
      cairo
      cups
      dbus
      expat
      glib
      gtk3
      libdrm
      libgbm
      libxkbcommon
      nspr
      nss
      pango
      systemdMinimal
      xorg.libX11
      xorg.libXcomposite
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXrandr
      xorg.libxcb
    ];

    # NEEDED に出ない (dlopen される) もの。GL は libglvnd 経由で
    # /run/opengl-driver/lib のドライバに解決される。
    runtimeDependencies = with pkgs; [
      libglvnd
      libgbm
      mesa
      systemdMinimal
    ];

    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;

    # プロファイル (Cookie・ログインセッション・履歴 DB) の置き場は既定で
    #   ~/.config/terminal-browser-<sha256(インストール先パス)[0:8]>
    # になる。nix store のパスはバージョンごとに変わるので、そのままだと
    # 更新のたびにログインが全部消える。suffix を固定文字列に差し替えて
    #   ~/.config/terminal-browser-nixos
    #   ~/.local/share/terminal-browser-nixos  (terminal-browser.db)
    #   ~/.local/state/terminal-browser-nixos  (logs)
    # に固定する。bundle の形が変わったら --replace-fail で気付けるようにしてある。
    postPatch = ''
      substituteInPlace browser/dist/main.js cli/dist/main.js \
        --replace-fail 'var suffix = import_node_crypto.default.createHash("sha256").update(stableIdentity(INSTALL_ROOT.root)).digest("hex").slice(0, 8);' \
                       'var suffix = "nixos";'

      # ページを載せる BrowserWindow の webPreferences に zoomFactor を足して、
      # 起動直後から ${defaultZoom} 倍で描画させる (Electron の既定は 1.0)。
      # 呼び出し側が渡す webPreferences の手前に置くので、passthrough があればそちらが勝つ。
      # 入力は sendInputEvent (ウィンドウ座標) なので、Ctrl + = で拡大したときと同じく
      # クリック位置はズレない。
      substituteInPlace browser/dist/main.js \
        --replace-fail '          ...webPreferences,' \
                       '          zoomFactor: ${defaultZoom},
          ...webPreferences,'
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/libexec/terminal-browser $out/bin
      cp -R ./* $out/libexec/terminal-browser/
      # bin/terminal-browser は $0 の symlink を辿って dist root を決めるので symlink で良い
      ln -s $out/libexec/terminal-browser/bin/terminal-browser $out/bin/terminal-browser

      runHook postInstall
    '';

    meta = {
      description = "A real browser that runs inside your terminal";
      homepage = "https://github.com/zenbu-labs/terminal-browser";
      license = lib.licenses.mit;
      mainProgram = "terminal-browser";
      platforms = lib.attrNames sources;
      sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    };
  };

  herdr = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # `herdr plugin link` はここに書いたパスをそのまま記録するので、store 直指定ではなく
  # home.file が張る安定パスを渡す (更新のたびに link し直さずに済む)。
  herdrPluginDir = "${config.home.homeDirectory}/.local/share/herdr-plugins/terminal-browser";
in
{
  home.packages = [ terminal-browser ];

  # `terminal-browser setup` が張るのと同じ skill の symlink を宣言的に持つ。
  # (setup はエージェントごとに ~/.claude/skills などへ symlink する実装)
  home.file.".claude/skills/terminal-browser".source =
    "${terminal-browser}/libexec/terminal-browser/skills/default/terminal-browser";
  home.file.".codex/skills/terminal-browser".source =
    "${terminal-browser}/libexec/terminal-browser/skills/codex/terminal-browser";

  home.file.".local/share/herdr-plugins/terminal-browser".source =
    ./files/terminal-browser-herdr-plugin;

  # herdr 側のプラグイン登録だけは ~/.config/herdr/.plugins.lock への書き込みなので
  # 宣言的にできない。未登録のときだけ link する (失敗しても switch は止めない)。
  home.activation.terminalBrowserHerdrPlugin =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if ! ${herdr}/bin/herdr plugin list 2>/dev/null | grep -q 'zenbu-labs.terminal-browser'; then
        run ${herdr}/bin/herdr plugin link ${lib.escapeShellArg herdrPluginDir} > /dev/null \
          || echo "terminal-browser: herdr plugin link に失敗しました。herdr 起動後に手動で実行してください: herdr plugin link ${herdrPluginDir}" >&2
      fi
    '';
}
