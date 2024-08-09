{ config, lib, pkgs, ... }:

{
  environment = {
    gnome.excludePackages = with pkgs; [
      baobab
      snapshot
      gnome.gnome-clocks
      gnome.gnome-contacts
      gnome.gnome-system-monitor
      gnome.gnome-maps
      gnome.gnome-music
      gnome.epiphany
      gnome.totem
      gnome.gnome-weather
    ];

    systemPackages = with pkgs; [
      gnome-usage
      gnome-extension-manager
      gnomeExtensions.appindicator
      gnomeExtensions.app-icons-taskbar
      gnomeExtensions.legacy-gtk3-theme-scheme-auto-switcher
      gnomeExtensions.logo-menu
      gnomeExtensions.speedinator
      gnomeExtensions.tiling-assistant
      eyedropper
      loupe
    ];
  };

  programs = {
    dconf = {
      enable = true;
      profiles.user.databases = [
        {
          settings = with lib.gvariant; {
            "org/gnome/desktop/interface" = {
              gtk-theme = "adw-gtk3";
            };

            "org/gnome/desktop/wm/keybindings" = {
              switch-applications = "[]";
              switch-applications-backward = "[]";
              switch-windows = "[ '<Alt>Tab' ]";
              switch-windows-backward = "[ '<Shift><Alt>Tab' ]";
            };

            "org/gnome/desktop/wm/preferences" = {
              button-layout = ":minimize,maximize,close";
            };

            "org/gnome/shell" = {
              enabled-extensions = [
                "appindicatorsupport@rgcjonas.gmail.com"
                "aztaskbar@aztaskbar.gitlab.com"
                "legacyschemeautoswitcher@joshimukul29.gmail.com"
                "logomenu@aryan_k"
                "speedinator@liam.moe"
                "tiling-assistant@leleat-on-github"
                # places
                "places-menu@gnome-shell-extensions.gcampax.github.com"
              ];
            };

            "org/gnome/shell/extensions/aztaskbar" = {
              clock-position-in-panel = "RIGHT";
              clock-position-offset = mkInt32 1;
              icon-size = mkInt32 20;
              indicator-location = "BOTTOM";
              main-panel-height = "(true, 40)";
              override-panel-clock-format = "(true, '%_d %b  |  %H:%M')";
              panel-location = "BOTTOM";
              shift-middle-click-action = "QUIT";
            };

            "org/gnome/shell/extensions/Logo-menu" = {
              menu-button-icon-image = mkInt32 23;
              menu-button-icon-size = mkInt32 23;
              menu-button-system-monitor = "gnome-usage";
              menu-button-terminal = "gnome-console";
              show-activities-button = true;
              symbolic-icon = true;
            };
          };
        }
      ];
    };
  };

  services = {
    gnome = {
      evolution-data-server.enable = lib.mkForce true;
      games.enable = false;
      gnome-browser-connector.enable = true;
      gnome-online-accounts.enable = true;
      tracker.enable = true;
      tracker-miners.enable = true;
    };
    udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];
    xserver = {
      enable = true;
      displayManager = {
        gdm = {
          enable = true;
          autoSuspend = false;
        };
      };
      desktopManager.gnome.enable = true;
    };
  };
}
