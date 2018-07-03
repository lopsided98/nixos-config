{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  version = "4.18.0-rc3-1033";
  modDirVersion = "4.18.0-rc3";
  extraMeta.branch = "4.18";

  src = fetchFromGitHub {
    owner = "ayufan-rock64";
    repo = "linux-mainline-kernel";
    rev = "${version}-ayufan";
    sha256 = "15b2mjkmg5n6nlsd5a8yd6dky6ni67hbmp18lcqx6xa6azhhks7b";
  };

} // (args.argsOverride or {}))
