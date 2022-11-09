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
    nix-index-database.url = "github:Mic92/nix-index-database";
  };

  outputs =
    { self
    , flake-utils
    , nixpkgs
    , home-manager
    , sops-nix
    , nix-index-database
    }@inputs: with nixpkgs.lib;
    {
      nixosModules.default = {
        imports = [
          ./modules/home-manager.nix
          ./modules/lib.nix
          ./modules/nvim.nix
          ./modules/reverse-tunnel.nix
          ./modules/system.nix
          ./users/ramses
          home-manager.nixosModule
          sops-nix.nixosModule
        ];
      };

      nixosConfigurations =
        let
          system = flake-utils.lib.system.x86_64-linux;
          specialArgs = { inherit nixpkgs nix-index-database; };

          mkStandardHost = hostname:
            nixpkgs.lib.nixosSystem {
              inherit system specialArgs;
              modules = [
                self.nixosModules.default
                ./hosts/${hostname}
              ];
            };
        in
        flip genAttrs mkStandardHost [
          "nixer"
          "starbook"
        ];
    };
}

