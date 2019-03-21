{ lib, linux_rpi, buildLinux, fetchFromGitHub, ... } @args:

linux_rpi.override (old: args // {
  buildLinux = a: buildLinux (a // rec {
    version = "${modDirVersion}";
    modDirVersion = "5.0.2";

    src = fetchFromGitHub {
      name = "linux-rpi-${version}-source";
      owner = "raspberrypi";
      repo = "linux";
      rev = "fd13b5afa162b756a1dffb437b6ac618363d04ea";
      sha256 = "0x0pvydqvf5cjwaasshdlpmqmay81xsh34my3yp6qppglbkg5g3k";
    };
  });
})
