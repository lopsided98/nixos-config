{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  name = "linux-rock64";
  version = "4.20.5";
  modDirVersion = "4.20.5";
  extraMeta.branch = "4.20";

  src = fetchFromGitHub {
    owner = "lopsided98";
    repo = "linux";
    rev = "05ff2fe76d4ebab6d27fe4a2ef7a8d1b52a9d795";
    sha256 = "0nqpw42jy7nj8v7k71gf27z1g3a0gql109s8ib1m56ancmg8si60";
  };

} // (args.argsOverride or {}))
