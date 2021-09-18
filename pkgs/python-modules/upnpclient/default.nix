{ stdenv, buildPythonPackage, fetchPypi,
  requests, six, netdisco, dateutil, lxml, pytest, pytestrunner }:

buildPythonPackage rec {
  pname = "upnpclient";
  version = "1.0.3";

  src = fetchPypi {
    inherit pname version;
    sha256 = "1f39kqj26h5dxxqqcdsidv978iswzr4sn7anqif5np4f9gx0a7v4";
  };

  buildInputs = [ pytest pytestrunner ];
  propagatedBuildInputs = [ requests six netdisco dateutil lxml ];
}
