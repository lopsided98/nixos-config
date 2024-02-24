{ lib, stdenv, fetchFromGitHub, meson, ninja, pkg-config, libcamera, boost
, ffmpeg_5, libexif, libjpeg, libtiff, libpng, libdrm, opencv }:

stdenv.mkDerivation (finalAttrs: {
  pname = "rpicam-apps";
  version = "1.4.3";

  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = "rpicam-apps";
    rev = "v${finalAttrs.version}";
    hash = "sha256-8YUXbk+qBAXoeMRaxJpUJB/lD8Yi8llO9A8ylpNA33A=";
  };

  nativeBuildInputs = [ meson ninja pkg-config ];
  buildInputs = [
    # rpicam-apps requires this fork
    (libcamera.overrideAttrs ({
      mesonFlags ? [], ...
    }: {
      src = fetchFromGitHub {
        owner = "raspberrypi";
        repo = "libcamera";
        rev = "v0.2.0+rpt20240215";
        hash = "sha256-+7dHUIXRsoy9CCHApmCnGuMjhGx/VhleI+zwB7E+5lU=";
      };
      mesonFlags = mesonFlags ++ [
        "-Dpipelines=rpi/vc4"
      ];
    }))
    boost
    (ffmpeg_5.override { withV4l2M2m = true; })
    libexif
    libjpeg
    libtiff
    libpng
    libdrm
    opencv
  ];

  env = {
    # https://github.com/NixOS/nixpkgs/issues/86131
    BOOST_INCLUDEDIR = "${lib.getDev boost}/include";
    BOOST_LIBRARYDIR = "${lib.getLib boost}/lib";
  };

  meta = with lib; {
    description = "Small suite of libcamera-based applications to drive the cameras on a Raspberry Pi platform.";
    homepage = "https://github.com/raspberrypi/rpicam-apps";
    license = licenses.bsd2;
    maintainers = with maintainers; [ lopsided98 ];
  };
})
