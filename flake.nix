{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Used to extract programs.sqlite for command-not-found
    nixos-channel.url = "https://nixos.org/channels/nixos-unstable/nixexprs.tar.xz";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        utils.follows = "flake-utils";
      };
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ocb-modules = {
      url = "github:MSF-OCB/NixOS/rvdp/flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , flake-utils
    , nixpkgs
    , nixos-channel
    , home-manager
    , sops-nix
    , ocb-modules
    }@inputs: with nixpkgs.lib;
    let
      system = flake-utils.lib.system.x86_64-linux;
      specialArgs = { inherit nixos-channel nixpkgs; };
    in
    {
      nixosModules.default = {
        imports = [
          ./modules/nvim.nix
          sops-nix.nixosModules.sops
        ];
      };

      nixosConfigurations = {
        nixer = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./org.nix
            ./hosts/nixer.nix
            ocb-modules.nixosModules.default
          ];
        };
        starbook = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = [
            self.nixosModules.default
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
            }
            ./hosts/starbook.nix
            ./hardware-config/starbook.nix
            ./modules/system.nix
          ];
        };
      };
    };
}

