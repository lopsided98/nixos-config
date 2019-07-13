{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  name = "linux-rock64";
  version = "5.2.0";
  modDirVersion = "5.2.0";
  extraMeta.branch = "5.2";

  src = fetchFromGitHub {
    name = "${name}-${version}-source";
    owner = "lopsided98";
    repo = "linux";
    rev = "73a7e67aa34543bcb725f199e3a536a3018345d6";
    sha256 = "1vab3bmj8q5k60hinvc1pq2ph8kd904h68c0vs8kf2n3dnlhjm3g";
  };

} // (args.argsOverride or {}))
