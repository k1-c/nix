{ pkgs, ... }:

{
  programs.git = {
    enable = true;

    includes = [
      { path = "~/.gitconfig.local"; }
    ];

    settings = {
      user = {
        name = "k1-c";
        email = "shun.kimura@integritis.io";
      };

      alias = {
        c = "commit";
        st = "status";
        br = "branch";
        co = "checkout";
        sw = "switch";
        d = "!git --no-pager diff";
        dt = "difftool";
        sweep = "!git branch --merged main | grep -v 'main$' | xargs git branch -d && git remote prune origin";
        lg = "log --graph --all --pretty=format:'%Cred%h%Creset - %s %Cgreen(%cr) %C(bold blue)%an%Creset %C(yellow)%d%Creset'";
        swp = "!f() { git checkout $(git branch --sort=-committerdate | peco | sed 's/^..//'); }; f";
      };

      ghq.root = "~/dev/git";
      apply.whitespace = "fix";
      branch.sort = "-committerdate";
      core = {
        excludesfile = "~/.gitignore";
        attributesfile = "~/.gitattributes";
        editor = "vim -c \"set fenc=utf-8\"";
      };
      help.autocorrect = 1;
      init.defaultBranch = "main";
      push.default = "current";
      "credential \"https://github.com\"".helper = "!${pkgs.gh}/bin/gh auth git-credential";
      "credential \"https://gist.github.com\"".helper = "!${pkgs.gh}/bin/gh auth git-credential";
    };
  };
}
