{ lib, fetchFromGitHub, buildLinux, ... } @ args:

with lib;

buildLinux (args // rec {
  name = "linux-rock64";
  version = "5.3";

  # modDirVersion needs to be x.y.z, will automatically add .0 if needed
  modDirVersion = concatStrings (intersperse "." (take 3 (splitString "." "${version}.0")));

  # branchVersion needs to be x.y
  extraMeta.branch = concatStrings (intersperse "." (take 2 (splitString "." version)));

  src = fetchFromGitHub {
    name = "${name}-${version}-source";
    owner = "lopsided98";
    repo = "linux";
    rev = "a8ee91a7b2d1b392c153c3fbb138321633402102";
    sha256 = "07fyh0iyr3g7swd8j5p1znna097329hi8fgvzgj5pdfn0dlly2zf";
  };

} // (args.argsOverride or {}))
