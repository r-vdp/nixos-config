# Config used for standalone home-manager profiles, not integrated into NixOS.
# Build and activate a new generation with:
#   nix run nixpkgs#home-manager -- --flake 'github:R-VdP/nixos-config' switch
# To forcefully refresh the cached flake in the nix store, run:
#   nix flake show --refresh 'github:R-VdP/nixos-config'
{ lib, inputs, config, pkgs, ... }:

{
  home = {
    homeDirectory = lib.mkDefault "/home/${config.home.username}";

    # Add the nix package to the path, to get the one from our nixpkgs
    packages = [
      config.nix.package
    ];

    settings = {
      nixSettings.enable = lib.mkDefault true;

      keys.privateKeyFiles =
        let
          sshDir = "${config.home.homeDirectory}/.ssh/";
        in
        lib.mkDefault {
          current = "${sshDir}/id_ed25519";
          id_ec = "${sshDir}/id_ec";
        };
    };
  };

  nix.package = pkgs.nix;
}
