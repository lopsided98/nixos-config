{ stdenv, fetchurl, kernel, coreutils, ncurses }:

stdenv.mkDerivation {
  name = "tmon-${kernel.version}";

  src = kernel.src;

  buildInputs = [ ncurses ];

  configurePhase = ''
    cd tools/thermal/tmon
  '';

  buildPhase = ''
    make
  '';

  installPhase = ''
    make INSTALL_ROOT="$out" BINDIR="bin" install
  '';

  enableParallelBuilding = true;

  meta = with stdenv.lib; {
    description = "Monitoring and Testing Tool for Linux kernel thermal subsystem";
    homepage = https://www.kernel.org/;
    license = licenses.gpl2;
    platforms = platforms.linux;
  };
}
