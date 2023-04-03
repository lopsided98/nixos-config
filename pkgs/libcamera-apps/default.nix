{ lib, stdenv, fetchFromGitHub, cmake, pkg-config, libcamera, boost, ffmpeg_5
, libexif, libjpeg, libtiff, libpng, libdrm, opencv }:

stdenv.mkDerivation rec {
  pname = "libcamera-apps";
  version = "1.1.2";
  
  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-A6UriYk8bHRL6wp6ehXOnUnbJH2/mNDkxwGemD/UYpw=";
  };

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [
    libcamera
    boost
    (ffmpeg_5.override { withV4l2M2m = true; })
    libexif
    libjpeg
    libtiff
    libpng
    libdrm
    opencv
  ];

  meta = with lib; {
    description = "Small suite of libcamera-based apps that aim to copy the functionality of the existing 'raspicam' apps";
    maintainers = with maintainers; [ lopsided98 ];
  };
}
