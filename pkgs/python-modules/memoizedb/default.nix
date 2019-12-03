{ lib, fetchurl, buildPythonPackage }:

buildPythonPackage rec {
  pname = "memoizedb";
  version = "2017.3.30";

  src = fetchurl {
    url = "http://xyne.archlinux.ca/projects/python3-${pname}/src/python3-${pname}-${version}.tar.xz";
    sha256 = "1knkqghrkkajriv6zw5bf9iz37pzjc94h4a6f9q1chrwznfy9v26";
  };

  meta = with lib; {
    description = "Generic data retrieval memoizer that uses an sqlite database to cache data";
    homepage = "https://xyne.archlinux.ca/projects/python3-memoizedb/";
    license = licenses.gpl3;
    maintainers = with maintainers; [ lopsided98 ];
  };
}
