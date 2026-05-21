{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
    };

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];

    shellAliases = {
      dev-browser = "chromium-browser --disable-web-security --user-data-dir '/tmp/chrome'";
      dc = "docker compose";
      docker-compose = "docker compose";
      vi = "nvim";
      vim = "nvim";
      view = "nvim -R";
      vimdiff = "nvim -d";
      vimconf = "vim ~/.config/nvim/init.lua";
      shconf = "vim ~/.zshrc";
      j = "ghq_peco";
      "ghq-search" = "ghq_remote_peco";
      ll = "eza -l -g -a --icons";
      ccusage = "npx ccusage@latest";
      python = "python3";
    };

    initContent = ''
      # Golang
      export GOPATH=$HOME/.go
      export PATH="$GOPATH/bin:$PATH"

      # QT setup for nvim
      export QT_QPA_PLATFORM=xcb

      # Switch Local GitHub Repositories
      function ghq_peco {
        local dir
        dir="$(ghq list -p | peco)"
        if [ -n "$dir" ]; then
          cd "$dir" || return
        fi
      }

      # Search & Clone Remote GitHub Repositories
      function ghq_remote_peco {
        local repo
        repo="$(gh repo list --limit 100 --json nameWithOwner --jq '.[].nameWithOwner' | peco)"
        if [ -n "$repo" ]; then
          ghq get "$repo"
          local dir
          dir="$(ghq list -p | grep -F "$repo")"
          if [ -n "$dir" ]; then
            cd "$dir" || return
          fi
        fi
      }

      # Powerlevel10k config
      [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

      # mise (version manager)
      if command -v mise >/dev/null 2>&1; then
        eval "$(mise activate zsh)"
      fi

      # Local overrides (untracked)
      [ -f ~/.zshrc.local ] && source ~/.zshrc.local
    '';
  };

  home.file.".p10k.zsh".source = ./files/p10k.zsh;
}
