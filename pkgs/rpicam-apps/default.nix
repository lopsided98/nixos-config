{ lib, stdenv, fetchFromGitHub, fetchpatch, meson, ninja, pkg-config, libcamera
, boost, ffmpeg, libdrm, libexif, libjpeg, libtiff, libpng, opencv, libX11
, epoxy, libGL
, withOpencv ? false
, withPreview ? false }:

stdenv.mkDerivation (finalAttrs: {
  pname = "rpicam-apps";
  version = "1.6.0";

  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = "rpicam-apps";
    rev = "v${finalAttrs.version}";
    hash = "sha256-pTSHmRmGV203HjrH6MWNDEz2xLitCsILKsOYD9PgjwU=";
  };

  patches = [
    (fetchpatch {
      # Fix deprecation warning with FFmpeg 7.1
      # https://github.com/raspberrypi/rpicam-apps/pull/792
      url = "https://github.com/raspberrypi/rpicam-apps/commit/0d2b311db0a190b7475b5a2e72637110a4b0231d.patch";
      hash = "sha256-/+88P1g3xcdUz1wnscRwKJywSjE9LtB+ipE1qL7didY=";
    })
  ];

  nativeBuildInputs = [ meson ninja pkg-config ];
  buildInputs = [
    libcamera
    boost
    (ffmpeg.override { withV4l2M2m = true; })
    # Required unconditionally by libav_encoder
    libdrm
    libexif
    libjpeg
    libtiff
    libpng
  ] ++ lib.optionals withOpencv [
    opencv
  ] ++ lib.optionals withPreview [
    libX11
    epoxy
    libGL
  ];

  mesonFlags = [
    (lib.mesonEnable "enable_opencv" withOpencv)
    # libav_encoder requires libdrm unconditionally, so might as well include
    # DRM preview as well
    (lib.mesonEnable "enable_drm" true)
    (lib.mesonEnable "enable_egl" withPreview)
    # Don't want to bother with Qt
    (lib.mesonEnable "enable_qt" false)
    (lib.mesonEnable "enable_hailo" false)
  ];

  meta = with lib; {
    description = "Small suite of libcamera-based applications to drive the cameras on a Raspberry Pi platform.";
    homepage = "https://github.com/raspberrypi/rpicam-apps";
    license = licenses.bsd2;
    maintainers = with maintainers; [ lopsided98 ];
  };
})
