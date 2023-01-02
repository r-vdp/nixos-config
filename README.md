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
