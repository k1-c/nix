{ pkgs, ... }:

let
  # `gh auth git-credential` always answers with gh's *active* account, so
  # pick the account explicitly per directory instead.
  ghCredential = user:
    "!f() { test \"$1\" = get || exit 0; echo username=${user}; echo \"password=$(${pkgs.gh}/bin/gh auth token --hostname github.com --user ${user})\"; }; f";

  # Credential helpers accumulate across includes; "" clears the inherited list,
  # so ~/.gitconfig.local can override the account per directory the same way.
  credentialsFor = user: {
    "credential \"https://github.com\"".helper = [ "" (ghCredential user) ];
    "credential \"https://gist.github.com\"".helper = [ "" (ghCredential user) ];
  };
in
{
  programs.git = {
    enable = true;

    includes = [
      { path = "~/.gitconfig.local"; }
    ];

    ignores = [
      "**/.claude/settings.local.json"
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
        editor = "vim -c \"set fenc=utf-8\"";
      };
      help.autocorrect = 1;
      init.defaultBranch = "main";
      push.default = "current";
    } // credentialsFor "k1-c";
  };
}
