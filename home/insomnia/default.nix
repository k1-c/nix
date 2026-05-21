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

  home.username = "insomnia";
  home.homeDirectory = "/home/insomnia";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
