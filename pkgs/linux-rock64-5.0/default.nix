{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  name = "linux-rock64";
  version = "5.0.0";
  modDirVersion = "5.0.0";
  extraMeta.branch = "5.0";

  src = fetchFromGitHub {
    owner = "lopsided98";
    repo = "linux";
    rev = "c92528bbcd2e96d9ecab0243e5e2692e4c6abaa0";
    sha256 = "099a7f6kj5q4wpsp6fjgn9d8k5bw56wpbl4gdsxv8msxkjwdbqrj";
  };

} // (args.argsOverride or {}))
