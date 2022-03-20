{ lib, fetchurl, buildPythonPackage, pyalpm, memoizedb, pyxdg, xcgf }:

buildPythonPackage rec {
  pname = "xcpf";
  version = "2021.12";

  src = fetchurl {
    url = "https://xyne.dev/projects/python3-${pname}/src/python3-${pname}-${version}.tar.xz";
    sha256 = "sha256-u4dTnYr4v5cO3M+Cj8CAzyRhq7VAYlCSTk8sFgrUDE0=";
  };

  propagatedBuildInputs = [ pyalpm memoizedb pyxdg xcgf ];

  meta = with lib; {
    description = "Xyne's common Pacman functions, for internal use";
    homepage = "https://xyne.dev/projects/python3-xcpf/";
    license = licenses.gpl3;
    maintainers = with maintainers; [ lopsided98 ];
  };
}
