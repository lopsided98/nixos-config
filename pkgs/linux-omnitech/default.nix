{ lib, fetchFromGitHub, buildLinux, ... } @ args:

with lib;

buildLinux (args // rec {
  name = "linux-omnitech";
  version = "5.8.1";

  # modDirVersion needs to be x.y.z, will automatically add .0 if needed
  modDirVersion = concatStrings (intersperse "." (take 3 (splitString "." "${version}.0")));

  # branchVersion needs to be x.y
  extraMeta.branch = concatStrings (intersperse "." (take 2 (splitString "." version)));

  src = fetchFromGitHub {
    name = "${name}-${version}-source";
    owner = "lopsided98";
    repo = "linux";
    rev = "240dd1417e114c041e92adc126d90fbb73bc28b4";
    sha256 = "1gj6if3535ndfdaa44l3jyc9r5yxymmbxcsj3h73x0220jlg6qfn";
  };
} // (args.argsOverride or {}))
