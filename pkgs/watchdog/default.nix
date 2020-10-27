{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "watchdog";
  version = "5.16";

  src = fetchurl {
    url = "mirror://sourceforge/${pname}/${pname}-${version}.tar.gz";
    sha256 = "17817dd2gixdq0dbpkv94qiwjxlzqdf3phdxcckfwampw5qc1rxq";
  };

  makeFlags = [ "DESTDIR=$(out)" "prefix=" ];
}
