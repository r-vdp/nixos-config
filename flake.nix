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
  };

  outputs =
    { self
    , flake-utils
    , nixpkgs
    , nixos-channel
    , home-manager
    , sops-nix
    }@inputs: with nixpkgs.lib;
    let
      system = flake-utils.lib.system.x86_64-linux;
      specialArgs = { inherit nixos-channel nixpkgs; };
    in
    {
      nixosModules.default = {
        imports = [
          ./modules/home-manager.nix
          ./modules/lib.nix
          ./modules/nvim.nix
          ./modules/reverse-tunnel.nix
          ./modules/system.nix
          ./users/ramses.nix
          home-manager.nixosModules.home-manager
          sops-nix.nixosModules.sops
        ];
      };

      nixosConfigurations = {
        nixer = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = [
            self.nixosModules.default
            ./hosts/nixer.nix
          ];
        };
        starbook = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = [
            self.nixosModules.default
            ./hosts/starbook.nix
          ];
        };
      };
    };
}

