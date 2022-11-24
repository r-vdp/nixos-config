{
  nixConfig = {
    extra-trusted-public-keys =
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
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
      inputs.nixpkgs.follows = "nixpkgs";
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
    , home-manager
    , sops-nix
    , devenv
    , nix-index-database
    }: with nixpkgs.lib;

    # Some things should be defined for every system.
    flake-utils.lib.eachDefaultSystem
      (system: {
        nixosModules.default =
          let
            # Add the devenv packages to nixpkgs
            devenv-overlay = final: prev: devenv.packages.${system};
          in
          {
            imports = [
              ./modules
              ./users
              home-manager.nixosModule
              sops-nix.nixosModule
            ];
            nixpkgs.overlays = [ devenv-overlay ];
          };
      })
    //
    # Things in here will define a single system that they are compatible with.
    {
      nixosConfigurations =
        let
          system = flake-utils.lib.system.x86_64-linux;
          mkStandardHost = hostname:
            nixpkgs.lib.nixosSystem {
              specialArgs = {
                inherit nixpkgs nix-index-database;
              };
              modules = [
                self.nixosModules.${system}.default
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

