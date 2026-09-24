{
  system.autoUpgrade = {
    enable = true;
    flake = "github:k1-c/nix";
    flags = [ "-L" ];
    # daily: claude-code など速く動くツールを追随させる。差分が無い日は no-op。
    #
    # lock の更新はここではしない。flake がリモート (github:k1-c/nix) なので
    # store 上の読み取り専用コピーになり、--recreate-lock-file を付けると
    #   error: cannot write modified lock file of flake 'github:k1-c/nix'
    # で毎回失敗する (2026-09-24 に発覚。それまで自動更新は一度も成功していなかった)。
    # 代わりに .github/workflows/update-claude-code.yml が nix-claude-code だけを
    # 毎日 bump して main に push し、ここは committed lock をそのまま適用する。
    # linear-tui も同様に update-linear-tui.yml が最新リリースへ bump する。
    # 他の input は flake.nix のコメント通り意図的に pin してあるので、まとめて
    # 最新へ解決されると niri などが壊れる。更新は手元で個別に行う。
    dates = "daily";
    randomizedDelaySec = "45min";
    allowReboot = false;
  };
}
