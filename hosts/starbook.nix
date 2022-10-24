{ config, lib, pkgs, ... }:

with lib;

let
  username = "ramses";
in
{
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };
    };

    initrd.luks.devices = {
      decrypted = {
        device = "/dev/disk/by-partuuid/07065c4d-825f-4a68-a388-8660c1dfed4a";
        header = "/dev/disk/by-partuuid/e1fda992-218c-4809-9522-01db59c8e6f8";
        allowDiscards = true;
        preLVM = true;
      };
    };
  };

  fileSystems = {
    "/" =
      {
        device = "/dev/disk/by-label/nixos-root";
        fsType = "ext4";
        options = [ "defaults" "noatime" "acl" ];
      };
    "/boot" =
      {
        device = "/dev/disk/by-label/nixos-boot";
        fsType = "ext4";
        options = [ "defaults" "noatime" "nosuid" "nodev" "noexec" ];
      };
    "/boot/efi" =
      {
        device = "/dev/disk/by-label/ESP";
        fsType = "vfat";
      };
  };

  networking = {
    hostName = "starbook";
    networkmanager = {
      enable = true;
      # Do not take DNS servers from DHCP
      dns = mkForce "none";
      wifi = {
        macAddress = "random";
      };
    };
  };

  time.timeZone = "Africa/Cairo";

  i18n = {
    defaultLocale = "en_GB.utf8";
    extraLocaleSettings = {
      LC_ADDRESS = "nl_BE.utf8";
      LC_IDENTIFICATION = "nl_BE.utf8";
      LC_MEASUREMENT = "nl_BE.utf8";
      LC_MONETARY = "nl_BE.utf8";
      LC_NAME = "nl_BE.utf8";
      LC_NUMERIC = "nl_BE.utf8";
      LC_PAPER = "nl_BE.utf8";
      LC_TELEPHONE = "nl_BE.utf8";
      LC_TIME = "nl_BE.utf8";
    };
  };

  # Enable the X11 windowing system.
  services = {
    xserver = {
      enable = true;
      # Enable the GNOME Desktop Environment.
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
      # Configure keymap in X11
      layout = "us";
      xkbVariant = "intl";
    };
    # Enable CUPS to print documents.
    printing.enable = true;
  };

  # Configure console keymap
  console.keyMap = "us-acentos";

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${username} = {
    isNormalUser = true;
    description = "Ramses";
    extraGroups = [ "networkmanager" "wheel" ];
  };
  home-manager.users.${username} = import ../users/${username}.nix;

  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: {
      vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
    };
  };

  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiVdpau
      libvdpau-va-gl
    ];
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
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
}

