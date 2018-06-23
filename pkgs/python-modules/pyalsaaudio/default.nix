{ stdenv, buildPythonPackage, fetchPypi, alsaLib }:

buildPythonPackage rec {
  name = "${pname}-${version}";
  pname = "pyalsaaudio";
  version = "0.8.4";

  src = fetchPypi {
    inherit pname version;
    sha256 = "1180ypn9596rq4b7y7dyv627j1q0fqilmkkrckclnzsdakdgis44";
  };

  buildInputs = [ alsaLib ];

  # Requires access to sound devices
  doCheck = false;
}
