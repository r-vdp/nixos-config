{ lib, config, pkgs, ...}:

with lib;

let
  bridge_interface = "br0";
  lan1_interface = "enp1s0";
  lan2_interface = "enp2s0";
  #local_ip = "10.0.7.252";
  #upstream_gateway = "10.0.7.254";
  nameservers = [
    "2620:fe::fe"
    "2620:fe::9"
    "9.9.9.9"
    "149.112.112.112"
  ];
in

{
  time.timeZone = "Europe/Brussels";

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Only safe on single-user machines
  programs.ssh.startAgent = mkForce true;

  system.autoUpgrade.rebootWindow = mkForce { lower = "10:00"; upper = "21:00"; };

  settings = {
    network.host_name = "nixer";
    boot.mode = "uefi";
    reverse_tunnel.enable = true;
    crypto = {
      encrypted_opt.enable = true;
      mounts = let
        ext_disk_wd = "ext_disk_wd";
      in {
        ${ext_disk_wd} = {
          enable = true;
          device = "/dev/disk/by-partlabel/${ext_disk_wd}";
          device_units = [ "dev-disk-by\\x2dpartlabel-ext_disk_wd.device" ];
          mount_point   = "/run/${ext_disk_wd}";
          mount_options = "acl,noatime,nosuid,nodev";
        };
      };
    };
    maintenance.nixos_upgrade.startAt = [ "Fri 18:00" ];
    docker.enable = true;
    services = {
      traefik.enable = true;
      #nomad.enable   = true;
    };
  };

  networking = {
    firewall = {
      extraCommands = ''
        function append_rule() {
          append_rule4 "''${1}"
          append_rule6 "''${1}"
        }

        function append_rule4() {
          do_append_rule "''${1}" "iptables"
        }

        function append_rule6() {
          do_append_rule "''${1}" "ip6tables"
        }

        function do_append_rule() {
          rule="''${1}"
          iptables="''${2}"
          if [ $(''${iptables} -C ''${rule} 2>/dev/null; echo $?) -ne "0" ]; then
            ''${iptables} -A ''${rule}
          fi
        }

        # Accept incoming DHCPv4 traffic
        #append_rule4 "nixos-fw --protocol udp --dport 67:68 --jump nixos-fw-accept"

        # Forward all outgoing traffic on the bridge belonging to existing connections
        append_rule  "FORWARD --out-interface ${bridge_interface} --match conntrack --ctstate ESTABLISHED,RELATED --jump ACCEPT"
        # Accept all outgoing traffic to the external interface of the bridge
        append_rule  "FORWARD --out-interface ${bridge_interface} --match physdev --physdev-out ${lan1_interface} --jump ACCEPT"
        # Accept DHCPv4
        append_rule4 "FORWARD --out-interface ${bridge_interface} --protocol udp --dport 67:68 --sport 67:68 --jump ACCEPT"
        # IPv6 does not work without ICMPv6
        append_rule6 "FORWARD --out-interface ${bridge_interface} --protocol icmpv6 --jump ACCEPT"
        # Do not forward by default
        ip46tables --policy FORWARD DROP
      '';
    };
    useDHCP = mkForce false;
    bridges.${bridge_interface}.interfaces = [ lan1_interface lan2_interface ];
    interfaces.${bridge_interface}.useDHCP = true;
    #interfaces.${bridge_interface}.ipv4.addresses = [ { address = local_ip; prefixLength = 22; } ];
    #defaultGateway = { address = upstream_gateway; interface = bridge_interface; };
    inherit nameservers;
  };

  services = {
    openssh = {
      ports = [ 22 2443 ];
    };

    ddclient = {
      enable = true;
      username = "none";
      passwordFile = config.settings.system.secrets.dest_directory + "/dynv6_token";
      use = ''web, web=https://ifconfig.io/ip'';
      server = "dynv6.com";
      protocol = "dyndns2";
      ipv6 = true;
      domains = [ "ramses.dynv6.net" ];
    };

    dhcpd4 = {
      enable = false;
      interfaces = [ bridge_interface ];
      extraConfig = ''
        option subnet-mask 255.255.252.0;
        option routers ${upstream_gateway};
        option domain-name-servers ${concatStringsSep ", " nameservers};
        min-lease-time ${toString (2 * 60 * 60)};
        default-lease-time ${toString (4 * 60 * 60)};
        max-lease-time ${toString (4 * 60 * 60)};
        subnet 10.0.4.0 netmask 255.255.252.0 {
          range 10.0.4.1 10.0.6.254;
        }
      '';
    };
  };
}

