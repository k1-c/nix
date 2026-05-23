{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    # vi / vim aliases come from zsh shellAliases.
    viAlias = false;
    vimAlias = false;
    # Plugins are managed inside init.lua by lazy.nvim; we don't declare them here.
  };

  # The actual init.lua and coc settings are tracked verbatim in files/.
  xdg.configFile."nvim/init.lua".source = ./files/nvim-init.lua;
  xdg.configFile."nvim/coc-settings.json".source = ./files/nvim-coc-settings.json;
}
