{ device ? "/dev/null" }:

{
  disk.${device} = {
    inherit device;
    type = "disk";
    content = {
      type = "table";
      format = "gpt";
      partitions = [
        {
          type = "partition";
          name = "ESP";
          start = "1MiB";
          end = "1GiB";
          fs-type = "fat32";
          bootable = true;
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
          };
        }
        {
          type = "partition";
          name = "luks";
          start = "1GiB";
          end = "100%";
          content = {
            type = "luks";
            name = "decrypted";
            content = {
              type = "lvm_pv";
              vg = "volgroup";
            };
          };
        }
      ];
    };
  };
  lvm_vg.pool = {
    type = "lvm_vg";
    lvs = {
      swap = {
        type = "lvm_lv";
        size = "10GiB";
        content = {
          type = "swap";
        };
      };
      nixos = {
        type = "lvm_lv";
        size = "100%FREE"; # TODO: does not work yet in disko?
        content = {
          type = "btrfs";
          subvolumes =
            let
              mountOptions = [ "defaults" "compress=zstd" "autodefrag" ];
            in
            {
              "/" = { inherit mountOptions; };
              "/home" = { inherit mountOptions; };
              "/nix" = { inherit mountOptions; };
              "/snapshots" = { inherit mountOptions; };
            };
        };
      };
    };
  };
}
