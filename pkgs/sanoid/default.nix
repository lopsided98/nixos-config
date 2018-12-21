{ lib, stdenv, fetchFromGitHub, makeWrapper, coreutils, zfs, perl, procps, 
  which, ConfigIniFiles, openssh, sudo, mbuffer, pv, lzop, gzip, pigz }:

with lib;

stdenv.mkDerivation rec {
  pname = "sanoid";
  version = "2.0.1";

  src = fetchFromGitHub {
    owner = "jimsalterjrs";
    repo = pname;
    rev = "v${version}";
    sha256 = "142s74srx7ayyrkm8c31lp81zwwjwj4z14xmvylc6qfk3vih9rwy";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ perl ConfigIniFiles ];

  installPhase = ''
    mkdir -p "$out/bin"
    mkdir -p "$out/etc/sanoid"
    cp sanoid.defaults.conf "$out/etc/sanoid/sanoid.defaults.conf"
    # Hardcode path to default config
    substitute sanoid "$out/bin/sanoid" \
      --replace "\$args{'configdir'}/sanoid.defaults.conf" "$out/etc/sanoid/sanoid.defaults.conf" \
      --replace /usr/bin/perl "${perl}/bin/perl" \
      --replace /sbin/zfs "${zfs}/bin/zfs" \
      --replace /sbin/zpool "${zfs}/bin/zpool" \
      --replace /bin/ps "${procps}/bin/ps"
    chmod +x "$out/bin/sanoid"
    wrapProgram "$out/bin/sanoid" --prefix PERL5LIB ":" "$PERL5LIB"

    # Replace "ls" with "which" to work with varied paths
    substitute syncoid "$out/bin/syncoid" \
      --replace /usr/bin/perl "${perl}/bin/perl" \
      --replace /sbin/zfs zfs \
      --replace /usr/bin/ssh "${openssh}/bin/ssh" \
      --replace /usr/bin/sudo sudo \
      --replace /bin/ps ps \
      --replace /bin/ls which \
      --replace /usr/bin/pv pv \
      --replace /usr/bin/mbuffer mbuffer \
      --replace /usr/bin/lzop lzop \
      --replace /bin/gzip gzip \
      --replace /bin/zcat zcat \
      --replace /usr/bin/pigz pigz
    chmod +x "$out/bin/syncoid"
    wrapProgram "$out/bin/syncoid" \
      --prefix PERL5LIB ":" "$PERL5LIB" \
      --prefix PATH : "${makeBinPath [ zfs sudo procps which pv mbuffer lzop gzip pigz ]}"

    substitute findoid "$out/bin/findoid" \
      --replace /usr/bin/perl "${perl}/bin/perl" \
      --replace /sbin/zfs "${zfs}/bin/zfs"
    chmod +x "$out/bin/findoid"
    wrapProgram "$out/bin/findoid" --prefix PERL5LIB ":" "$PERL5LIB"
  '';

  meta = {
    description = "A policy-driven snapshot management tool for ZFS filesystems";
    homepage = https://github.com/jimsalterjrs/sanoid;
    license = lib.licenses.gpl3;
  };
}
