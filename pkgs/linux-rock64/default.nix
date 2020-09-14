{ lib, fetchFromGitHub, buildLinux, ... } @ args:

with lib;

buildLinux (args // rec {
  name = "linux-rock64";
  version = "5.8.3";

  # modDirVersion needs to be x.y.z, will automatically add .0 if needed
  modDirVersion = concatStrings (intersperse "." (take 3 (splitString "." "${version}.0")));

  # branchVersion needs to be x.y
  extraMeta.branch = concatStrings (intersperse "." (take 2 (splitString "." version)));

  src = fetchFromGitHub {
    name = "${name}-${version}-source";
    owner = "lopsided98";
    repo = "linux";
    rev = "6c7797239daf882b286a5fe92cad2b196fa7b0be";
    sha256 = "1bpyyda5drmdrkyj7qv3205qn1fyzr61j2wqc9m36kx8hy7s7a6v";
  };
} // (args.argsOverride or {}))
