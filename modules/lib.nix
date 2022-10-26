{ config, lib, pkgs, ... }:

with lib;

/* We structure this file as one big let expression from which we will then
  inherit all the defined functions.
  The main reason is that let expressions are recursive while attribute sets
  are not, so within a let expression definitions can recursively reference
  each other independent of the order in which they have been defined.
*/
let
  # compose [ f g h ] x == f (g (h x))
  compose =
    let
      apply = f: x: f x;
    in
    flip (foldr apply);

  applyN = n: f: compose (genList (const f) n);

  applyTwice = applyN 2;

  filterEnabled = filterAttrs (_: conf: conf.enable);

  # concatMapAttrsToList :: (String -> v -> [a]) -> AttrSet -> [a]
  concatMapAttrsToList = f: compose [
    concatLists
    (mapAttrsToList f)
  ];

  /* Find duplicate elements in a list in O(n) time

    Example:
    find_duplicates [ 1 2 2 3 4 4 4 5 ]
    => [ 2 4 ]
  */
  find_duplicates =
    let
      /* Function to use with foldr
        Given an element and a set mapping elements (as Strings) to booleans,
        it will add the element to the set with a value of:
        - false if the element was not previously there, and
        - true  if the element had been added already
        The result after folding, is a set mapping duplicate elements to true.
      */
      update_duplicates_set = el: set:
        let
          is_duplicate = el: hasAttr (toString el);
        in
        set // { ${toString el} = is_duplicate el set; };
    in
    compose [
      attrNames # return the name only
      (filterAttrs (flip const)) # filter on trueness of the value
      (foldr update_duplicates_set { }) # fold to create the duplicates set
    ];

  /* Function to find duplicate mappings in a list of attrsets
    *
    *   find_duplicate_mappings [ { "foo" = 1; "bar" = 2; } { "foo" = 3; } ]
    *     -> { "foo" = [ 1 3 ] }
  */
  find_duplicate_mappings =
    let
      # For every element seen, we add an entry to the set
      update_duplicates_set = el: set: set // { ${toString el} = true; };
    in
    compose [
      (filterAttrs (_: v: length v >= 2)) # filter on users having 2 or more profiles
      (mapAttrs (_: attrNames)) # collect just the different profile names
      (foldAttrs update_duplicates_set { }) # collect the values for the different keys
    ];

  # recursiveUpdate merges the two resulting attribute sets recursively
  recursiveMerge = foldr recursiveUpdate { };

  stringNotEmpty = s: stringLength s != 0;

  /* A type for host names, host names consist of:
    * a first character which is an upper or lower case ascii character
    * followed by zero or more of: dash (-), upper case ascii, lower case ascii, digit
    * followed by an upper or lower case ascii character or a digit
  */
  host_name_type =
    types.strMatching "^[[:upper:][:lower:]][-[:upper:][:lower:][:digit:]]*[[:upper:][:lower:][:digit:]]$";
  empty_str_type = types.strMatching "^$" // {
    description = "empty string";
  };
  pub_key_type =
    let
      key_data_pattern = "[[:lower:][:upper:][:digit:]\\/+]";
      key_patterns =
        let
          /* These prefixes consist out of 3 null bytes followed by a byte giving
            the length of the name of the key type, followed by the key type itself,
            and all of this encoded as base64.
            So "ssh-ed25519" is 11 characters long, which is \x0b, and thus we get
            b64_encode(b"\x00\x00\x00\x0bssh-ed25519")
            For "ecdsa-sha2-nistp256", we have 19 chars, or \x13, and we get
            b64encode(b"\x00\x00\x00\x13ecdsa-sha2-nistp256")
            For "ssh-rsa", we have 7 chars, or \x07, and we get
            b64encode(b"\x00\x00\x00\x07ssh-rsa")
          */
          ed25519_prefix = "AAAAC3NzaC1lZDI1NTE5";
          nistp256_prefix = "AAAAE2VjZHNhLXNoYTItbmlzdHAyNTY";
          rsa_prefix = "AAAAB3NzaC1yc2E";
        in
        {
          ssh-ed25519 =
            "^ssh-ed25519 ${ed25519_prefix}${key_data_pattern}{48}$";
          ecdsa-sha2-nistp256 =
            "^ecdsa-sha2-nistp256 ${nistp256_prefix}${key_data_pattern}{108}=$";
          # We require 2048 bits minimum. This limit might need to be increased
          # at some point since 2048 bit RSA is not considered very secure anymore
          ssh-rsa =
            "^ssh-rsa ${rsa_prefix}${key_data_pattern}{355,}={0,2}$";
        };
      pub_key_pattern = concatStringsSep "|" (attrValues key_patterns);
      description =
        ''valid ${concatStringsSep " or " (attrNames key_patterns)} key, '' +
        ''meaning a string matching the pattern ${pub_key_pattern}'';
    in
    types.strMatching pub_key_pattern // { inherit description; };

  ifPathExists = path: optional (builtins.pathExists path) path;

  traceImportJSON = compose [
    (filterAttrsRecursive (k: _: k != "_comment"))
    importJSON
    (traceValFn (f: "Loading file ${toString f}..."))
  ];

  # If the given option exists in the given path, then we return the option,
  # otherwise we return null.
  # This can be used to optionally set options:
  #   config.foo.bar = {
  #     ${keyIfExists config.foo.bar "baz"} = valueIfBazOptionExists;
  #   };
  keyIfExists = path: option:
    if hasAttr option path then option else null;

  # Prepend a string with a given number of spaces
  # indentStr :: Int -> String -> String
  indentStr = n: str:
    let
      spacesN = compose [ concatStrings (genList (const " ")) ];
    in
    (spacesN n) + str;

  mkSudoStartServiceCmds =
    { serviceName
    , extraOpts ? [ "--system" ]
    }:
    let
      optsStr = concatStringsSep " " extraOpts;
      mkStartCmd = service: "${pkgs.systemd}/bin/systemctl ${optsStr} start ${service}";
    in
    [
      (mkStartCmd serviceName)
      (mkStartCmd "${serviceName}.service")
    ];

  reset_git =
    { url
    , branch
    , git_options
    , indent ? 0
    }:
    let
      git = "${pkgs.git}/bin/git";
      mkOptionsStr = concatStringsSep " ";
      mkGitCommand = git_options: cmd: "${git} ${mkOptionsStr git_options} ${cmd}";
      mkGitCommandIndented = indent: git_options:
        compose [ (indentStr indent) (mkGitCommand git_options) ];
    in
    concatMapStringsSep "\n" (mkGitCommandIndented indent git_options) [
      ''remote set-url origin "${url}"''
      # The following line is only used to avoid the warning emitted by git.
      # We will reset the local repo anyway and remove all local changes.
      ''config pull.rebase true''
      ''fetch origin ${branch}''
      ''checkout ${branch} --''
      ''reset --hard origin/${branch}''
      ''clean -d --force''
      ''pull''
    ];

  clone_and_reset_git =
    { config
    , clone_dir
    , github_repo
    , branch
    , git_options ? [ ]
    , indent ? 0
    }:
    let
      repo_url = config.settings.system.org.repo_to_url github_repo;
    in
    optionalString (config != null) ''
      if [ ! -d "${clone_dir}" ] || [ ! -d "${clone_dir}/.git" ]; then
        if [ -d "${clone_dir}" ]; then
          # The directory exists but is not a git clone
          ${pkgs.coreutils}/bin/rm --recursive --force "${clone_dir}"
        fi
        ${pkgs.coreutils}/bin/mkdir --parent "${clone_dir}"
        ${pkgs.git}/bin/git clone "${repo_url}" "${clone_dir}"
      fi
      ${reset_git { inherit branch indent;
                    url = repo_url;
                    git_options = git_options ++ [ "-C" ''"${clone_dir}"'' ]; }}
    '';
in
{
  config.lib.ext_lib = {
    inherit compose applyTwice filterEnabled concatMapAttrsToList
      find_duplicates find_duplicate_mappings
      recursiveMerge
      stringNotEmpty ifPathExists traceImportJSON
      keyIfExists
      host_name_type empty_str_type pub_key_type
      indentStr mkSudoStartServiceCmds
      reset_git clone_and_reset_git;
  };
}

