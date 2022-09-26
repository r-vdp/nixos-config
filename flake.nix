{
  inputs = {
    ocb-modules = {
      url = "github:MSF-OCB/NixOS/rvdp/flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ocb-modules }: with nixpkgs.lib;
    let
      system = "x86_64-linux";
    in
    {
      nixosModules.default = {
        imports = [
          ./.
          ocb-modules.nixosModules.default
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

