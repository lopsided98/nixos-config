{ lib, linux_rpi, buildLinux, fetchFromGitHub, ... } @args:

linux_rpi.override (old: args // {
  buildLinux = a: buildLinux (a // rec {
    version = "${modDirVersion}-20181204";
    modDirVersion = "4.19.7";

    src = fetchFromGitHub {
      owner = "raspberrypi";
      repo = "linux";
      rev = "172a80a6804086350ee594765d43047a69f4755f";
      sha256 = "06axrwcgmyhd2j1grvlmri7nqqnirqs6dsl6yarb46114r6kc7gf";
    };
  });
})
