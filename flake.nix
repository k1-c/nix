{
  description = "k1-c NixOS configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

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
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, niri, plasma-manager, nix-claude-code, ... }@inputs:
    let
      mkHost = hostName: system:
        let
          pkgs-unstable = import nixpkgs-unstable { inherit system; };
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
              home-manager.extraSpecialArgs = { inherit inputs pkgs-unstable; };
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
      };
    };
}
