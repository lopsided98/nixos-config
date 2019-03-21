{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  name = "linux-rock64";
  version = "4.19.30";
  modDirVersion = "4.19.30";
  extraMeta.branch = "4.19";

  src = fetchFromGitHub {
    name = "${name}-${version}-source";
    owner = "lopsided98";
    repo = "linux";
    rev = "4bdd25bfa7d9b3c790d6c9b2c7796642c8a2fa03";
    sha256 = "1al37sz284rfxkjmwdbk4bq0x2h236djzzj9gvwl9lm8wx4dpki8";
  };

} // (args.argsOverride or {}))
