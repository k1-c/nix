{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    vim
    git
    gh
    curl
    wget
    google-chrome
    slack
  ];
}
