{ lib, stdenv, fetchurl }:

stdenv.mkDerivation rec {
  name = "tinyssh-20180201";

  src = fetchurl {
    url = "https://mojzis.com/software/tinyssh/${name}.tar.gz";
    sha256 = "00lrb4ra7j731cxk69jcf5sf9gvad037v9jgigj4hh31w46asbsc";
  };
  
  patches = [ ./0001-Skip-channeltest.patch ];
  
  makeFlags = [ "DESTDIR=$(out)" ];
  
  postInstall = ''
    mv "$out/usr/sbin" "$out/bin"
    mv "$out/usr/share" "$out/share"
    rmdir "$out/usr"
  '';

  meta = with lib; {
    description = "A minimalistic SSH server";
    homepage = https://tinyssh.org/;
    license = licenses.cc0;
  };
}
