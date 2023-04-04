{ lib, stdenv, fetchFromGitHub, meson, ninja }:

stdenv.mkDerivation rec {
  pname = "mavlink-router";
  version = "3";

  src = fetchFromGitHub {
    owner = pname;
    repo = pname;
    rev = "v${version}";
    hash = "sha256-aWGiXQN1aNwkjaFcfZWnIuxcbsIpFuOclp7iI1CBstg=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [ meson ninja ];

  mesonFlags = [ "-Dsystemdsystemunitdir=lib/systemd/system" ];

  meta = with lib; {
    description = "Route mavlink packets between endpoints";
    homepage = "https://github.com/mavlink-router/mavlink-router";
    license = licenses.asl20;
    maintainers = with maintainers; [ lopsided98 ];
  };
}
