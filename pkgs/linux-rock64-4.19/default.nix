{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  name = "linux-rock64";
  version = "4.19.13";
  modDirVersion = "4.19.13";
  extraMeta.branch = "4.19";

  src = fetchFromGitHub {
    owner = "lopsided98";
    repo = "linux";
    rev = "6549913774e677d01dbd19a82440ef2428a41708";
    sha256 = "0bggxrmyq2h6h2y8wvyqaqsnyc8vvavgjqqk0iw4ch623k8qcfbz";
  };

} // (args.argsOverride or {}))
