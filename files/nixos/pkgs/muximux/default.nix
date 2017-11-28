{ lib, stdenv, fetchFromGitHub }:

let
commit = "66b11488206b44364b6ed8bb438462cbbb0835c5";

in stdenv.mkDerivation {
  name = with lib; "muximux-${substring 0 7 commit}";

  src = fetchFromGitHub {
    owner = "mescon";
    repo = "Muximux";
    rev = commit;
    sha256 = "039gil0glb3kjywf3ac3r0z6v75lgy8hf7bqzpnn0zq4pwsf060q";
  };

  builder = ./builder.sh;

  meta = {
    description = "A lightweight way to manage your HTPC";
    homepage = https://github.com/mescon/Muximux;
  };
}
