{ lib, stdenv, fetchFromGitHub, autoreconfHook }: let
  version = "0.2";
in stdenv.mkDerivation rec {
  name = "tinyssh-convert-${version}";

  src = fetchFromGitHub {
    owner = "ansemjo";
    repo = "tinyssh-convert";
    rev = "v${version}";
    sha256 = "19l888pn45ayx9lpyfw2c5nlk484cyzn4r53mpcbs3q3c762igrc";
  };

  buildInputs = [ autoreconfHook ];

  meta = with lib; {
    description = "A minimalistic SSH server";
    homepage = https://tinyssh.org/;
    license = licenses.cc0;
  };
}
