{ stdenv, lib, fetchFromGitHub, runtimeShell }:

stdenv.mkDerivation {
  pname = "aur-buildbot";
  version = "2024-10-17";

  src = fetchFromGitHub {
    owner = "lopsided98";
    repo = "aur-buildbot";
    rev = "14cbd4c402e496e1ce4ea174aebdeb43e98c0c57";
    hash = "sha256-SjBVWfUHlYaL+69LBSRVxtlxILs536GKrNa2G8rLBDo=";
  };

  installPhase = ''
    mkdir "$out"
    cp -a * "$out"
  '';

  postFixup = ''
    substituteInPlace "$out/worker/build-package" \
      --replace /bin/bash "${runtimeShell}" \
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
