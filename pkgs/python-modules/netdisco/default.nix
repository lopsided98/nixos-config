{ stdenv, buildPythonPackage, fetchPypi,
  requests, zeroconf }:

buildPythonPackage rec {
  name = "${pname}-${version}";
  pname = "netdisco";
  version = "1.5.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "0p51af2diwffia5rkvf56gxp3vxr2l4scmwq6ih5ilprjnd8p39h";
  };

  propagatedBuildInputs = [ requests zeroconf ];
}
