{ fetchurl, buildPythonPackage,
  pyalpm, memoizedb, pyxdg, xcgf }:

buildPythonPackage rec {
  pname = "xcpf";
  version = "2017.12";
  name = "${pname}-${version}";

  src = fetchurl {
    url = "http://xyne.archlinux.ca/projects/python3-xcpf/src/python3-xcpf-${version}.tar.xz";
    sha256 = "1m8kw8r3kvyxqd2vyccbgk04n8nrxk2a62zlybrgjfcpxxfihw13";
  };
  
  propagatedBuildInputs = [ pyalpm memoizedb pyxdg xcgf ];

  meta = {
    description = "Xyne's common Pacman functions, for internal use";
    homepage = http://xyne.archlinux.ca/projects/python3-xcpf;
  };
}
