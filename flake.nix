{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    ocb-modules = {
      url = "github:MSF-OCB/NixOS/rvdp/flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Is there a better way?
    private-key = {
      url = "/etc/nixos/local/id_tunnel";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, ocb-modules, private-key }: with nixpkgs.lib;
    let
      system = "x86_64-linux";
    in
    {
      nixosModules.default = {
        imports = [
          ./.
          ocb-modules.nixosModules.default
          {
            settings.system.private_key_source = private-key;
          }
        ];
      };

      nixosConfigurations = {
        nixer = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            self.nixosModules.default
            ./hosts/nixer.nix
          ];
        };
      };
    };
}

