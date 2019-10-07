{ lib, stdenv, fetchFromGitHub, makeWrapper, coreutils, zfs, perl, procps
, which, ConfigIniFiles, CaptureTiny, openssh, sudo, mbuffer, pv, lzop, gzip
, pigz }:

with lib;

stdenv.mkDerivation rec {
  pname = "sanoid";
  version = "2.0.2";

  src = fetchFromGitHub {
    owner = "jimsalterjrs";
    repo = pname;
    rev = "v${version}";
    sha256 = "09cgchhpprr8yyx9kabwz3y7lz9kzn6wfdsqq3zam7c7yck672xa";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ perl ConfigIniFiles CaptureTiny ];

  installPhase = ''
    mkdir -p "$out/bin"
    mkdir -p "$out/etc/sanoid"
    cp sanoid.defaults.conf "$out/etc/sanoid/sanoid.defaults.conf"
    # Hardcode path to default config
    substitute sanoid "$out/bin/sanoid" \
      --replace "\$args{'configdir'}/sanoid.defaults.conf" "$out/etc/sanoid/sanoid.defaults.conf" \
      --replace /sbin/zfs "${zfs}/bin/zfs" \
      --replace /sbin/zpool "${zfs}/bin/zpool" \
      --replace /bin/ps "${procps}/bin/ps"
    chmod +x "$out/bin/sanoid"
    patchShebangs "$out/bin/sanoid"
    wrapProgram "$out/bin/sanoid" --prefix PERL5LIB : "$PERL5LIB"

    install -m755 syncoid "$out/bin/syncoid"
    patchShebangs "$out/bin/syncoid"
    wrapProgram "$out/bin/syncoid" \
      --prefix PERL5LIB : "$PERL5LIB" \
      --prefix PATH : "${makeBinPath [ zfs openssh procps which pv mbuffer lzop gzip pigz ]}"

    substitute findoid "$out/bin/findoid" \
      --replace /sbin/zfs "${zfs}/bin/zfs"
    chmod +x "$out/bin/findoid"
    patchShebangs "$out/bin/syncoid"
    wrapProgram "$out/bin/findoid" --prefix PERL5LIB ":" "$PERL5LIB"
  '';

  meta = {
    description = "A policy-driven snapshot management tool for ZFS filesystems";
    homepage = https://github.com/jimsalterjrs/sanoid;
    license = lib.licenses.gpl3;
  };
}
