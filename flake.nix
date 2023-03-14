{
  nixConfig = {
    extra-trusted-substituters = [
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
    #   devenv.inputs.pre-commit-hooks.inputs.flake-utils.follows = "flake-utils";
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
          "nuke"
          "starbook"
        ];
    }
    //
    flake-utils.lib.eachSystem
      [
        flake-utils.lib.system.x86_64-linux
        flake-utils.lib.system.aarch64-linux
      ]
      (system: {
        packages =
          let
            pkgs = inputs.nixpkgs.legacyPackages.${system};
          in
          {
            coreboot-configurator = pkgs.libsForQt5.callPackage ./pkgs/coreboot-configurator.nix { };

            flashrom = pkgs.flashrom.overrideAttrs (prevAttrs: {
              src = pkgs.fetchzip {
                url = "https://download.flashrom.org/releases/flashrom-v${prevAttrs.version}.tar.bz2";
                hash = "sha256-rXwD8kpIrmmGJQu0NHHjIPGTa4+xx+H0FdqwAwo6ePg=";
              };

              nativeBuildInputs = prevAttrs.nativeBuildInputs ++ (with pkgs; [
                meson
                ninja
              ]);

              buildInputs = prevAttrs.buildInputs ++ (with pkgs; [
                cmocka
              ]);

              mesonFlags = [
                "-Dprogrammer=auto"
              ];

              postInstall =
                let
                  udevRulesPath = "lib/udev/rules.d/flashrom.rules";
                in
                ''
                  # After the meson build, the udev rules file is no longer present
                  # in the build dir, so we need to get it from $src and patch it
                  # again.
                  # There might be a better way to do this...
                  install -Dm644 $src/util/flashrom_udev.rules $out/${udevRulesPath}
                  substituteInPlace $out/${udevRulesPath} \
                    --replace 'GROUP="plugdev"' 'TAG+="uaccess", TAG+="udev-acl"'
                '';
            });

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
