{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  name = "linux-rock64";
  version = "4.19.23";
  modDirVersion = "4.19.23";
  extraMeta.branch = "4.19";

  src = fetchFromGitHub {
    owner = "lopsided98";
    repo = "linux";
    rev = "3ff99bc1c59d783ae2c1bda27f7d7bda2c4bb6e6";
    sha256 = "1shpv6ns8dzaqgb2v8f7jawfc4wvh84h5rchq8393l03bkik7ryc";
  };

} // (args.argsOverride or {}))
