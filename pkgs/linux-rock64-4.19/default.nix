{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  name = "linux-rock64";
  version = "4.19.35";
  modDirVersion = "4.19.35";
  extraMeta.branch = "4.19";

  src = fetchFromGitHub {
    name = "${name}-${version}-source";
    owner = "lopsided98";
    repo = "linux";
    rev = "27c5bb0c9d1796b40c8bdd08bbb9eeb939fea856";
    sha256 = "1lbdrla6isa85n1cqmc8wrsaw13iwg8crn3x0n6y1df011zjrwmr";
  };

} // (args.argsOverride or {}))
