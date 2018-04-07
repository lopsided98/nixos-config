{ lib, stdenv, fetchFromGitHub }: let
  commit = "b58f2a51e2d360c18f499984c88c46ab6fcbedae";
in stdenv.mkDerivation {
  name = "hacker-hats-${lib.substring 0 7 commit}";

  src = fetchFromGitHub {
    owner = "lopsided98";
    repo = "HackerHats";
    rev = commit;
    sha256 = "1kym0h5qa9lvyad5055d9v5bpf774p3hhv4jv9jp4pp9li1x3qaj";
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
