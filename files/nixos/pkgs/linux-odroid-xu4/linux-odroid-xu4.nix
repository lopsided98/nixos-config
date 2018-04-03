{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  version = "4.14.29-125";
  modDirVersion = "4.14.29";
  extraMeta.branch = "4.14";

  src = fetchFromGitHub {
    owner = "hardkernel";
    repo = "linux";
    rev = version;
    sha256 = "0k3b605p7x0fnlc13gzfp13kd5yf8z4zqbrrwfmsgccl943s6nyf";
  };

} // (args.argsOverride or {}))
