{ lib, config, ...}:

with lib;

let
  bridge_interface = "br0";
  lan1_interface = "enp1s0";
  lan2_interface = "enp2s0";
  local_ip = "10.0.7.252";
  upstream_gateway = "10.0.7.254";
  nameservers = [ "9.9.9.9" "149.112.112.112" ];
in

{

  time.timeZone = "Europe/Brussels";

  settings = {
    network.host_name = "benuc012";
    boot.mode = "uefi";
    reverse_tunnel.enable = true;
    crypto.encrypted_opt.enable = true;
    docker.enable = true;
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
        append_rule4 "nixos-fw --protocol udp --dport 67:68 --jump nixos-fw-accept"

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
    interfaces.${bridge_interface}.ipv4.addresses = [ { address = local_ip; prefixLength = 22; } ];
    defaultGateway = { address = upstream_gateway; interface = bridge_interface; };
    inherit nameservers;
  };

  services.dhcpd4 = {
    enable = true;
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
}

