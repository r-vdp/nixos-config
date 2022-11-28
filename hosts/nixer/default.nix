{ lib, config, pkgs, ... }:

with lib;

let
  bridge_interface = "br0";
  lan1_interface = "enp1s0";
  lan2_interface = "enp2s0";
  #local_ip = "10.0.7.252";
  #upstream_gateway = "10.0.7.254";
  inherit (config.settings.system) nameservers;
in

{
  imports = [
    ./hardware-configuration.nix
  ];

  time.timeZone = "Europe/Brussels";

  settings.system.isHeadless = true;

  boot.kernel.sysctl = {
    "net.ipv6.conf.${bridge_interface}.use_tempaddr" = mkForce "2";
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos_root";
      fsType = "ext4";
      options = [ "defaults" "noatime" "acl" ];
    };
    "/boot" = {
      device = "/dev/disk/by-label/EFI";
      fsType = "vfat";
    };
  };

  sops.secrets = {
    sshv6_token = { };
    opt-keyfile = { };
  };

  # TODO
  #swapDevices = [
  #  { device = "/dev/disk/by-label/swap"; }
  #];

  #settings = {
  #  maintenance.enable = false;
  #};

  networking = {
    hostName = "nixer";
    useNetworkd = true;
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
    useDHCP = true;
    bridges.${bridge_interface}.interfaces = [ lan1_interface lan2_interface ];
    interfaces.${bridge_interface} = {
      useDHCP = true;
      tempAddress = "default";
      #ipv4.addresses = [ { address = local_ip; prefixLength = 22; } ];
    };
    #defaultGateway = { address = upstream_gateway; interface = bridge_interface; };
    inherit nameservers;
  };

  systemd = mkMerge [
    {
      network = {
        enable = true;

        netdevs.${bridge_interface} = {
          enable = true;
          netdevConfig = {
            Name = bridge_interface;
            Kind = "bridge";
          };
        };

        networks = {
          ${lan1_interface} = {
            enable = true;
            matchConfig = { Name = lan1_interface; };
            bridge = [ bridge_interface ];
          };
          ${lan2_interface} = {
            enable = true;
            matchConfig = { Name = lan2_interface; };
            bridge = [ bridge_interface ];
          };
          ${bridge_interface} = {
            enable = true;
            matchConfig = { Name = bridge_interface; };
            DHCP = "yes";
            dhcpV6Config = { UseDNS = false; };
            ipv6AcceptRAConfig = { UseDNS = false; };
            dhcpV4Config = { UseDNS = false; };
            networkConfig = { IPv6PrivacyExtensions = "kernel"; };
          };
        };
      };
    }
    (
      let
        open_opt_service = "open-encrypted-opt";
        decrypted_name = "decrypted_opt";
      in
      {
        services = {
          ${open_opt_service} =
            let
              device = "/dev/LVMVolGroup/nixos_data";
            in
            {
              enable = true;
              description = "Open the encrypted /opt partition.";
              conflicts = [ "shutdown.target" ];
              before = [ "shutdown.target" ];
              restartIfChanged = false;
              unitConfig = {
                DefaultDependencies = "no";
                ConditionPathExists = "!/dev/mapper/${decrypted_name}";
                AssertPathExists = config.sops.secrets.opt-keyfile.path;
              };
              serviceConfig = {
                User = "root";
                Type = "oneshot";
                Restart = "on-failure";
                RemainAfterExit = true;
                ExecStop = ''
                  ${pkgs.cryptsetup}/bin/cryptsetup close --deferred ${decrypted_name}
                '';
              };
              script = ''
                # Avoid a harmless warning
                mkdir --parents /run/cryptsetup

                ${pkgs.cryptsetup}/bin/cryptsetup \
                  open ${device} ${decrypted_name} \
                  --key-file ${config.sops.secrets.opt-keyfile.path}

                # We wait to exit from this script until
                # the decrypted device has been created by udev
                dev="/dev/mapper/${decrypted_name}"
                echo "Making sure that ''${dev} exists before exiting..."
                for countdown in $( seq 60 -1 0 ); do
                  if [ -b "''${dev}" ]; then
                    exit 0
                  fi
                  echo "Waiting for ''${dev}... (''${countdown})"
                  sleep 5
                  udevadm settle --exit-if-exists="''${dev}"
                done
                echo "Device node could not be found, exiting..."
                exit 1
              '';
            };
        };
        mounts = [
          {
            enable = true;
            what = "/dev/mapper/${decrypted_name}";
            where = "/opt";
            type = "ext4";
            options = "acl,noatime,nosuid,nodev";
            after = [ "${open_opt_service}.service" ];
            requires = [ "${open_opt_service}.service" ];
            wantedBy = [
              "multi-user.target"
              "${open_opt_service}.service"
            ];
          }
          {
            enable = true;
            what = "/opt/.home";
            where = "/home";
            type = "none";
            options = "bind";
            after = [ "opt.mount" ];
            requires = [ "opt.mount" ];
            wantedBy = [ "multi-user.target" ];
          }
        ];
      }
    )
  ];

  services = {
    openssh = {
      ports = [ 22 2443 ];
    };

    avahi = {
      interfaces = [ bridge_interface ];
    };

    ddclient = {
      enable = true;
      username = "VoEF8e1gHa1FpVWT";
      passwordFile = config.sops.secrets.sshv6_token.path;
      use = ''web, web=https://api6.ipify.org'';
      server = "domains.google.com";
      protocol = "dyndns2";
      ssl = true;
      ipv6 = true;
      domains = [ "sshv6.engyandramses.xyz" ];
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

