{ lib, fetchFromGitHub, buildLinux, ... } @ args:

with lib;

buildLinux (args // rec {
  name = "linux-rock64";
  version = "4.19.77";

  # modDirVersion needs to be x.y.z, will automatically add .0 if needed
  modDirVersion = concatStrings (intersperse "." (take 3 (splitString "." "${version}.0")));

  # branchVersion needs to be x.y
  extraMeta.branch = concatStrings (intersperse "." (take 2 (splitString "." version)));

  src = fetchFromGitHub {
    name = "${name}-${version}-source";
    owner = "lopsided98";
    repo = "linux";
    rev = "42050e4dab9c5a688c9d4b867da1f0ed6b66dc86";
    sha256 = "033vlyyihdgm39hdalw2hibmbgw08r4c5rdgszrbwi15kwfb5s98";
  };

} // (args.argsOverride or {}))
