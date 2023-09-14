{ lib, fetchPypi, buildPythonPackage, pkgconfig, pkg-config, pacman, libarchive
, nose }:

buildPythonPackage rec {
  pname = "pyalpm";
  version = "0.10.6";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-mebsc7jEa7EkZgE/Io+DHuDRjoq2ZLkaAcKjxA3gfH8=";
  };

  nativeBuildInputs = [ pkgconfig pkg-config ];
  buildInputs = [ pacman libarchive ];
  checkInputs = [ nose ];

  # Tests only run on Arch Linux
  doCheck = false;

  meta = with lib; {
    description = "Python 3 bindings for libalpm";
    homepage = "https://gitlab.archlinux.org/archlinux/pyalpm";
    license = licenses.gpl3;
    maintainers = with maintainers; [ lopsided98 ];
  };
}
