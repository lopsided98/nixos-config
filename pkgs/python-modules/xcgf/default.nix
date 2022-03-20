{ lib, fetchurl, buildPythonPackage }:

buildPythonPackage rec {
  pname = "xcgf";
  version = "2021";

  src = fetchurl {
    url = "https://xyne.dev/projects/python3-${pname}/src/python3-${pname}-${version}.tar.xz";
    sha256 = "sha256-1YkMitu1f4Nee2wOcFNZzeyF/MCTFSzFCP/trL/YaOA=";
  };

  meta = with lib; {
    description = "Xyne's common generic functions, for internal use";
    homepage = "https://xyne.dev/projects/python3-xcgf/";
    license = licenses.gpl3;
    maintainers = with maintainers; [ lopsided98 ];
  };
}
