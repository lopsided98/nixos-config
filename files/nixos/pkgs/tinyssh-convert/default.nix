{ lib, stdenv, fetchurl, autoreconfHook }:
let
  version = "0.2";
in stdenv.mkDerivation rec {
  name = "tinyssh-convert-${version}";

  src = fetchurl {
    url = "https://github.com/ansemjo/tinyssh-convert/archive/v${version}.tar.gz";
    sha256 = "1fi9zms9kcwgcw1hdpclkhid9ys7xrzqvmf02spvwns54lsk81m2";
  };

  buildInputs = [ autoreconfHook ];

  meta = with lib; {
    description = "A minimalistic SSH server";
    homepage = https://tinyssh.org/;
    license = licenses.cc0;
  };
}
