{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  name = "linux-rock64";
  version = "4.19.16";
  modDirVersion = "4.19.16";
  extraMeta.branch = "4.19";

  src = fetchFromGitHub {
    owner = "lopsided98";
    repo = "linux";
    rev = "4b434fabb6ba5c5fc504fc1a052b13aa47dbf59b";
    sha256 = "0hjf7721hhcn3hlfbla10rhg63ib5svfni49mq9kfnraia8dcxi5";
  };

} // (args.argsOverride or {}))
