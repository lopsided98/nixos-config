{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  version = "4.14.66-147";
  modDirVersion = "4.14.66";
  extraMeta.branch = "4.14";

  src = fetchFromGitHub {
    owner = "hardkernel";
    repo = "linux";
    rev = version;
    sha256 = "06v38jl4i7l8gl8zcpyp9vmjjhaqhbp7by15f82rxa724zppxi9x";
  };

  defconfig = "odroidxu4_defconfig";

  structuredExtraConfig.GATOR = "n";

} // (args.argsOverride or {}))
