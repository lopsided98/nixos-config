{ stdenv, buildPythonPackage, fetchPypi, grpcio }:

buildPythonPackage rec {
  name = "${pname}-${version}";
  pname = "grpcio-tools";
  version = "1.12.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "1f869xfazk58mslcxy0l04rl4b2s3bmps8labx8w5zh9xgsrpjw8";
  };

  buildInputs = [ grpcio ];
}
