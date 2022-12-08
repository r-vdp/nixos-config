{ inputs, ... }:

{
  home-manager = {
    # Extra arguments to pass to home-manager modules
    extraSpecialArgs = { inherit inputs; };
    useGlobalPkgs = true;
    useUserPackages = true;
    sharedModules = [
      ../home-modules
      ../home-profiles/integrated.nix
    ];
  };
}

