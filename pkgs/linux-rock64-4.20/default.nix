{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  name = "linux-rock64";
  version = "4.20.0";
  modDirVersion = "4.20.0";
  extraMeta.branch = "4.20";

  src = fetchFromGitHub {
    owner = "lopsided98";
    repo = "linux";
    rev = "2d8bb5e84110cdcd69d835b55c79eec2cf4a8261";
    sha256 = "11p5z0xyn8iz74whj1bg8y78n6z5k2n9l9hby2lgigiprag4wpm5";
  };

} // (args.argsOverride or {}))
