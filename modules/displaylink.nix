{ ... }:

{
  # Anker Prime Docking Station (14-in-1, Triple Display) は DisplayLink チップ
  # (USB ID 17e9:7000 DisplayLink A83B3) 経由で追加ディスプレイを出力する。
  # このため Synaptics のプロプライエタリドライバ (displaylink + evdi カーネル
  # モジュール) が必要になる。
  #
  # ドライバ本体 (displaylink-620.zip) は再配布不可なため、リビルド前に手動で
  # store へ取り込んでおく必要がある:
  #
  #   nix-prefetch-url --name displaylink-620.zip \
  #     "https://www.synaptics.com/sites/default/files/exe_files/2025-09/DisplayLink%20USB%20Graphics%20Software%20for%20Ubuntu6.2-EXE.zip"
  #
  # videoDrivers に "displaylink" を加えると evdi モジュールと
  # DisplayLinkManager systemd サービスが自動で構成される。"modesetting" を
  # 先頭に残すことで内蔵 GPU 側の出力は従来どおり使われる。
  services.xserver.videoDrivers = [ "modesetting" "displaylink" ];

  # ホットプラグ時に確実に evdi が読み込まれるようブートで読み込む。
  boot.kernelModules = [ "evdi" ];
}
