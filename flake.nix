{
  description = "k1-c NixOS configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # mise 専用。nixos-unstable チャンネルは CI ゲートのため mise が遅れがち
    # (例: 2026.6.5)。CI 前の nixpkgs-unstable ブランチはより新しい mise
    # (例: 2026.6.11) を持つため、mise だけこちらから取得して影響範囲を限定する。
    nixpkgs-mise.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

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

  outputs = { self, nixpkgs, nixpkgs-unstable, nixpkgs-mise, home-manager, niri, plasma-manager, nix-claude-code, herdr, ... }@inputs:
    let
      mkHost = hostName: system:
        let
          pkgs-unstable = import nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
          };
          pkgs-mise = import nixpkgs-mise { inherit system; };
        in
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
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
