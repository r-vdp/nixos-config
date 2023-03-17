# Archival notice
This repo now lives on Sourcehut: https://git.sr.ht/~r-vdp/nixos-config


# My personal NixOS and home-manager configuration

## Installation

We partition using a script for now,
I should adapt this to use [disko] and [nixos-remote].

[disko]: https://github.com/nix-community/disko
[nixos-remote]: https://github.com/numtide/nixos-remote

```bash
lsblk
./partition.sh /dev/<device>
```

## Bootstrapping a standalone home-manager config on a remote server
```
nix --extra-experimental-features 'nix-command flakes' run 'github:nix-community/home-manager' -- --extra-experimental-features 'nix-command flakes' --verbose --refresh --flake 'github:R-VdP/nixos-config#ramses@generic' switch
```
