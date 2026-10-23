{ lib, pkgs, osConfig, ... }:

let
  # cosmic-bg の Source::Path はディレクトリを渡すと、その中の画像を
  # rotation_frequency 秒ごとに巡回するスライドショーになる (1 枚だけ固定したい場合は
  # ファイルまでのフルパスを書く)。
  # 使うのは cosmic-wallpapers の NASA/ESA の宇宙写真 7 枚 (jpg)
  # (orion_nebula / tarantula_nebula / webb-inspired-wallpaper-system76 など)。
  # どれも暗色寄りなので、Dark テーマ + 紫アクセント (#E79CFE) の Frosted Glass
  # パネルが乗っても文字が沈まない。
  # 1.10.0 で同じディレクトリに COSMIC-Pattern-{Dark,Light} / COSMIC-logo-{Dark,White}
  # (png) が増え、Light 版が巡回に混ざるので、jpg だけの symlink ディレクトリを渡す。
  # cosmic-bg は WalkDir の follow_links(true) で辿るので symlink で問題ない。
  #
  # NOTE: pkgs は home-manager.useGlobalPkgs = true 経由で system 側と同一なので、
  # modules/desktop/cosmic.nix の overlay が効いて 1.10.0 が来る。
  # store パスを直書きしているため GC で消えることはない (世代が参照を持つ)。
  wallpaperDir = pkgs.runCommand "cosmic-wallpapers-photos" { } ''
    mkdir -p $out
    ln -s ${pkgs.cosmic-wallpapers}/share/backgrounds/cosmic/*.jpg $out/
  '';

  # cosmic-bg-config の Entry (ron)。フィールド名と enum の綴りは cosmic-bg 1.6.0 の
  # バイナリ内シンボルに合わせてある (Source: Path/Color, ScalingMode: Fit/Stretch/Zoom,
  # FilterMethod: Nearest/Linear/Lanczos, SamplingMethod: Alphanumeric/Random)。
  # 1.10.0 でも同じ綴りであることを確認済み。
  #   filter_by_theme  : 明暗テーマで絞り込むための設定。1.10.0 時点では
  #                      cosmic-bg 側が未実装 (src/wallpaper.rs の TODO) なので false のまま。
  #   sampling_method  : Random = 巡回順をシャッフル。ファイル名順にしたいなら Alphanumeric。
  #   scaling_mode     : Zoom = アスペクト比を保ったまま画面いっぱいに切り取る。
  #   filter_method    : Lanczos = 拡大時の品質優先。
  backgroundEntry = ''
    (
        output: "all",
        source: Path("${wallpaperDir}"),
        filter_by_theme: false,
        rotation_frequency: 1800,
        filter_method: Lanczos,
        scaling_mode: Zoom,
        sampling_method: Random,
    )
  '';
in
{
  # COSMIC を有効にしているのは mind だけ (hosts/mind/default.nix)。
  # 他ホストで pkgs.cosmic-wallpapers を forcing しないよう mkIf で丸ごと落とす
  # (mkIf の中身は条件が false なら評価されない)。
  config = lib.mkIf (osConfig.services.desktopManager.cosmic.enable or false) {
    # cosmic-config は「1 フィールド = 1 ファイル」形式。
    #
    # NOTE: COSMIC Settings → Wallpaper の GUI もまったく同じパスに書き込むため、
    # ここを xdg.configFile で握ると GUI からの壁紙変更ができなくなる
    # (読み取り専用 symlink になり保存が弾かれる)。壁紙を変えたい時はこの nix を編集する。
    xdg.configFile = {
      # same-on-all が true の間は output.<出力名> の個別エントリは参照されず all だけが効く。
      # (GUI 時代に書かれた output.DP-2 が残っていても無視される)
      "cosmic/com.system76.CosmicBackground/v1/same-on-all".text = "true";
      "cosmic/com.system76.CosmicBackground/v1/backgrounds".text = "[]";
      "cosmic/com.system76.CosmicBackground/v1/all".text = backgroundEntry;
    };
  };
}
