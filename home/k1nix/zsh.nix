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
      open = "xdg-open";
    };

    initContent = ''
      # Golang
      export GOPATH=$HOME/.go
      export PATH="$GOPATH/bin:$PATH"

      # QT setup for nvim
      export QT_QPA_PLATFORM=xcb

      # Switch Local GitHub Repositories
      function ghq_peco {
        local selected dir
        selected="$(ghq list | awk -F/ '{print $(NF-1)"/"$NF}' | peco)"
        if [ -n "$selected" ]; then
          dir="$(ghq list -p | grep -E "/$selected\$" | head -1)"
          [ -n "$dir" ] && cd "$dir"
        fi
      }

      # Search & Clone Remote GitHub Repositories
      # 自分のリポジトリ + 所属 organization のリポジトリをまとめて peco に渡す。
      # org メンバーシップが private な場合は gh auth に read:org スコープが必要。
      function ghq_remote_peco {
        local repo
        repo="$(
          {
            gh repo list --limit 200 --json nameWithOwner --jq '.[].nameWithOwner'
            gh api user/orgs --jq '.[].login' 2>/dev/null | while IFS= read -r owner; do
              [ -n "$owner" ] && gh repo list "$owner" --limit 200 --json nameWithOwner --jq '.[].nameWithOwner'
            done
          } | awk '!seen[$0]++' | peco
        )"
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

  # peco: 選択行が薄ピンクで読めない問題への対処。
  # Selected を bold + reverse にして、テーマ非依存で必ず読める状態にする。
  xdg.configFile."peco/config.json".text = builtins.toJSON {
    Prompt = "QUERY>";
    Style = {
      Basic = [ "on_default" "default" ];
      Selected = [ "bold" "reverse" ];
      Query = [ "yellow" "bold" ];
      Matched = [ "cyan" "bold" ];
      SavedSelection = [ "bold" "on_yellow" "black" ];
    };
  };
}
