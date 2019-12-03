{ lib, fetchurl, buildPythonPackage, pyalpm, memoizedb, pyxdg, xcgf }:

buildPythonPackage rec {
  pname = "xcpf";
  version = "2019.11";

  src = fetchurl {
    url = "http://xyne.archlinux.ca/projects/python3-xcpf/src/python3-${pname}-${version}.tar.xz";
    sha256 = "1kgl31ljrhn6h4ah8wzmylblx2im02jjrih3nlga20gg4n6hm164";
  };

  propagatedBuildInputs = [ pyalpm memoizedb pyxdg xcgf ];

  meta = with lib; {
    description = "Xyne's common Pacman functions, for internal use";
    homepage = "http://xyne.archlinux.ca/projects/python3-xcpf";
    license = licenses.gpl3;
    maintainers = with maintainers; [ lopsided98 ];
  };
}
