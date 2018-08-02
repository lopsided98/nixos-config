{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  version = "4.17.0-rc6-1019";
  modDirVersion = "4.17.0-rc6";
  extraMeta.branch = "4.17";

  src = fetchFromGitHub {
    owner = "ayufan-rock64";
    repo = "linux-mainline-kernel";
    rev = "${version}-ayufan";
    sha256 = "0wsi621gfpb3vk35cfbiy2bd4kix6gdy9qn7qna6dvr06wn73yqb";
  };

} // (args.argsOverride or {}))
