{ stdenv, lib, fetchurl, fetchFromGitHub, meson, ninja, pkgconfig, gettext
, python3, gst-plugins-base, raspberrypi-tools}:

stdenv.mkDerivation rec {
  pname = "gst-omx";
  version = "1.16.0";

  src = fetchurl {
    url = "${meta.homepage}/src/gst-omx/${pname}-${version}.tar.xz";
    sha256 = "0jmgm1afv8id1y8giv3d4h526qqbi3prssy4a6261117q3fprxzy";
  };

  patches = [ ./0001-Fix-fragmented-buffers-on-Raspberry-Pi.patch ];

  separateDebugInfo = true;

  outputs = [ "out" "dev" ];

  nativeBuildInputs = [ meson ninja pkgconfig gettext python3 ];

  mesonFlags = [ "-Dtarget=rpi" "-Dheader_path=${raspberrypi-tools}/include/IL" ];

  buildInputs = [ gst-plugins-base raspberrypi-tools ];

  postPatch = ''
    substituteInPlace config/rpi/gstomx.conf \
      --replace /opt/vc/lib/libopenmaxil.so "${raspberrypi-tools}/lib/libopenmaxil.so"
  '';

  meta = with stdenv.lib; {
    description = "GStreamer OpenMAX IL wrapper plugin";
    homepage = "https://gstreamer.freedesktop.org";
    longDescription = ''
      OpenMax-based decoder and encoder elements for GStreamer.
    '';
    license = licenses.lgpl2Plus;
    platforms = platforms.linux;
    maintainers = with maintainers; [ lopsided98 ];
  };
}
