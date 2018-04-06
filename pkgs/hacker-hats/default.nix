{ lib, stdenv, fetchFromGitHub }:

let
commit = "8db7720655fcf1d038e5c3a0bfc80ed917a70630";

in stdenv.mkDerivation {
  name = "hacker-hats-${lib.substring 0 7 commit}";

  src = fetchFromGitHub {
    owner = "lopsided98";
    repo = "HackerHats";
    rev = commit;
    sha256 = "0iaga2m8yabgdvwqlxqpnf30nmz5mq43jk0kdfkxjshx48vix7hv";
  };

  installPhase = ''
    cp -a . "$out"
  '';


  meta = {
    description = "A website created for my Writing 5 class at Dartmouth";
    homepage = https://github.com/lopsided98/HackerHats;
    license = [ lib.licenses.gpl3 ];
  };
}
