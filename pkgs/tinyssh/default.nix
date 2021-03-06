{ lib, stdenv, fetchFromGitHub, fetchpatch }:

stdenv.mkDerivation rec {
  pname = "tinyssh";
  version = "20190101";

  src = fetchFromGitHub {
    owner = "janmojzis";
    repo = pname;
    rev = version;
    sha256 = "1xfm9gnpng8d5y3456rgz78jl5n9y5q005gf5vaswd99v4hrw742";
  };

  patches = [
    ./0001-Skip-channeltest.patch
    (fetchpatch {
      url = "https://github.com/janmojzis/tinyssh/commit/f69d3b773ffe93ad6c74a4d1c75ba43366bb64f8.patch";
      sha256 = "1y7rfy65qkm60ivzmj28i0lil77axpdhny8al7lxv3xn61v2rxiy";
    })
    (fetchpatch {
      url = "https://github.com/janmojzis/tinyssh/commit/656a6b0313286bfe097c222a91b3a4b51b795b5a.patch";
      sha256 = "1zddvsflppac8f97r0ccafdl2b1nsql6irvw89g1mr631xh74cx7";
    })
  ];

  buildPhase = ''
    runHook preBuild
    sh -e make-tinyssh${lib.optionalString (stdenv.hostPlatform != stdenv.buildPlatform) "cc"}.sh
    runHook postBuild
  '';

  makeFlags = [ "DESTDIR=$(out)" ];
  
  outputs = [ "out" "man" ];

  preInstall = ''
    echo /bin > conf-bin
    echo /share/man > conf-man
  '';

  meta = with lib; {
    description = "A minimalistic SSH server";
    homepage = "https://tinyssh.org";
    license = licenses.cc0;
    maintainers = [ maintainers.lopsided98 ];
  };
}
