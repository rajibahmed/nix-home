let
  nixpkgs = (builtins.fetchTarball (builtins.fromJSON (builtins.readFile ./nixpkgs.lock.json)));
  pkgs = import nixpkgs { };
in
{ config
, ...
}:
let
  coinSound = pkgs.fetchurl {
    url = "https://themushroomkingdom.net/sounds/wav/smw/smw_coin.wav";
    sha256 = "18c7dfhkaz9ybp3m52n1is9nmmkq18b1i82g6vgzy7cbr2y07h93";
  };
  coin = pkgs.writeShellScriptBin "coin" ''
     ${pkgs.sox}/bin/play --no-show-progress ${coinSound}
  '';
  vscode = pkgs.vscode;
  pulseaudio = pkgs.pulseaudioFull;
  dropbox = pkgs.dropbox;
in
{
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.firefox.enableAdobeFlash = false;
  nixpkgs.config.pulseaudio = true;

  home.packages = with builtins; with pkgs.lib;
    [ coin ] ++ (
      map (name: getAttrFromPath (splitString "." name) pkgs) (fromJSON (readFile ./pkgs.json))
    );

  programs.termite = {
    enable = false;
    font = "DejaVu Sans Mono for Powerline, 11";
    colorsExtra = ''
      # Base16 Solarized Dark
      # Author: Ethan Schoonover (modified by aramisgithub)

      foreground          = #93a1a1
      foreground_bold     = #eee8d5
      cursor              = #eee8d5
      cursor_foreground   = #002b36
      background          = #002B36

      # 16 color space

      # Black, Gray, Silver, White
      color0  = #002b36
      color8  = #657b83
      color7  = #93a1a1
      color15 = #fdf6e3

      # Red
      color1  = #dc322f
      color9  = #dc322f

      # Green
      color2  = #859900
      color10 = #859900

      # Yellow
      color3  = #b58900
      color11 = #b58900

      # Blue
      color4  = #268bd2
      color12 = #268bd2

      # Purple
      color5  = #6c71c4
      color13 = #6c71c4

      # Teal
      color6  = #2aa198
      color14 = #2aa198

      # Extra colors
      color16 = #cb4b16
      color17 = #d33682
      color18 = #073642
      color19 = #586e75
      color20 = #839496
      color21 = #eee8d5
    '';
  };
  home.file.".i3status.conf".text = ''
    general {
            colors = true
            interval = 5
    }

    #order += "ipv6"
    order += "disk /"
    #order += "run_watch DHCP"
    #order += "run_watch VPN"
    order += "wireless wlp3s0"
    order += "ethernet enp0s25"
    order += "battery 0"
    #order += "load"
    order += "tztime local"

    wireless wlp3s0 {
            format_up = "W: (%quality at %essid) %ip"
            format_down = "W: down"
    }

    ethernet enp0s25 {
            # if you use %speed, i3status requires root privileges
            format_up = "E: %ip (%speed)"
            format_down = "E: down"
    }

    battery 0 {
            format = "%status %percentage %remaining"
    }

    #run_watch DHCP {
    #        pidfile = "/var/run/dhclient*.pid"
    #}

    #run_watch VPN {
    #        pidfile = "/var/run/vpnc/pid"
    #}

    tztime local {
            format = "%Y-%m-%d %H:%M:%S"
    }

    #load {
    #        format = "%1min"
    #}

    disk "/" {
            format = "%avail"
    }
  '';
  home.file.".config/kitty/kitty.conf".text = ''
    background #002B36
    font_size 11.0
    input_delay 0
  '';
  fonts.fontconfig.enable = true;
  gtk = {
    enable = true;
    font = {
      name = "Noto Sans 10";
      package = pkgs.noto-fonts;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.gnome3.adwaita-icon-theme;
    };
    theme = {
      name = "Adapta-Nokto-Eta";
      package = pkgs.adapta-gtk-theme;
    };
  };
  programs.ssh.enable = true;
  programs.fzf.enable = true;
  programs.vim.enable = true;
  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    history.extended = true;
    oh-my-zsh = {
      enable = true;
      plugins = [
        "archlinux"
        "git-extras"
        "git"
        "gitfast"
        "github"
      ];
      #theme = "frozencow";
      theme = "agnoster";
    };
    loginExtra = ''
      setopt extendedglob
      source $HOME/.aliases
      bindkey '^R' history-incremental-pattern-search-backward
      bindkey '^F' history-incremental-pattern-search-forward
    '';
  };
  qt = {
    enable = true;
    platformTheme = "gtk";
  };

  services.gnome-keyring.enable = true;
  services.gpg-agent.enable = true;
  services.keybase.enable = true;
  services.network-manager-applet.enable = true;
  services.blueman-applet.enable = true;
  services.flameshot.enable = true;
  services.redshift = {
    enable = true;
    latitude = "51.985104";
    longitude = "5.898730";
    brightness.day = "1";
    brightness.night = "0.5";
    tray = true;
  };

  systemd.user.services.volumeicon = {
    Unit = {
      Description = "Volume Icon";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.volumeicon}/bin/volumeicon";
    };
  };

  systemd.user.services.dropbox = {
    Unit = {
      Description = "Dropbox";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${dropbox}/bin/dropbox";
    };
  };

  xdg.enable = true;
  news.display = "silent";
  xsession = {
    enable = true;
    initExtra = ''
      keepassxc &
    '';
    windowManager.i3 = rec {
      enable = true;
      config = {
        modifier = "Mod4";
        bars = [
          { statusCommand = "${pkgs.i3status}/bin/i3status"; }
        ];
        keybindings = let mod = config.modifier; in {
          "${mod}+t" = "exec kitty";
          "${mod}+w" = "exec chromium";
          "${mod}+e" = "exec thunar";
          "${mod}+q" = "exec dmenu_run";
          "${mod}+Print" = "exec flameshot gui";
          "${mod}+c" = "kill";

          "${mod}+Shift+grave" = "move scratchpad";
          "${mod}+grave" = "scratchpad show";
          "${mod}+j" = "focus left";
          "${mod}+k" = "focus down";
          "${mod}+l" = "focus up";
          "${mod}+semicolon" = "focus right";
          "${mod}+Left" = "focus left";
          "${mod}+Down" = "focus down";
          "${mod}+Up" = "focus up";
          "${mod}+Right" = "focus right";
          "${mod}+Shift+j" = "move left";
          "${mod}+Shift+k" = "move down";
          "${mod}+Shift+l" = "move up";
          "${mod}+Shift+semicolon" = "move right";
          "${mod}+Shift+Left" = "move left";
          "${mod}+Shift+Down" = "move down";
          "${mod}+Shift+Up" = "move up";
          "${mod}+Shift+Right" = "move right";
          "${mod}+h" = "split h";
          "${mod}+v" = "split v";
          "${mod}+f" = "fullscreen";
          "${mod}+Shift+s" = "layout stacking";
          "${mod}+Shift+t" = "layout tabbed";
          "${mod}+Shift+f" = "floating toggle";
          "${mod}+space" = "focus mode_toggle";
          "${mod}+1" = "workspace 1";
          "${mod}+2" = "workspace 2";
          "${mod}+3" = "workspace 3";
          "${mod}+4" = "workspace 4";
          "${mod}+5" = "workspace 5";
          "${mod}+6" = "workspace 6";
          "${mod}+7" = "workspace 7";
          "${mod}+8" = "workspace 8";
          "${mod}+9" = "workspace 9";
          "${mod}+0" = "workspace 10";
          "${mod}+Shift+1" = "move container to workspace 1";
          "${mod}+Shift+2" = "move container to workspace 2";
          "${mod}+Shift+3" = "move container to workspace 3";
          "${mod}+Shift+4" = "move container to workspace 4";
          "${mod}+Shift+5" = "move container to workspace 5";
          "${mod}+Shift+6" = "move container to workspace 6";
          "${mod}+Shift+7" = "move container to workspace 7";
          "${mod}+Shift+8" = "move container to workspace 8";
          "${mod}+Shift+9" = "move container to workspace 9";
          "${mod}+Shift+0" = "move container to workspace 10";
          "${mod}+Shift+r" = "restart";
          "${mod}+Shift+e" = "exec \"i3-nagbar -t warning -m 'You pressed the exit shortcut. Do you really want to exit i3? This will end your X session.' -b 'Yes, exit i3' 'i3-msg exit'\"";

          "XF86AudioRaiseVolume" = "exec ${pulseaudio}/bin/pactl set-sink-volume 0 +5%";
          "XF86AudioLowerVolume" = "exec ${pulseaudio}/bin/pactl set-sink-volume 0 -5%";
          "XF86AudioMute" = "exec ${pulseaudio}/bin/pactl set-sink-mute 0 toggle";

          "XF86MonBrightnessUp" = "exec ${pkgs.xorg.xbacklight}/bin/xbacklight -inc 5";
          "XF86MonBrightnessDown" = "exec ${pkgs.xorg.xbacklight}/bin/xbacklight -dec 5";

          "XF86AudioPlay" = "exec ${pkgs.playerctl}/bin/playerctl play";
          "XF86AudioPause" = "exec ${pkgs.playerctl}/bin/playerctl pause";
          "XF86AudioNext" = "exec ${pkgs.playerctl}/bin/playerctl next";
          "XF86AudioPrev" = "exec ${pkgs.playerctl}/bin/playerctl previous";
        };

        startup = [{
          command = "${pkgs.dex}/bin/dex -a";
          notification = false;
        }];
      };
      extraConfig = ''
        default_orientation horizontal
        workspace_layout tabbed

        workspace "10" output DVI-I-0
        assign [class="Pidgin"] "10"
        assign [class="Spotify"] = "10"

        for_window [window_role="scratchpad"] move scratchpad
        for_window [class="scratchpad"] move scratchpad
        for_window [class="keepassxc"] move scratchpad
        for_window [title="notes - Zim"] move scratchpad
        for_window [class="floating"] floating enable
      '';
    };
  };

  programs.git = {
    enable = true;
    userName = "Bob van der Linden";
    userEmail = "bobvanderlinden@gmail.com";
    signing.signByDefault = true;
    signing.key = "21198FFF4275C8197D723AD22A90361F99CF1795";
    aliases = {
      unstage = "reset HEAD --";
      pr = "pull --rebase";
      addp = "add --patch";
      comp = "commit --patch";
      co = "checkout";
      ci = "commit";
      c = "commit";
      b = "branch";
      p = "push";
      d = "diff";
      a = "add";
      s = "status";
      f = "fetch";
      br = "branch";
      pa = "add --patch";
      pc = "commit --patch";
      rf = "reflog";
      l = "log --graph --pretty='%Cred%h%Creset - %C(bold blue)<%an>%Creset %s%C(yellow)%d%Creset %Cgreen(%cr)' --abbrev-commit --date=relative";
      pp = "!git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD)";
      recent-branches = "branch --sort=-committerdate";
    };
    extraConfig = {
      core.editor = "${vscode}/bin/code --wait";
      merge.conflictstyle = "diff3";
    };
  };
  home.sessionVariables = {
    BROWSER = "${pkgs.chromium}/bin/chromium";
  };
  programs.autorandr.enable = true;
  programs.direnv.enable = true;
  programs.htop.enable = true;
  programs.home-manager.enable = true;
}
