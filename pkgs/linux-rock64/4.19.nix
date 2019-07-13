{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  name = "linux-rock64";
  version = "4.19.58";
  modDirVersion = "4.19.58";
  extraMeta.branch = "4.19";

  src = fetchFromGitHub {
    name = "${name}-${version}-source";
    owner = "lopsided98";
    repo = "linux";
    rev = "d3a2befda8875a17d6910160c1bbd8ca9ce2776d";
    sha256 = "1j1xc9w17innv6dcnmzvyp2ydiw5hipwc2kk6a1j7xr00cwl43nh";
  };

} // (args.argsOverride or {}))
