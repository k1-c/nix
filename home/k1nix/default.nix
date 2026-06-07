{ ... }:

{
  imports = [
    ./packages.nix
    ./git.nix
    ./zsh.nix
    ./mise.nix
    ./prisma.nix
    ./tmux.nix
    ./neovim.nix
    ./vscode.nix
    ./gitui.nix
    ./claude-code.nix
    ./desktop
  ];

  home.username = "k1nix";
  home.homeDirectory = "/home/k1nix";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
