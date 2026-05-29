{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    google-chrome
    slack
  ];
}
