{ lib, stdenv, fetchFromGitHub, makeWrapper,
  coreutils, zfs, perl, procps, which, ConfigIniFiles, openssh, sudo,
  mbufferSupport ? true, mbuffer ? null,
  pvSupport ? true, pv ? null,
  lzoSupport ? true, lzop ? null,
  gzipSupport ? false, gzip ? null,
  parallelGzipSupport ? false, pigz ? null}:

with lib;

assert mbufferSupport -> mbuffer != null;
assert pvSupport -> pv != null;
assert lzoSupport -> lzop != null;
assert gzipSupport -> gzip != null;
assert parallelGzipSupport -> pigz != null;

let
  commit = "b04fb4552ab5bea793064c5f59d0e402231f5f56";

in stdenv.mkDerivation rec {
  name = "sanoid-${substring 0 7 commit}";

  src = fetchFromGitHub {
    owner = "lopsided98";
    repo = "sanoid";
    rev = "${commit}";
    sha256 = "171m0iyhqsxz7fycq9jz9cz80myylw2nq5kydyfywlxbqg04rzff";
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

    # Replace "ls" with "which" to with varied paths
    substitute syncoid "$out/bin/syncoid" \
      --replace /usr/bin/perl "${perl}/bin/perl" \
      --replace /sbin/zfs zfs \
      --replace /usr/bin/ssh "${openssh}/bin/ssh" \
      --replace /usr/bin/sudo sudo \
      --replace /bin/ps ps \
      --replace /bin/ls which \
      ${optionalString pvSupport "--replace /usr/bin/pv pv"} \
      ${optionalString mbufferSupport "--replace /usr/bin/mbuffer mbuffer"} \
      ${optionalString lzoSupport "--replace /usr/bin/lzop lzop"} \
      ${optionalString gzipSupport "--replace /bin/gzip gzip"} \
      ${optionalString gzipSupport "--replace /bin/zcat zcat"} \
      ${optionalString parallelGzipSupport "--replace /usr/bin/pigz pigz"}
    chmod +x "$out/bin/syncoid"
    wrapProgram "$out/bin/syncoid" \
      --prefix PERL5LIB ":" "$PERL5LIB" \
      --prefix PATH : "${makeBinPath ([ zfs sudo procps which ]
                          ++ optional pvSupport pv
                          ++ optional mbufferSupport mbuffer
                          ++ optional lzoSupport lzop
                          ++ optional gzipSupport gzip
                          ++ optional parallelGzipSupport pigz)}"

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
