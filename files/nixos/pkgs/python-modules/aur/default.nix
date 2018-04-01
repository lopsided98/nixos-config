{ fetchurl, buildPythonPackage,
  pyalpm, xcgf, xcpf, pyxdg }:

buildPythonPackage rec {
  pname = "aur";
  version = "2018";
  name = "${pname}-${version}";

  src = fetchurl {
    url = "http://xyne.archlinux.ca/projects/python3-${pname}/src/python3-${pname}-${version}.tar.xz";
    sha256 = "1v1xfvb6q78nk8bgzj958q90q6y9qk9b9d9sy0l1hmks2dcycwmw";
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
