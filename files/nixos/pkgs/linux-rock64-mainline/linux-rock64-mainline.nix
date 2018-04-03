{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  version = "4.16-rc6-0.6.28";
  modDirVersion = "4.16.0-rc6";
  extraMeta.branch = "4.16";

  src = fetchFromGitHub {
    owner = "ayufan-rock64";
    repo = "linux-mainline-kernel";
    rev = "027e722bb005d95adae3957306f7b6755c2b203d";
    sha256 = "0njbj2i9d17jiw0m406v337mzhkv9l7cnlq44ac232axhjprn9zs";
  };

} // (args.argsOverride or {}))
