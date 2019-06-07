{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  name = "linux-rock64";
  version = "4.19.48";
  modDirVersion = "4.19.48";
  extraMeta.branch = "4.19";

  src = fetchFromGitHub {
    name = "${name}-${version}-source";
    owner = "lopsided98";
    repo = "linux";
    rev = "8c6a7d526f8e2725666c2f79e950abbca077400d";
    sha256 = "15m22pyxqq756y6kbqraspnj1mwwa59zl0xih86kndqwy4hzd3sq";
  };

} // (args.argsOverride or {}))
