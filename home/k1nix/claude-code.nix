{ pkgs, inputs, ... }:

{
  programs.claude-code = {
    enable = true;
    package = inputs.nix-claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };
}
