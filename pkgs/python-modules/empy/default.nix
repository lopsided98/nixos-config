{ lib, fetchurl, buildPythonPackage }:

buildPythonPackage rec {
  pname = "empy";
  version = "3.3.3";
  name = "${pname}-${version}";

  src = fetchurl {
    url = "http://www.alcyone.com/software/empy/empy-latest.tar.gz";
    sha256 = "1mxfy5mgp473ga1pgz2nvm8ds6z4g3hdky8523z6jzvcs9ny6hcq";
  };

  meta = {
    description = "A powerful and robust templating system for Python";
    homepage = http://www.alcyone.com/software/empy/;
  };
}
