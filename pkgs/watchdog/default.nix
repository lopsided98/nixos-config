{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "watchdog";
  version = "5.15";

  src = fetchurl {
    url = "mirror://sourceforge/${pname}/${pname}-${version}.tar.gz";
    sha256 = "0z4l306aylnb401p4dj63dni7jp69nnjpljbcr9qwpdd6x8qdp7z";
  };

  makeFlags = [ "DESTDIR=$(out)" "prefix=" ];
}
