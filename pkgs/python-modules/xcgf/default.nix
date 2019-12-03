{ lib, fetchurl, buildPythonPackage }:

buildPythonPackage rec {
  pname = "xcgf";
  version = "2017.3";

  src = fetchurl {
    url = "http://xyne.archlinux.ca/projects/python3-${pname}/src/python3-${pname}-${version}.tar.xz";
    sha256 = "1kr7971fgiwl52840c0x9ap4hgd20w2c13gp2bbsbambqijbykmm";
  };

  meta = with lib; {
    description = "Xyne's common generic functions, for internal use";
    homepage = "https://xyne.archlinux.ca/projects/python3-xcgf/";
    license = licenses.gpl3;
    maintainers = with maintainers; [ lopsided98 ];
  };
}
