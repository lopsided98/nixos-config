{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  name = "linux-rock64";
  version = "4.19.18";
  modDirVersion = "4.19.18";
  extraMeta.branch = "4.19";

  src = fetchFromGitHub {
    owner = "lopsided98";
    repo = "linux";
    rev = "3b3e4bfd7744895ad3a17d321a1950bcdb005208";
    sha256 = "0z1jkbkmchjs2b9cz6jvlr2pzs10mqzv4ls81vznzzsbj0ydb88y";
  };

} // (args.argsOverride or {}))
