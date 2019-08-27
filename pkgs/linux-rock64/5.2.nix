{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  name = "linux-rock64";
  version = "5.2.10";
  modDirVersion = "5.2.10";
  extraMeta.branch = "5.2";

  src = fetchFromGitHub {
    name = "${name}-${version}-source";
    owner = "lopsided98";
    repo = "linux";
    rev = "454c8254f74e4c1f01755e2b957fc1b08a0fb027";
    sha256 = "1z427hyr11spd2nhzblnz0kii0vpdg4np15pncyc61qmxisy107j";
  };

} // (args.argsOverride or {}))
