{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  name = "linux-rock64";
  version = "5.1.4";
  modDirVersion = "5.1.4";
  extraMeta.branch = "5.1";

  src = fetchFromGitHub {
    name = "${name}-${version}-source";
    owner = "lopsided98";
    repo = "linux";
    rev = "5755d66c263ddf9fa101879c9629d164d479fe67";
    sha256 = "181skndrqj73rzz0d73fda3cgjx75ilmi8j5n2sbkjd5si5sx8b4";
  };

} // (args.argsOverride or {}))
