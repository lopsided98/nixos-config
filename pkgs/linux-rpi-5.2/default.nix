{ lib, linux_rpi, buildLinux, fetchFromGitHub, ... } @args:

linux_rpi.override (old: args // {
  buildLinux = a: buildLinux (a // rec {
    version = "${modDirVersion}";
    modDirVersion = "5.2.0";

    src = fetchFromGitHub {
      name = "linux-rpi-${version}-source";
      owner = "raspberrypi";
      repo = "linux";
      rev = "1a75b37ead9ee99fee6db5525608755a73a5efba";
      sha256 = "1a1mwp935ip3zdk22w3b4wajnj5r8zaw6y8cllgakbi18a6bgw51";
    };
  });
})
