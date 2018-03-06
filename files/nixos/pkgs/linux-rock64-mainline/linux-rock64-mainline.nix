{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  version = "4.15-rc5-0.6.23";
  modDirVersion = "4.15.0-rc5";
  extraMeta.branch = "4.15";

  src = fetchFromGitHub {
    owner = "ayufan-rock64";
    repo = "linux-mainline-kernel";
    rev = "29128dea21f623cac3386fdfe97a11ed69dacbd4";
    sha256 = "02c5fhzjs6237frynwpd29xc629dawdfpm25dvmgm0safnx424s1";
  };

} // (args.argsOverride or {}))
