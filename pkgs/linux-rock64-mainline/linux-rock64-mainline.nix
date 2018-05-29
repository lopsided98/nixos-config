{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  version = "4.17-rc3-0.6.36";
  modDirVersion = "4.17.0-rc3";
  extraMeta.branch = "4.17";

  src = fetchFromGitHub {
    owner = "ayufan-rock64";
    repo = "linux-mainline-kernel";
    rev = "d02e62360554b19074d69b4f91dde23699b2f5b9";
    sha256 = "1sm2fi2qirw37qxag4lpjyz5rvdqmgspmkmpgy6phwcwla1im7ak";
  };

} // (args.argsOverride or {}))
