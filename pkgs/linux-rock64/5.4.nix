{ lib, fetchFromGitHub, buildLinux, ... } @ args:

with lib;

buildLinux (args // rec {
  name = "linux-rock64";
  version = "5.4.0";

  # modDirVersion needs to be x.y.z, will automatically add .0 if needed
  modDirVersion = concatStrings (intersperse "." (take 3 (splitString "." "${version}.0")));

  # branchVersion needs to be x.y
  extraMeta.branch = concatStrings (intersperse "." (take 2 (splitString "." version)));

  src = fetchFromGitHub {
    name = "${name}-${version}-source";
    owner = "lopsided98";
    repo = "linux";
    rev = "259c605f68587b29209f661b7a564708be0a05ba";
    sha256 = "1ppizhs76qydrdx0p39gp19xwz6v2dkw0053vimic4l70zma7dcx";
  };
  
  extraConfig = ''
    CRYPTO_AEGIS128_SIMD n
  '' + (args.extraConfig or "");

} // (args.argsOverride or {}))
