{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-channel.url = "https://nixos.org/channels/nixos-unstable/nixexprs.tar.xz";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ocb-modules = {
      url = "github:MSF-OCB/NixOS/rvdp/flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , nixos-channel
    , home-manager
    , ocb-modules
    }@inputs: with nixpkgs.lib;
    let
      system = "x86_64-linux";
    in
    {
      nixosModules.default = {
        imports = [
          ./modules/nvim.nix
        ];
      };

      nixosConfigurations = {
        nixer = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./.
            ./hosts/nixer.nix
            ocb-modules.nixosModules.default
          ];
        };
        nikser = nixpkgs.lib.nixosSystem {
          inherit system;
          # Pass the nixos-channel input to the modules
          specialArgs = { inherit nixos-channel; };
          modules = [
            self.nixosModules.default
            ./hosts/nikser.nix
            ./hardware-config/nikser.nix
            ./modules/system.nix
            ./modules/dropbox.nix
          ];
        };
        starbook = nixpkgs.lib.nixosSystem {
          inherit system;
          # Pass the nixos-channel input to the modules
          specialArgs = { inherit nixos-channel; };
          modules = [
            self.nixosModules.default
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.ramses = import ./users/ramses.nix;
            }
            ./hosts/starbook.nix
            ./hardware-config/starbook.nix
            ./modules/system.nix
            ./modules/dropbox.nix
          ];
        };
      };
    };
}

