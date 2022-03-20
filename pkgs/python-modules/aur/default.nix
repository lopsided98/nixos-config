{ lib, fetchurl, buildPythonPackage, pyalpm, xcgf, xcpf, pyxdg }:

buildPythonPackage rec {
  pname = "aur";
  version = "2021.11.20.1";

  src = fetchurl {
    url = "https://xyne.dev/projects/python3-${pname}/src/python3-${pname}-${version}.tar.xz";
    sha256 = "sha256-V93/aKPvGcXt5PcfioD5ezO6DSaoyfX3wG8W+jgici4=";
  };

  propagatedBuildInputs = [ pyalpm xcgf xcpf pyxdg ];

  postInstall = ''
    mkdir -p "$out/bin"
    mv aur* "$out/bin"
  '';

  meta = with lib; {
    description = "AUR-related modules and helper utilities (aurploader, aurquery, aurtomatic)";
    homepage = "https://xyne.dev/projects/python3-aur/";
    license = licenses.gpl3;
    maintainers = with maintainers; [ lopsided98 ];
  };
}
