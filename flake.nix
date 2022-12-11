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

      rescue-iso = (nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [ ./hosts/iso ];
      }).config.system.build.isoImage;
    }
    //
    # As a temporary workaround, we put the homeConfigurations under packages
    # so that we do not need to hard code the value for system.
    # See https://github.com/nix-community/home-manager/issues/3075
    flake-utils.lib.eachDefaultSystem (system: {
      packages.homeConfigurations =
        let
          mkHomeConfig = entryName:
            let
              splitted = splitString "@" entryName;
              username = elemAt splitted 0;
              hostname =
                if length splitted > 1
                then elemAt splitted 1
                else error "No hostname provided!";
            in
            home-manager.lib.homeManagerConfiguration {
              pkgs = nixpkgs.legacyPackages.${system};
              extraSpecialArgs = { inherit inputs; };
              modules = [
                ./hosts/${hostname}
                ./home-modules
                ./home-profiles/standalone.nix
                ./users/ramses/home.nix
                ({ config, ... }: {
                  home = {
                    inherit username;
                    homeDirectory = mkDefault "/home/${config.home.username}";
                  };
                })
              ];
            };
        in
        # TODO make this better typed by taking an attrset as input and
          # transforming it into "user@host" = { ... }
        flip genAttrs mkHomeConfig [
          "ramses@dev1"
        ];
    });
}

