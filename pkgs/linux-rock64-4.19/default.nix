{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  name = "linux-rock64";
  version = "4.19.18";
  modDirVersion = "4.19.18";
  extraMeta.branch = "4.19";

  src = fetchFromGitHub {
    owner = "lopsided98";
    repo = "linux";
    rev = "4a69548641eade5f3bdd887a4057ca3a72afaa9e";
    sha256 = "0fqmhhjw55fsyrrbnspd1ndq648x6q9x9yqjqv85lvy53iff9zjw";
  };

} // (args.argsOverride or {}))
