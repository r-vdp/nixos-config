# Generate a list of all nix files and subdirectories in the given directory,
# the result can be assigned to imports in a module to import all files and
# subdirectories from the given directory.
{ fromDir
, ignoreFiles ? [ "default.nix" ]
, lib
}:

with lib;

let
  safeLast = default: list:
    if length list > 0 then last list else default;
  extensionOf = name:
    safeLast "" (splitString "." (toString name));

  notIgnored = path: ! elem (baseNameOf path) ignoreFiles;
  isNixFile = path: extensionOf path == "nix";
  validPath = path: type:
    notIgnored path && (isNixFile path || type == "directory");
in
attrValues
  (mapAttrs (name: _type: fromDir + ("/" + name))
    (filterAttrs validPath
      (builtins.readDir fromDir)))

