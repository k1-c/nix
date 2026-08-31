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
    # 1.6.0 を持つ。nixpkgs-unstable 自体を上げると niri が壊れる (下の
    # 1Password overlay のコメント参照) ので、mise と同じく COSMIC だけ
    # 別 input に隔離して影響範囲を mind ホストに閉じ込める。
    nixpkgs-cosmic.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    nix-claude-code.url = "github:ryoppippi/nix-claude-code";

    # herdr (AI エージェント・マルチプレクサ) は nixpkgs 未収録のため公式 flake から取得。
    # 独自の nixpkgs + rust-overlay でソースビルドするため follows は付けない。
    herdr.url = "github:ogulcancelik/herdr";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixpkgs-mise, nixpkgs-cosmic, home-manager, niri, plasma-manager, nix-claude-code, herdr, ... }@inputs:
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
                # 最新安定版に更新できる。nixpkgs-unstable 自体は上げない
                # (上げると niri が libdisplay-info 削除で壊れるため)。
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
            niri.nixosModules.niri
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
      };
    };
}
