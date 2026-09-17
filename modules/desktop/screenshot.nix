{ pkgs, ... }:

let
  # Spectacle 相当 (領域選択 → 注釈 → クリップボード/保存) を Wayland 汎用の
  # grim + slurp + satty で組んだラッパー。COSMIC / Niri / Hyprland のどのセッションでも
  # 同じコマンドで動く (compositor 固有の protocol ではなく wlr-screencopy を使うため)。
  #
  # COSMIC 標準の Print キー (cosmic-screenshot → xdg-desktop-portal-cosmic) は
  # 領域/ウィンドウ/画面の切り出しと保存まではやるが注釈機能が無い。
  # 注釈したい時だけこちらを呼ぶ、という住み分け。
  screenshot-annotate = pkgs.writeShellApplication {
    name = "screenshot-annotate";
    runtimeInputs = with pkgs; [ grim slurp satty wl-clipboard ];
    text = ''
      outdir="''${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
      mkdir -p "$outdir"

      # 引数無し = 領域選択。`screenshot-annotate full` = 画面全体。
      if [ "''${1:-region}" = "full" ]; then
        grim - > /tmp/screenshot-annotate.$$.png
      else
        # slurp を Esc でキャンセルした場合はここで静かに終了する。
        geometry=$(slurp -d) || exit 0
        grim -g "$geometry" - > /tmp/screenshot-annotate.$$.png
      fi

      # satty の --output-filename は chrono の strftime 指定子を展開するので
      # date(1) を挟まずにタイムスタンプ付きファイル名を作れる。
      # Enter = クリップボードへコピーして終了、Ctrl+S = ファイル保存。
      satty --filename /tmp/screenshot-annotate.$$.png \
        --output-filename "$outdir/Screenshot_%Y-%m-%d_%H-%M-%S.png" \
        --copy-command wl-copy \
        --initial-tool rectangle \
        --actions-on-enter save-to-clipboard \
        --early-exit

      rm -f /tmp/screenshot-annotate.$$.png
    '';
  };
in
{
  environment.systemPackages = with pkgs; [
    satty
    screenshot-annotate
  ];
}
