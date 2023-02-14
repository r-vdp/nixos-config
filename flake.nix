{
  nixConfig = {
    extra-substituters = [
      "https://devenv.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

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
      inputs = {
        nixpkgs.follows = "nixpkgs";
        # Avoid a plethora of nixpkgs-stable entries in flake.lock by syncing them.
        #nixpkgs-stable.follows = "devenv/pre-commit-hooks/nixpkgs-stable";
        nixpkgs-stable.follows = "pre-commit-hooks/nixpkgs-stable";
      };
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # FIXME: temporarily add this input to avoid duplicate entries of deps in our
    # flake.lock file. This will not be needed anymore once
    #   https://github.com/NixOS/nix/issues/5790
    # is fixed, then we'll be able to say something like
    #   pre-commit-hooks.inputs.flake-utils.follows = "flake-utils";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
        flake-compat.follows = "devenv/flake-compat";
      };
    };
    devenv = {
      url = "github:cachix/devenv";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        pre-commit-hooks.follows = "pre-commit-hooks";
      };
    };
    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , flake-utils
    , nixpkgs
    , home-manager
    , sops-nix
    , nixos-generators
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
          mkStandardHost = hostname:
            nixpkgs.lib.nixosSystem {
              specialArgs = { inherit inputs; };
              modules = [
                self.nixosModules.default
                ./hosts/${hostname}
              ];
            };
        in
        flip genAttrs mkStandardHost [
          "nixer"
          "nuke"
          "starbook"
        ];
    }
    //
    flake-utils.lib.eachDefaultSystem (system: {
      packages = {
        # Build with "nix build '.#rescue-iso'
        rescue-iso = nixos-generators.nixosGenerate {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            self.nixosModules.default
            ./hosts/rescue-iso
          ];
          format = "iso";
        };
      };

      legacyPackages = {
        # As a temporary workaround, we put the home configurations under
        # legacyPackages so that we do not need to hard code the value for system.
        # See https://github.com/nix-community/home-manager/issues/3075
        homeConfigurations =
          let
            mkHomeConfig = username: hostname:
              home-manager.lib.homeManagerConfiguration {
                pkgs = nixpkgs.legacyPackages.${system};
                extraSpecialArgs = { inherit inputs; };
                modules = [
                  ./hosts/${hostname}
                  ./home-modules
                  ./home-profiles/standalone.nix
                  ./users/ramses/home.nix
                  { home = { inherit username; }; }
                ];
              };

            mkHomeConfigEntry = { username, hostname }:
              nameValuePair "${username}@${hostname}"
                (mkHomeConfig username hostname);
          in
          listToAttrs (
            map mkHomeConfigEntry [
              { username = "ramses"; hostname = "dev1"; }
              { username = "ramses"; hostname = "generic"; }
            ]
          );
      };
    });
}
