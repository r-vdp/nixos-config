{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
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
    command-not-found = {
      url = "github:R-VdP/command-not-found";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , flake-utils
    , nixpkgs
    , home-manager
    , sops-nix
    , command-not-found
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
          command-not-found.nixosModules.command-not-found
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


