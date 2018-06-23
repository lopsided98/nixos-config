{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  version = "4.4.120-0.6.29";
  modDirVersion = "4.4.120";
  extraMeta.branch = "4.4";

  src = fetchFromGitHub {
    owner = "ayufan-rock64";
    repo = "linux-kernel";
    rev = "76cd7d926b623214ba6e8e25e9f3ceb30b84d2ad";
    sha256 = "181x99g02a4nh56p5xdyx5jr4q6ffwfzx26d08j931jaw6fawyqk";
  };

} // (args.argsOverride or {}))
