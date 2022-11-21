{ nix-index-database, ... }:
{
  home-manager = {
    # Extra arguments to pass to home-manager modules
    extraSpecialArgs = { inherit nix-index-database; };
    useGlobalPkgs = true;
    useUserPackages = true;
    sharedModules = [
      ../home-modules
    ];
  };
}

