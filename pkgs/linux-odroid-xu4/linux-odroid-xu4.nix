{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  version = "4.14.35-131";
  modDirVersion = "4.14.35";
  extraMeta.branch = "4.14";

  src = fetchFromGitHub {
    owner = "hardkernel";
    repo = "linux";
    rev = version;
    sha256 = "1cifd6arpd9pl5wdnk5z9n1dya5dldlj3p33v44na8bkg8rrqx9r";
  };

} // (args.argsOverride or {}))
