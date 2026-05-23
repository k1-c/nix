{ ... }:

{
  imports = [
    ./packages.nix
    ./git.nix
    ./zsh.nix
    ./tmux.nix
    ./neovim.nix
    ./vscode.nix
    ./gitui.nix
    ./desktop
  ];

  home.username = "k1nix";
  home.homeDirectory = "/home/k1nix";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
