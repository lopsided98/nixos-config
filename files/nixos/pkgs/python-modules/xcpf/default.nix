{ fetchurl, buildPythonPackage,
  pyalpm, memoizedb, pyxdg, xcgf }:

buildPythonPackage rec {
  pname = "xcpf";
  version = "2017.11.1";
  name = "${pname}-${version}";

  src = fetchurl {
    url = "http://xyne.archlinux.ca/projects/python3-xcpf/src/python3-xcpf-${version}.tar.xz";
    sha256 = "1qxh7mb8lv4xihwsk77fa8p2rlnr851c1fxsfd9ghcj56ywbgrib";
  };
  
  propagatedBuildInputs = [ pyalpm memoizedb pyxdg xcgf ];

  meta = {
    description = "Xyne's common Pacman functions, for internal use";
    homepage = http://xyne.archlinux.ca/projects/python3-xcpf;
  };
}
