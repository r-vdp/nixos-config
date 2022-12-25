# My personal NixOS and home-manager configuration

## Installation

Manual for now, I should adapt this to use [disko] and [nixos-remote].

[disko]: https://github.com/nix-community/disko
[nixos-remote]: https://github.com/numtide/nixos-remote

```bash
lsblk

sudo parted /dev/sda -- mklabel gpt
sudo parted /dev/sda -- mkpart ESP fat32 0% 1GB
sudo parted /dev/sda -- set 1 boot on
sudo parted /dev/sda -- mkpart primary 1GB 100%

sudo mkfs.fat -F 32 -n ESP /dev/sda1

sudo cryptsetup luksFormat /dev/sda2 --type luks2
sudo cryptsetup luksOpen /dev/sda2 decrypted

sudo pvcreate /dev/mapper/decrypted
sudo vgcreate volgroup /dev/mapper/decrypted
sudo lvcreate -L 10G -n swap volgroup
sudo lvcreate -l 100%FREE -n nixos volgroup

sudo mkswap -L swap /dev/volgroup/swap
sudo mkfs.btrfs -L nixos /dev/volgroup/nixos

sudo mkdir /mnt
sudo mount /dev/volgroup/nixos /mnt

sudo btrfs subvolume create /mnt/root
sudo btrfs subvolume create /mnt/home
sudo btrfs subvolume create /mnt/nix
sudo btrfs subvolume create /mnt/snapshots

sudo umount /mnt

sudo mount -o compressed=zstd,noatime,subvol=root /dev/volgroup /mnt
mkdir /mnt/{boot,home,nix,snapshots}
sudo mount -o compressed=zstd,noatime,subvol=home /dev/volgroup /mnt/home
sudo mount -o compressed=zstd,noatime,subvol=nix /dev/volgroup /mnt/nix
sudo mount -o compressed=zstd,noatime,subvol=snapshots /dev/volgroup /mnt/snapshots
sudo mount /dev/disk/by-label/ESP /mnt/boot

sudo btrfs subvolume snapshot /mnt/ /mnt/snapshots/empty-root

sudo nixos-instal --no-root-passwd --root /mnt --flake 'github:R-VdP/nixos-config#<hostname>'
```
