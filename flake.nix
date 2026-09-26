{
  description = "k1-c NixOS configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # mise 専用。nixos-unstable チャンネルは CI ゲートのため mise が遅れがち
    # (例: 2026.6.5)。CI 前の nixpkgs-unstable ブランチはより新しい mise
    # (例: 2026.6.11) を持つため、mise だけこちらから取得して影響範囲を限定する。
    nixpkgs-mise.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # COSMIC 専用。Frosted Glass は COSMIC 1.3 で入った機能だが、nixpkgs
    # nixos-25.11 は cosmic 1.0.0、上の nixpkgs-unstable pin は 1.0.16、
    # 現 stable の nixos-26.05 でも 1.2.0 で未搭載。nixos-unstable だけが
    # 1.6.0 を持つ。mise と同じく COSMIC だけ別 input に隔離して、
    # 影響範囲を COSMIC 一式に閉じ込める (全ホスト共通)。
    nixpkgs-cosmic.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    nix-claude-code.url = "github:ryoppippi/nix-claude-code";

    # ghostty 専用。COSMIC で frosted glass にするため upstream main を使う。
    # リリース版 1.3.1 (nixpkgs 25.11 / unstable / cosmic pin すべて 1.3.1) の
    # Wayland blur は旧 org_kde_kwin_blur_manager 専用実装だが、cosmic-comp 1.6.0 は
    # このプロトコルを advertise せず新標準の ext_background_effect_manager_v1 のみを
    # 出すため、COSMIC では background-blur が黙って無視される。
    # main は ext-background-effect 実装済み (milestone 1.4.0, 未リリース)。
    # 1.4.0 が nixpkgs に降りてきたらこの input を削って pkgs.ghostty に戻す。
    # zig でソースビルドされ、上流が pin した nixpkgs で検証されているため
    # follows は付けない (herdr と同じ隔離方針)。
    ghostty.url = "github:ghostty-org/ghostty";

    # herdr (AI エージェント・マルチプレクサ) は nixpkgs 未収録のため公式 flake から取得。
    # 独自の nixpkgs + rust-overlay でソースビルドするため follows は付けない。
    herdr.url = "github:ogulcancelik/herdr";

    # herdr-reviewr 専用。上流の rust-toolchain.toml が 1.97.0 を要求するが、
    # nixos-25.11 の rustc は 1.91.1、nixpkgs-unstable でも 1.95.0 で足りない。
    # herdr input が持つ rust-overlay も lock が古く 1.96.1 までしか無いため、
    # ツールチェイン取得用に自前で pin する (overlay なので nixpkgs は follows でよい)。
    # linear-tui (自作 TUI) のソース。nixpkgs 未収録なので home/k1nix/linear-tui.nix で
    # ビルドする。リリースタグに pin し、.github/workflows/update-linear-tui.yml が
    # 最新リリースのタグへ書き換えて lock を更新する (手で触る必要はない)。
    linear-tui = {
      url = "github:k1-c/linear-tui/v0.10.0";
      flake = false;
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixpkgs-mise, nixpkgs-cosmic, home-manager, plasma-manager, nix-claude-code, herdr, ... }@inputs:
    let
      mkHost = hostName: system:
        let
          pkgs-unstable = import nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
            overlays = [
              # 1Password CLI の Environments 機能 (op environment / op run
              # --environment) は 2026-08 時点で beta 版のみ対応。安定版 2.34.1
              # (nixpkgs が配布する最新) は未対応のため、公式 beta の prebuilt
              # バイナリに差し替える。op 自体に自動更新機能は無いので、更新時は
              # 下記 version を最新 beta にし、
              #   nix-prefetch-url --unpack <zip URL> | xargs nix hash to-sri --type sha256
              # で得た hash を書き換えて rebuild する。
              # 一覧: https://releases.1password.com/developers/cli-beta/
              # (全ホスト x86_64-linux 前提で linux_amd64 を直指定)
              (final: prev: {
                _1password-cli = prev._1password-cli.overrideAttrs (old: rec {
                  version = "2.38.1-beta.01";
                  src = prev.fetchzip {
                    url = "https://cache.agilebits.com/dist/1P/op2/pkg/v${version}/op_linux_amd64_v${version}.zip";
                    hash = "sha256-8o7xDxZcvQ1NSFpKxRzJXSkousl/Uk5YB2ji1+EIjIM=";
                    stripRoot = false;
                  };
                });

                # GUI も nixpkgs は prebuilt tarball を落とすだけ (linux.nix は
                # version をパス生成に使わない) なので、version/src の差し替えで
                # 最新安定版に更新できる。
                # 更新時: 下記の stable tarball URL の version を変え、
                #   nix-prefetch-url <URL> | xargs nix hash convert --to sri --hash-algo sha256
                # で hash を更新する。
                _1password-gui = prev._1password-gui.overrideAttrs (old: rec {
                  version = "8.12.32";
                  src = prev.fetchurl {
                    url = "https://downloads.1password.com/linux/tar/stable/x86_64/1password-${version}.x64.tar.gz";
                    hash = "sha256-dg42SQNMS77+393sDP66weZ33VVIKjOQEZwaK82ifZc=";
                  };
                });
              })
            ];
          };
          pkgs-mise = import nixpkgs-mise { inherit system; };
          # COSMIC 一式 (cosmic-* / xdg-desktop-portal-cosmic / pop-launcher) を
          # ここから overlay で差し替える。実際に forcing されるのは
          # modules/desktop/cosmic.nix を import したホストだけ。
          pkgs-cosmic = import nixpkgs-cosmic { inherit system; };
        in
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs pkgs-unstable pkgs-cosmic; };
          modules = [
            ./hosts/${hostName}
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit inputs pkgs-unstable pkgs-mise; };
              home-manager.sharedModules = [
                plasma-manager.homeModules.plasma-manager
              ];
              home-manager.users.k1nix = import ./home/k1nix;
            }
          ];
        };
    in
    {
      nixosConfigurations = {
        insomnia = mkHost "insomnia" "x86_64-linux";
        dwarf    = mkHost "dwarf"    "x86_64-linux";
        mind     = mkHost "mind"     "x86_64-linux";
        daiv     = mkHost "daiv"     "x86_64-linux";
      };
    };
}
