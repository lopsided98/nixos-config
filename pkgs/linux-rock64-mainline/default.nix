{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  name = "linux-rock64";
  version = "4.19.9";
  modDirVersion = "4.19.9";
  extraMeta.branch = "4.19";

  src = fetchFromGitHub {
    owner = "lopsided98";
    repo = "linux";
    rev = "a8ebc01c889406a65f4cbcd0eb5e5fa12205cade";
    sha256 = "0zykwzgkn60487yh9g1dgrphkmji012x0vnxix3p5n0rwwjl87nv";
  };

} // (args.argsOverride or {}))
