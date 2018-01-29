{ lib, fetchgit, buildPythonPackage,
  pacman, libarchive, nose }:

buildPythonPackage rec {
  pname = "pyalpm";
  version = "0.8.2";
  name = "${pname}-${version}";

  src = fetchgit {
    url = "https://git.archlinux.org/pyalpm.git";
    rev = "6f0787ef74fc342c3eb0a9b24ab7aea0087bb27a";
    sha256 = "078m79zzmgm3a49jrx6pdl5g53f6gcchwf49x6jb97hjhh8ysmhb";
  };
  
  buildInputs = [ pacman libarchive nose ];

  # Tests only run on Arch Linux
  doCheck = false;

  meta = {
    description = "Libalpm bindings for Python 3";
    homepage = https://git.archlinux.org/pyalpm.git/;
  };
}
