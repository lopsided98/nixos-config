{ lib, fetchFromGitHub, buildLinux, ... } @ args:

with lib;

buildLinux (args // rec {
  name = "linux-rock64";
  version = "5.7.7";

  # modDirVersion needs to be x.y.z, will automatically add .0 if needed
  modDirVersion = concatStrings (intersperse "." (take 3 (splitString "." "${version}.0")));

  # branchVersion needs to be x.y
  extraMeta.branch = concatStrings (intersperse "." (take 2 (splitString "." version)));

  src = fetchFromGitHub {
    name = "${name}-${version}-source";
    owner = "lopsided98";
    repo = "linux";
    rev = "ffa133b374b199c17a29da6a08a41ffceb43be43";
    sha256 = "0cd1qm1qwjzwhbg4z2qkgz5hs363qhswm1a0wqzka3im39a9dn82";
  };
} // (args.argsOverride or {}))
