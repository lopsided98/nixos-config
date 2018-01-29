{ fetchurl, buildPythonPackage }:

buildPythonPackage rec {
  pname = "xcgf";
  version = "2017.3";
  name = "${pname}-${version}";

  src = fetchurl {
    url = "http://xyne.archlinux.ca/projects/python3-xcgf/src/python3-xcgf-${version}.tar.xz";
    sha256 = "1kr7971fgiwl52840c0x9ap4hgd20w2c13gp2bbsbambqijbykmm";
  };

  meta = {
    description = "Xyne's common generic functions, for internal use";
    homepage = http://xyne.archlinux.ca/projects/python3-xcgf;
  };
}
