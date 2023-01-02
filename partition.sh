#! /usr/bin/env bash

device="${1}"

if [ ! -b "${device}" ]; then
  echo "Please give the block device to install on as a paramter."
fi

function wait_for_devices() {
  local -a devs=("${@}")
  all_found=false
  for dev in "${devs[@]}"; do
    udevadm settle --exit-if-exists="${dev}"
  done
  for countdown in $( seq 60 -1 0 ); do
    missing=false
    for dev in "${devs[@]}"; do
      if [ ! -b "${dev}" ]; then
        missing=true
        echo "waiting for ${dev}... (${countdown})"
      fi
    done
    if [ "${missing}" = true ]; then
      partprobe "${device}"
      sleep 1
      for dev in "${devs[@]}"; do
        udevadm settle --exit-if-exists="${dev}"
      done
    else
      all_found=true
      break;
    fi
  done
  if [ "${all_found}" != true ]; then
    echo "Time-out waiting for devices."
    exit 1
  fi
}

sudo parted "${device}" -- mklabel gpt
sudo parted "${device}" -- mkpart ESP fat32 0% 1GB
sudo parted "${device}" -- set 1 boot on
sudo parted "${device}" -- mkpart primary 1GB 100%

wait_for_devices "/dev/disk/by-partlabel/ESP" "/dev/disk/by-partlabel/primary"

sudo mkfs.fat -F 32 -n ESP /dev/disk/by-partlabel/ESP

sudo cryptsetup luksFormat /dev/disk/by-partlabel/primary --type luks2
sudo cryptsetup luksOpen /dev/disk/by-partlabel/primary decrypted

wait_for_devices "/dev/mapper/decrypted"

sudo pvcreate /dev/mapper/decrypted
sudo vgcreate volgroup /dev/mapper/decrypted
sudo lvcreate -L 10G -n swap volgroup
sudo lvcreate -l 100%FREE -n nixos volgroup

wait_for_devices "/dev/volgroup/nixos" "/dev/volgroup/swap"

sudo mkswap -L swap /dev/volgroup/swap
sudo mkfs.btrfs -L nixos /dev/volgroup/nixos

wait_for_devices "/dev/disk/by-label/nixos"

sudo mkdir /mnt
sudo mount /dev/disk/by-label/nixos /mnt

sudo btrfs subvolume create /mnt/root
sudo btrfs subvolume create /mnt/home
sudo btrfs subvolume create /mnt/nix
sudo btrfs subvolume create /mnt/snapshots

sudo umount /mnt

sudo mount -o compressed=zstd,noatime,subvol=root /dev/by-label/nixos /mnt
mkdir /mnt/{boot,home,nix,snapshots}
sudo mount -o compressed=zstd,noatime,subvol=home /dev/by-label/nixos /mnt/home
sudo mount -o compressed=zstd,noatime,subvol=nix /dev/by-label/nixos /mnt/nix
sudo mount -o compressed=zstd,noatime,subvol=snapshots /dev/by-label/nixos /mnt/snapshots
sudo mount /dev/disk/by-label/ESP /mnt/boot

sudo btrfs subvolume snapshot /mnt/ /mnt/snapshots/empty-root

sudo nixos-install --no-root-passwd --root /mnt --flake 'github:R-VdP/nixos-config#<hostname>'
