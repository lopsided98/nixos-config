{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  version = "4.14.32-126";
  modDirVersion = "4.14.32";
  extraMeta.branch = "4.14";

  src = fetchFromGitHub {
    owner = "hardkernel";
    repo = "linux";
    rev = version;
    sha256 = "1csc7s2agb015b9hr8q7z3384r80jmhf0692m492fxx44nd0fmxh";
  };

} // (args.argsOverride or {}))
