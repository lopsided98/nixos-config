{ lib, fetchurl, buildPythonPackage, pyalpm, xcgf, xcpf, pyxdg }:

buildPythonPackage rec {
  pname = "aur";
  version = "2018.8";

  src = fetchurl {
    url = "http://xyne.archlinux.ca/projects/python3-${pname}/src/python3-${pname}-${version}.tar.xz";
    sha256 = "09if4a32dzg0j3haqxis6c90sknng9s2zs90mmp3z9dk0h9h3vni";
  };

  propagatedBuildInputs = [ pyalpm xcgf xcpf pyxdg ];

  postInstall = ''
    mkdir -p "$out/bin"
    cp aur* "$out/bin"
  '';

  meta = with lib; {
    description = "AUR-related modules and helper utilities (aurploader, aurquery, aurtomatic)";
    homepage = http://xyne.archlinux.ca/projects/python3-aur;
    license = licenses.gpl3;
    maintainers = with maintainers; [ lopsided98 ];
  };
}
