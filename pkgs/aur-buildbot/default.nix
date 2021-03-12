{ stdenv, lib, fetchFromGitHub }:

stdenv.mkDerivation {
  pname = "aur-buildbot";
  version = "2021-02-05";

  src = fetchFromGitHub {
    owner = "lopsided98";
    repo = "aur-buildbot";
    rev = "080802ea437a5822ff0840d25b5030496ba91e9e";
    sha256 = "0mgqr31rppgn19qhjhpvsj8lzqn7b6mbklhba71d8ca2q4v55jh6";
  };

  installPhase = ''
    mkdir "$out"
    cp -a * "$out"
  '';

  postFixup = ''
    substituteInPlace "$out/worker/build-package" \
      --replace /bin/bash "${stdenv.shell}" \
  '';

  # Don't patch the docker entrypoint script
  dontPatchShebangs = true;

  meta = with lib; {
    description = "Buildbot configuration for building Arch Linux AUR packages";
    homepage = "https://github.com/lopsided98/aur-buildbot";
    license = licenses.gpl3;
    maintainers = with maintainers; [ lopsided98 ];
  };
}
