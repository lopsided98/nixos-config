{ lib, buildPythonPackage, fetchPypi, future, lxml }:

buildPythonPackage rec {
  pname = "pymavlink";
  version = "2.4.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "12ivzpw9ggird3aag67j1dyz7pply7ypbcwkffgs68mqf8f2i818";
  };

  propagatedBuildInputs = [ future lxml ];

  # Tests are broken
  doCheck = false;

  meta = with lib; {
    description = "Python MAVLink interface and utilities";
    homepage = "https://github.com/ArduPilot/pymavlink";
    license = licenses.lgpl3;
    maintainers = with maintainers; [ lopsided98 ];
  };
}
