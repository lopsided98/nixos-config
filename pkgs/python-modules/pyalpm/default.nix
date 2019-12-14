{ lib, fetchPypi, fetchpatch, buildPythonPackage,
  pacman, libarchive, nose }:

buildPythonPackage rec {
  pname = "pyalpm";
  version = "0.9.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "0l4dhayl0j8vqxczccbizh3jgyhkwrazd6j210lf3ksjb1x3wqyp";
  };

  patches = [
    # Revert memleak patch which causes 'random' segfauts since the handle is
    # still used while it's already cleaned up.
    (fetchpatch {
      url = "https://git.archlinux.org/pyalpm.git/patch/?id=c02555c5d83e63b1a308e7c165d5615198e6d813";
      sha256 = "1i4n26vzkinlc09yfn2vknxnii1kjjw98pmj7apb55pmc59qsjsq";
      revert = true;
    })
  ];

  buildInputs = [ pacman libarchive nose ];

  # Tests only run on Arch Linux
  doCheck = false;

  meta = with lib; {
    description = "Libalpm bindings for Python 3";
    homepage = "https://git.archlinux.org/pyalpm.git";
    license = licenses.gpl3;
    maintainers = with maintainers; [ lopsided98 ];
  };
}
