{ lib, fetchFromGitHub, buildLinux, ... } @ args:

with lib;

buildLinux (args // rec {
  name = "linux-rock64";
  version = "5.6.7";

  # modDirVersion needs to be x.y.z, will automatically add .0 if needed
  modDirVersion = concatStrings (intersperse "." (take 3 (splitString "." "${version}.0")));

  # branchVersion needs to be x.y
  extraMeta.branch = concatStrings (intersperse "." (take 2 (splitString "." version)));

  src = fetchFromGitHub {
    name = "${name}-${version}-source";
    owner = "lopsided98";
    repo = "linux";
    rev = "1648df603886e518565e36bf18f083a4eac99b28";
    sha256 = "1x9ajyns9k9686w1jhn4dff8cfxf5kbxhdxwsqnxb60aw3596myl";
  };
} // (args.argsOverride or {}))
