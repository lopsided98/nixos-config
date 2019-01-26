{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  name = "linux-rock64";
  version = "4.19.17";
  modDirVersion = "4.19.17";
  extraMeta.branch = "4.19";

  src = fetchFromGitHub {
    owner = "lopsided98";
    repo = "linux";
    rev = "ee22a36f4988402e001f0b453e22debd03cbd547";
    sha256 = "145cbafrpgxakkascm8dkdr5yqbbk5n07wnhpczf512dy5qvwvwr";
  };

} // (args.argsOverride or {}))
