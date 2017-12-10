{ lib, stdenv, fetchurl }:

stdenv.mkDerivation rec {
  name = "tinyssh-20161101";

  src = fetchurl {
    url = "https://mojzis.com/software/tinyssh/${name}.tar.gz";
    sha256 = "0kmjgkvzp2jm15lkw66kqrv0ziqy97k36ll58jfijmx064kga3jg";
  };
  
  patches = [ ./0001-Skip-channeltest.patch ];
  
  installPhase = ''
    make install DESTDIR="$out"
    mv "''${out}/usr/sbin" "$out/bin"
  '';

  meta = with lib; {
    description = "A minimalistic SSH server";
    homepage = https://tinyssh.org/;
    license = licenses.cc0;
  };
}
