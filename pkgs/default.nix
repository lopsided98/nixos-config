final: prev: {
  dnsupdate = final.python3Packages.callPackage ./dnsupdate { };

  hacker-hats = final.callPackage ./hacker-hats {};

  mavlink-router = final.callPackage ./mavlink-router { };

  nixos-secrets = final.python3Packages.callPackage ./nixos-secrets { };

  tinyssh = final.callPackage ./tinyssh {};

  watchdog = final.callPackage ./watchdog { };

  # GPG pulls in huge numbers of graphics libraries by default
  gnupg = prev.gnupg.override { guiSupport = false; };

  rpicam-apps = final.callPackage ./rpicam-apps { };
}
