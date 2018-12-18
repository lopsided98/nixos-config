{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  name = "linux-rock64";
  version = "4.19.10";
  modDirVersion = "4.19.10";
  extraMeta.branch = "4.19";

  src = fetchFromGitHub {
    owner = "lopsided98";
    repo = "linux";
    rev = "1db18dc0188890ea3686eb41db30db46f8e7841c";
    sha256 = "08ywr68bal5r7yddkh6qnjv3cdndjc7cfb4hdzssrpcxvl9k0g8x";
  };

} // (args.argsOverride or {}))
