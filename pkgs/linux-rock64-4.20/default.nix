{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  name = "linux-rock64";
  version = "4.20.3";
  modDirVersion = "4.20.3";
  extraMeta.branch = "4.20";

  src = fetchFromGitHub {
    owner = "lopsided98";
    repo = "linux";
    rev = "164474d8571657ee7c744fbefab8fd4e48a1f073";
    sha256 = "0n0bzjhskqgl195jn8605zcskczq462aw7l3grx1y5yp3f6az5in";
  };

} // (args.argsOverride or {}))
