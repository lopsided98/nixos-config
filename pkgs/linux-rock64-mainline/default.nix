{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  name = "linux-rock64";
  version = "4.19.4";
  modDirVersion = "4.19.4";
  extraMeta.branch = "4.19";

  src = fetchFromGitHub {
    owner = "lopsided98";
    repo = "linux";
    rev = "a0de9629ebc4ddebb325ec9db5d352dad04f458a";
    sha256 = "1bj9y1rp5pcv5bfr0zsfzhzv7a13jg63v8gxsq3mwx2v6yrbmbbf";
  };

} // (args.argsOverride or {}))
