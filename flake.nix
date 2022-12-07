{
  nixConfig = {
    extra-substituters = [
      "https://nixpkgs-unfree.cachix.org"
      "https://devenv.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    ];
  };

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unfree = {
      url = "github:numtide/nixpkgs-unfree";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        utils.follows = "flake-utils";
      };
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        # Avoid a plethora of nixpkgs-stable entries in flake.lock by syncing them.
        nixpkgs-stable.follows = "devenv/pre-commit-hooks/nixpkgs-stable";
      };
    };
    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database.url = "github:Mic92/nix-index-database";
  };

  outputs =
    { self
    , flake-utils
    , nixpkgs
    , nixpkgs-unfree
    , home-manager
    , sops-nix
    , ...
    }@inputs: with nixpkgs.lib; {
      nixosModules.default = {
        imports = [
          ./modules
          ./users
          home-manager.nixosModule
          sops-nix.nixosModule
        ];
      };

      nixosConfigurations =
        let
          system = flake-utils.lib.system.x86_64-linux;
          mkStandardHost = hostname:
            nixpkgs-unfree.lib.nixosSystem {
              specialArgs = { inherit inputs; };
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

