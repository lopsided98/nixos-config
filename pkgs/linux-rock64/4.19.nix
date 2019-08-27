{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  name = "linux-rock64";
  version = "4.19.68";
  modDirVersion = "4.19.68";
  extraMeta.branch = "4.19";

  src = fetchFromGitHub {
    name = "${name}-${version}-source";
    owner = "lopsided98";
    repo = "linux";
    rev = "71449826aac3c0d7abb1b9795459348f907854ff";
    sha256 = "1sd2g5l19l4zph68s81zjvbz8bb5j0qg043b7fag627rfs88iyxk";
  };

} // (args.argsOverride or {}))
