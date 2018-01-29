{ fetchurl, buildPythonPackage,
  pyalpm, xcgf, xcpf, pyxdg }:

buildPythonPackage rec {
  pname = "aur";
  version = "2017.7";
  name = "${pname}-${version}";

  src = fetchurl {
    url = "http://xyne.archlinux.ca/projects/python3-${pname}/src/python3-${pname}-${version}.tar.xz";
    sha256 = "0dhjzgzsc3qpj3wrd1hh0dg7hfca7gx484h19a1v4b2kgf14hs37";
  };
  
  propagatedBuildInputs = [ pyalpm xcgf xcpf pyxdg ];
  
  postInstall = ''
    mkdir -p "$out/bin"
    cp aur* "$out/bin"
  '';

  meta = {
    description = "AUR-related modules and helper utilities (aurploader, aurquery, aurtomatic)";
    homepage = http://xyne.archlinux.ca/projects/python3-aur;
  };
}
