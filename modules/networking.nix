{ lib, ... }:

let
  # 常時ブロックするサイト。/etc/hosts で名前解決を潰すので、ブラウザを問わず効く
  # (Focus モードと違って ON/OFF は無い。外すにはここを直して rebuild する)。
  # hosts はワイルドカードを書けないので、サブドメインは 1 つずつ並べる。
  blockedHosts = lib.concatMap (domain: [
    domain
    "www.${domain}"
    "mobile.${domain}"
  ]) [
    "x.com"
    "twitter.com" # x.com へリダイレクトされる旧ドメイン
  ];
in
{
  networking.networkmanager.enable = true;

  networking.hosts = {
    "0.0.0.0" = blockedHosts;
    "::" = blockedHosts;
  };
}
