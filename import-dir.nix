# Generate a list of all nix files and subdirectories in the given directory,
# the result can be assigned to imports in a module to import all files and
# subdirectories from the given directory.
{ fromDir
, ignoreFiles ? [ "default.nix" ]
, lib
}:

let
  safeLast = default: list:
    if lib.length list > 0 then lib.last list else default;
  extensionOf = name:
    safeLast "" (lib.splitString "." (toString name));

  notIgnored = path: ! lib.elem (baseNameOf path) ignoreFiles;
  isNixFile = path: extensionOf path == "nix";
  validPath = path: type:
    notIgnored path && (isNixFile path || type == "directory");
in
lib.attrValues
  (lib.mapAttrs (name: _type: fromDir + ("/" + name))
    (lib.filterAttrs validPath
      (builtins.readDir fromDir)))
