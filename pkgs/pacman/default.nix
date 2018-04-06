{ lib, stdenv, fetchurl, 
  pkgconfig, m4, perl, libarchive, xz, zlib, bzip2, openssl,
  curlSupport ? true, curl ? null }:
  
assert curlSupport -> curl != null;

stdenv.mkDerivation rec {
  name = "pacman-5.0.2";

  src = fetchurl {
    url = "https://sources.archlinux.org/other/pacman/${name}.tar.gz";
    sha256 = "03hzqklrn97i9fn96l59sjn2ilqxwnpiyjkzjz6lnmk8mn361lyz";
  };
  
  nativeBuildInputs = [ pkgconfig m4 ];
  buildInputs = [ perl libarchive xz zlib bzip2 curl openssl ];
  
  postFixup = ''
    substituteInPlace $out/bin/repo-add \
      --replace bsdtar "${libarchive}/bin/bsdtar" \
      --replace openssl "${openssl}/bin/openssl" \
  '';

  meta = with lib; {
    description = "A simple library-based package manager";
    homepage = https://www.archlinux.org/pacman/;
    license = licenses.gpl2;
  };
}
