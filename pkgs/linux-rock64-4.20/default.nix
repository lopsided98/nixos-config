{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  name = "linux-rock64";
  version = "4.20.4";
  modDirVersion = "4.20.4";
  extraMeta.branch = "4.20";

  src = fetchFromGitHub {
    owner = "lopsided98";
    repo = "linux";
    rev = "17220bd8cbd9305f02802cfa93d4f315b4a84a81";
    sha256 = "1yz2k5a9cvsn13apy1z4mjzpih21d3w6b1jbsg5alfaazjwcmvh2";
  };

} // (args.argsOverride or {}))
