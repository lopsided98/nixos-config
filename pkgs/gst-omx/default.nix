{ stdenv, fetchurl, fetchFromGitHub, meson, ninja, pkgconfig, gettext, python3,
  gst-plugins-base, raspberrypi-tools}:

stdenv.mkDerivation rec {
  name = "gst-omx-1.14.4";

  meta = with stdenv.lib; {
    description = "GStreamer OpenMAX IL wrapper plugin";
    homepage    = "https://gstreamer.freedesktop.org";
    longDescription = ''
      OpenMax-based decoder and encoder elements for GStreamer.
    '';
    license     = licenses.lgpl2Plus;
    platforms   = platforms.linux;
    maintainers = with maintainers; [ lopsided98 ];
  };

  src = fetchurl {
    url = "${meta.homepage}/src/gst-omx/${name}.tar.xz";
    sha256 = "1m53iqkaw7gmcv2b0vlpzpxkmz1j54n0wlw3hxpwjx8zbkkp164n";
  };

  patches = [ ./0001-Fix-fragmented-buffers-on-Raspberry-Pi.patch ];

  separateDebugInfo = true;

  outputs = [ "out" "dev" ];

  nativeBuildInputs = [ meson ninja pkgconfig gettext python3 ];

  mesonFlags = [ "-Dwith_omx_target=rpi" "-Dwith_omx_header_path=${raspberrypi-tools}/include/IL" ];

  buildInputs = [ gst-plugins-base raspberrypi-tools ];

  postPatch = ''
    substituteInPlace config/rpi/gstomx.conf \
      --replace /opt/vc/lib/libopenmaxil.so "${raspberrypi-tools}/lib/libopenmaxil.so"
  '';
}
