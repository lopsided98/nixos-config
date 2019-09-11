{ lib, fetchurl, buildPythonPackage, pyalpm, memoizedb, pyxdg, xcgf }:

buildPythonPackage rec {
  pname = "xcpf";
  version = "2019";

  src = fetchurl {
    url = "http://xyne.archlinux.ca/projects/python3-xcpf/src/python3-${pname}-${version}.tar.xz";
    sha256 = "0lbf5gw6cx6cp4i7n2cjwyjf82pclbrxkyqc5n7ascmaajqdvn8k";
  };

  propagatedBuildInputs = [ pyalpm memoizedb pyxdg xcgf ];

  meta = with lib; {
    description = "Xyne's common Pacman functions, for internal use";
    homepage = "http://xyne.archlinux.ca/projects/python3-xcpf";
    license = licenses.gpl3;
    maintainers = with maintainers; [ lopsided98 ];
  };
}
