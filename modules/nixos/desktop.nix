{
  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
    # add /etc/x11/xkb
    exportConfiguration = true;
  };

  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
}
