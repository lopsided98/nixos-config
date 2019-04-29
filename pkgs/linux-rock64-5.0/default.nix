{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  name = "linux-rock64";
  version = "5.0.8";
  modDirVersion = "5.0.8";
  extraMeta.branch = "5.0";

  src = fetchFromGitHub {
    name = "${name}-${version}-source";
    owner = "lopsided98";
    repo = "linux";
    rev = "ff2a51578a6d56b13a7be1aa53cc580b6eea4d03";
    sha256 = "13rzkyaw9kbx2z6qwkjnfjm46hf7x2na5s08v7lp7b48am0w9a8q";
  };

} // (args.argsOverride or {}))
