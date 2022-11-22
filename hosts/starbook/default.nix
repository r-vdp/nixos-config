{ config, lib, pkgs, ... }:

with lib;

{
  imports = [
    ./hardware-configuration.nix
  ];

  time.timeZone = "Africa/Cairo";

  settings.system.isHeadless = false;

  boot = {
    # Get sound working, but no microphone...
    # https://thesofproject.github.io/latest/getting_started/intel_debug/introduction.html#pci-devices-introduced-after-2016
    extraModprobeConfig = ''
      options snd-intel-dspcfg dsp_driver=1
    '';

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
        device = "/dev/disk/by-label/ESP";
        fsType = "vfat";
      };
  };

  swapDevices = [
    { device = "/dev/disk/by-label/swap"; }
  ];

  networking = {
    hostName = "starbook";
    networkmanager = {
      enable = true;
      # Do not take DNS servers from DHCP
      dns = mkForce "none";
      wifi = {
        macAddress = "preserve";
      };
    };
    extraHosts = ''
      # I hate captive portals
      41.128.153.50 ezxcess.antlabs.com
    '';
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

  # Enable sound with pipewire.
  sound.enable = false;
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

    # use the example session desktopManager
    # (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManagers).
  # services.xserver.libinput.enable = true;

  nixpkgs.config = {
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
}

