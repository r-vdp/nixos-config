{
  nixConfig = {
    extra-substituters = [
      "https://devenv.cachix.org"
    ];
    extra-trusted-public-keys = [
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
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
        nixpkgs-stable.follows = "devenv/pre-commit-hooks/nixpkgs-stable";
      };
    };
    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
      # FIXME: enable this line once the bug in Nix is fixed
      # TODO: add issue reference
      #inputs.pre-commit-hooks.inputs.flake-utils.follows = "flake-utils";
    };
    nix-index-database.url = "github:Mic92/nix-index-database";
  };

  outputs =
    { self
    , flake-utils
    , nixpkgs
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
          "starbook"
        ];

      homeConfigurations =
        let
          systemMapping = {
            # Add any systems with a different system architecture here and
            # in the mapping below.
            "default" = flake-utils.lib.system.x86_64-linux;
          };
          mkHomeConfig = entryName:
            let
              splitted = splitString "@" entryName;
              username = elemAt splitted 0;
              hostname =
                if length splitted > 1
                then elemAt splitted 1
                else "default";
              system =
                if systemMapping ? hostname
                then systemMapping.${hostname}
                else systemMapping.default;
            in
            home-manager.lib.homeManagerConfiguration {
              pkgs = nixpkgs.legacyPackages.${system};
              extraSpecialArgs = { inputs = inputs // { inherit username; }; };
              modules = [
                ./home-modules
                ./home-profiles/standalone.nix
                ./users/ramses/home.nix
              ];
            };
        in
        flip genAttrs mkHomeConfig [
          # Add any systems with a different system architecture here and
          # in the mapping above.
          "ramses"
        ];
    };
}

