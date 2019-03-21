{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  name = "linux-rock64";
  version = "5.0.3";
  modDirVersion = "5.0.3";
  extraMeta.branch = "5.0";

  src = fetchFromGitHub {
    name = "${name}-${version}-source";
    owner = "lopsided98";
    repo = "linux";
    rev = "4c7908811bddeee39e98c5bc7fe1a2741a68d285";
    sha256 = "036cj42qxj9dpq85cs7gai4jfj04hxpsazpr94k9b453gnbm04mr";
  };

} // (args.argsOverride or {}))
