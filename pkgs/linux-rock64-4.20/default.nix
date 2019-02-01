{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  name = "linux-rock64";
  version = "4.20.6";
  modDirVersion = "4.20.6";
  extraMeta.branch = "4.20";

  src = fetchFromGitHub {
    owner = "lopsided98";
    repo = "linux";
    rev = "6ced941cdac284d3396c1c5d70c2b79b70fa9f3a";
    sha256 = "0hcbghkcadx3xjhcv8z54ppacdix82h1rqn448mvidjniwm250nl";
  };

} // (args.argsOverride or {}))
