{ lib, linux_rpi, buildLinux, fetchFromGitHub, ... } @args:

linux_rpi.override (old: args // {
  buildLinux = a: buildLinux (a // rec {
    version = "${modDirVersion}";
    modDirVersion = "4.19.10";

    src = fetchFromGitHub {
      owner = "raspberrypi";
      repo = "linux";
      rev = "9a2e2d98ae5154ecef23aac28ca4d3165ac002ee";
      sha256 = "1fx24phag7nhpyqrhha7kzg1kjv6jr22gcsizh7jxh06kd9vnpn7";
    };
  });
})
