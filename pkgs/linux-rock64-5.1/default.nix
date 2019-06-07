{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  name = "linux-rock64";
  version = "5.1.7";
  modDirVersion = "5.1.7";
  extraMeta.branch = "5.1";

  src = fetchFromGitHub {
    name = "${name}-${version}-source";
    owner = "lopsided98";
    repo = "linux";
    rev = "176978220191732e7ecf51eb2b97e85f960f00f0";
    sha256 = "1vl6y9zdjwx39qyiiym9yziawps053f4mmhzfrl02b7s8wv6z915";
  };

} // (args.argsOverride or {}))
