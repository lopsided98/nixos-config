{ lib, stdenv, fetchFromGitHub, makeWrapper,
  coreutils, zfs, perl, procps, ConfigIniFiles, openssh, sudo,
  mbufferSupport ? false, mbuffer ? null,
  pvSupport ? false, pv ? null,
  lzoSupport ? false, lzop ? null,
  gzipSupport ? false, gzip ? null,
  parallelGzipSupport ? false, pigz ? null}:

with lib;

assert mbufferSupport -> mbuffer != null;
assert pvSupport -> pv != null;
assert lzoSupport -> lzop != null;
assert gzipSupport -> gzip != null;
assert parallelGzipSupport -> pigz != null;

let
  commit = "f6519c0aea4c624161f92a1304943d1c60e714bc";

in stdenv.mkDerivation rec {
  name = "sanoid-${substring 0 7 commit}";

  src = fetchFromGitHub {
    owner = "jimsalterjrs";
    repo = "sanoid";
    rev = "${commit}";
    sha256 = "1zfg438zbzfmhaq92dfmkialwar1lqxvl24yhvyz52wxwy6v5wa1";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ coreutils zfs perl ConfigIniFiles openssh sudo ]
    ++ optional mbufferSupport mbuffer
    ++ optional pvSupport pv
    ++ optional lzoSupport lzop
    ++ optional gzipSupport gzip
    ++ optional parallelGzipSupport pigz;

  installPhase = ''
    mkdir -p "$out/bin"
    mkdir -p "$out/conf"
    cp -a sanoid.defaults.conf "$out/conf/sanoid.defaults.conf"
    substitute sanoid "$out/bin/sanoid" \
      --replace /usr/bin/perl "${perl}/bin/perl" \
      --replace /sbin/zfs "${zfs}/bin/zfs" \
      --replace /sbin/zpool "${zfs}/bin/zpool" \
      --replace /bin/ps "${procps}/bin/ps"
    chmod +x "$out/bin/sanoid"
    wrapProgram "$out/bin/sanoid" --prefix PERL5LIB ":" "$PERL5LIB"

    substitute syncoid "$out/bin/syncoid" \
      --replace /usr/bin/perl "${perl}/bin/perl" \
      --replace /sbin/zfs "${zfs}/bin/zfs" \
      --replace /usr/bin/ssh "${openssh}/bin/ssh" \
      --replace /usr/bin/sudo "${sudo}/bin/sudo" \
      --replace /bin/ps "${procps}/bin/ps" \
      --replace /bin/ls "${procps}/bin/ps" \
      ${optionalString pvSupport "--replace /usr/bin/pv \"${pv}/bin/pv\""} \
      ${optionalString mbufferSupport "--replace /usr/bin/mbuffer \"${mbuffer}/bin/mbuffer\""} \
      ${optionalString lzoSupport "--replace /usr/bin/lzop \"${lzop}/bin/lzop\""} \
      ${optionalString gzipSupport "--replace /bin/gzip \"${gzip}/bin/gzip\""} \
      ${optionalString gzipSupport "--replace /bin/zcat \"${gzip}/bin/zcat\""} \
      ${optionalString parallelGzipSupport "--replace /usr/bin/pigz \"${pigz}/bin/pigz\""}
    chmod +x "$out/bin/syncoid"
    wrapProgram "$out/bin/syncoid" --prefix PERL5LIB ":" "$PERL5LIB"

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
