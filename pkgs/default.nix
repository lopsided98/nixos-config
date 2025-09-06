final: prev: with prev.lib; {
  dnsupdate = final.python3Packages.callPackage ./dnsupdate { };

  hacker-hats = final.callPackage ./hacker-hats {};

  mavlink-router = final.callPackage ./mavlink-router { };

  nixos-secrets = final.python3Packages.callPackage ./nixos-secrets { };

  tinyssh = final.callPackage ./tinyssh {};

  watchdog = final.callPackage ./watchdog { };

  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (pyFinal: pyPrev: {
    })
  ];

  # GPG pulls in huge numbers of graphics libraries by default
  gnupg = prev.gnupg.override { guiSupport = false; };

  linux_omnitech = final.callPackage ./linux-omnitech {
    kernelPatches = with final.kernelPatches; [
      bridge_stp_helper
      request_key_helper
    ];
  };
  linuxPackages_omnitech = final.recurseIntoAttrs (final.linuxPackagesFor final.linux_omnitech);

  rpicam-apps = final.callPackage ./rpicam-apps { };
}
