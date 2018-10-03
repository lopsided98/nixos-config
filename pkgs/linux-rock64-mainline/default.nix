{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  version = "4.18.0-rc8-1060";
  modDirVersion = "4.18.0-rc8";
  extraMeta.branch = "4.18";

  src = fetchFromGitHub {
    owner = "ayufan-rock64";
    repo = "linux-mainline-kernel";
    rev = "${version}-ayufan";
    sha256 = "1nmn1ffz7ynb7snc6wn8db9d8hxlmxbhgjfwv6f0w3hnd7xr3k4j";
  };

} // (args.argsOverride or {}))
