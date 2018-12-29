{ lib, linux_rpi, buildLinux, fetchFromGitHub, ... } @args:

linux_rpi.override (old: args // {
  buildLinux = a: buildLinux (a // rec {
    version = "${modDirVersion}";
    modDirVersion = "4.20.0";

    src = fetchFromGitHub {
      owner = "raspberrypi";
      repo = "linux";
      rev = "e67a50ff84e746515ddf5c455119ffaac5c26e23";
      sha256 = "0hzclxfvb0cn54c8pgngdqqhwq8aj31rnb2d9h2dc9dpq0mwldhf";
    };
  });
})
