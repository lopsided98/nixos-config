{ lib, stdenv, fetchFromGitHub, meson, ninja, pkg-config, libcamera, boost
, ffmpeg, libdrm, libexif, libjpeg, libtiff, libpng, opencv, libX11, epoxy
, libGL
, withOpencv ? false
, withPreview ? false }:

stdenv.mkDerivation (finalAttrs: {
  pname = "rpicam-apps";
  version = "1.5.2";

  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = "rpicam-apps";
    rev = "v${finalAttrs.version}";
    hash = "sha256-qCYGrcibOeGztxf+sd44lD6VAOGoUNwRqZDdAmcTa/U=";
  };

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
