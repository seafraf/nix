# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, inputs, unstable-pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      inputs.rke2.nixosModules.default
    ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  systemd.services.containerd.path=with pkgs;[iptables nvidia-docker libnvidia-container];

  nixpkgs.config.allowUnfree = true;
  
  virtualisation = {
    containerd = {
      enable = true;
      settings = {
        version = 2;
        plugins."io.containerd.grpc.v1.cri" = {
          enable_cdi = lib.mkForce true;
          cdi_spec_dirs = lib.mkForce [" "];
        };
      };
    };
  };

  hardware = {
    nvidia-container-toolkit.enable = true;
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    nvidia = {
      modesetting.enable = true;
      open = true;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.latest;
    };
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernel.sysctl = {
      "fs.inotify.max_user_watches" = "2099999999";
      "fs.inotify.max_user_instances" = "2099999999";
      "fs.inotify.max_queued_events" = "2099999999";
    };
    kernelParams = [ "nvidia_drm.fbdev=1" ];
  };
  
  systemd.network = {
    enable = true;
    networks."10-enp7s0" = {
      matchConfig.Name = "enp7s0";
      address = [
        "192.168.1.200/24"
      ];
      routes = [
        { routeConfig.Gateway = "192.168.1.1"; }
      ];
      linkConfig.RequiredForOnline = "routable";
    }; 
  };

  networking = {
    hostName = "Kassadin";
    useDHCP = false;
  };

  networking.firewall.enable = lib.mkForce false;
  services.numtide-rke2 = {
    enable = true;
    role = "server";
    package = pkgs.rke2;
    settings = {
      kube-apiserver-arg = [ "anonymous-auth=false" ];
      tls-san = [ "gs.sfdr.me" "sfdr.me" "sforder.me" "bot.sfdr.me" ];
      write-kubeconfig-mode = "0644";
    };
  };

  services.openiscsi = {
    enable = true;
    name = "kassadin";
  };

  services.xserver = {
    videoDrivers = [ "nvidia" ];
  };
  
  # This sadness is required because Longhorn pods expect iscsi binaries here
  systemd.tmpfiles.rules = [
    "L+ /usr/local/bin - - - - /run/current-system/sw/bin/"
  ];


  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "Europe/Stockholm";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;


  

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.seafra = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF4sYFqUte7eUUD4gAEM2x4UygNOP8HHQFYUnHy0+RDF"
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
    nano
    wget
    openiscsi
    docker
  ]++ [
    unstable-pkgs.nh
  ];

  environment.variables = {
    FLAKE = "/home/seafra/nixos";
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "23.11"; # Did you read the comment?

  fileSystems = {
    "/mnt/sata-ssd-1" = {
      device = "/dev/disk/by-uuid/4e62b92d-8eb0-4ed4-87b3-cf7bb1272c33";
      fsType = "xfs";
      options = ["users" "nofail"];
    };
    "/mnt/sata-ssd-2" = {
      device = "/dev/disk/by-uuid/c3503d96-2062-4b3f-b6fc-27a180087600";
      fsType = "ext4";
      options = ["users" "nofail"];
    };
    "/mnt/lvm-12tb" = {
      device = "/dev/12tb-vg/12tb";
      fsType = "ext4";
    };
  };
}