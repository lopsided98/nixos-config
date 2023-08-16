{ lib, stdenv, fetchFromGitHub, fetchpatch }:

stdenv.mkDerivation rec {
  pname = "tinyssh";
  version = "20230101";

  src = fetchFromGitHub {
    owner = "janmojzis";
    repo = pname;
    rev = version;
    hash = "sha256-yEqPrLp14AF0L1QLoIcBhTphmd6qVzOB9EVW0Miy8yM=";
  };

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
