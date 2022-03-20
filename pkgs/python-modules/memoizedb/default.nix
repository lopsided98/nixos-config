{ lib, fetchurl, buildPythonPackage }:

buildPythonPackage rec {
  pname = "memoizedb";
  version = "2021";

  src = fetchurl {
    url = "https://xyne.dev/projects/python3-${pname}/src/python3-${pname}-${version}.tar.xz";
    sha256 = "sha256-Ttw7bGWBLCvqcM645KEbkRUZo3bDPHiEF3+NzXcVB0Q=";
  };

  meta = with lib; {
    description = "Generic data retrieval memoizer that uses an sqlite database to cache data";
    homepage = "https://xyne.dev/projects/python3-memoizedb/";
    license = licenses.gpl3;
    maintainers = with maintainers; [ lopsided98 ];
  };
}
