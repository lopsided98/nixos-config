{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  version = "4.14.55-146";
  modDirVersion = "4.14.55";
  extraMeta.branch = "4.14";

  src = fetchFromGitHub {
    owner = "hardkernel";
    repo = "linux";
    rev = version;
    sha256 = "1bm1njng4rwfylgnqv06vabkvybm9rikqj1lsb7p9qcs3y1kw6mh";
  };

  defconfig = "odroidxu4_defconfig";

  structuredExtraConfig.GATOR = "n";

} // (args.argsOverride or {}))
