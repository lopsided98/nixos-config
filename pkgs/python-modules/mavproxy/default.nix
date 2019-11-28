{ lib, buildPythonPackage, fetchFromGitHub, matplotlib, numpy, pymavlink
, pyserial, setuptools, wxPython_4_0 }:

buildPythonPackage rec {
  pname = "MAVProxy";
  version = "1.8.16";

  src = fetchFromGitHub {
    owner = "ArduPilot";
    repo = pname;
    rev = "f715f9612999732854e4eefc30980470438bd579";
    sha256 = "1y1x0qs3vn3knlnyqrgbznq5ikhk4j1idr9il65k7myjimvz4g2k";
  };

  propagatedBuildInputs = [
    matplotlib numpy pymavlink pyserial setuptools wxPython_4_0
  ];

  doCheck = false;

  meta = with lib; {
    description = "MAVLink proxy and command line ground station ";
    homepage = "https://github.com/ArduPilot/MAVProxy";
    license = licenses.gpl3;
    maintainers = with maintainers; [ lopsided98 ];
  };
}
