{ stdenv, buildPythonPackage, fetchPypi,
  requests, six, netdisco, dateutil, lxml, pytest, pytestrunner }:

buildPythonPackage rec {
  name = "${pname}-${version}";
  pname = "upnpclient";
  version = "0.0.8";

  src = fetchPypi {
    pname = "uPnPClient";
    inherit version;
    sha256 = "1dh7ym9s0yhh9gc5hdlj9g9y3q4l3h56y4z312p4s4wcz815rzk7";
  };

  buildInputs = [ pytest pytestrunner ];
  propagatedBuildInputs = [ requests six netdisco dateutil lxml ];
}
