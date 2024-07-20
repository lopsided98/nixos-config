final: prev: with prev.lib; {
  aur-buildbot = final.callPackage ./aur-buildbot {};

  dnsupdate = final.python3Packages.callPackage ./dnsupdate { };

  hacker-hats = final.callPackage ./hacker-hats {};

  mavlink-router = final.callPackage ./mavlink-router { };

  nixos-secrets = final.python3Packages.callPackage ./nixos-secrets { };

  tinyssh = final.callPackage ./tinyssh {};

  watchdog = final.callPackage ./watchdog { };

  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (pyFinal: pyPrev: {
      aur = pyFinal.callPackage ./python-modules/aur { };

      memoizedb = pyFinal.callPackage ./python-modules/memoizedb { };

      pyalpm = pyFinal.callPackage ./python-modules/pyalpm {
        inherit (final) libarchive;
      };

      xcgf = pyFinal.callPackage ./python-modules/xcgf { };

      xcpf = pyFinal.callPackage ./python-modules/xcpf { };
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

  wpa_supplicant = prev.wpa_supplicant.overrideAttrs ({ patches ? [], ... }: {
    patches = patches ++ [
      # Fix external passwords with 4-way handshake offloading
      (final.fetchpatch {
        url = "https://github.com/lopsided98/hostap/commit/023c17659786fe381312f154cf06663f1cb3607c.patch";
        hash = "sha256-sQDcLPRMWGmos+V7O+mNv7myZ/Ubxg6ZLftF+g3lUng=";
      })
      # Fix external passwords with WPA3-SAE
      (final.fetchpatch {
        url = "https://github.com/lopsided98/hostap/commit/abf0b545c7f29ce10a07e6aad08f01878125ae5e.patch";
        hash = "sha256-qxh8VnSe6eQpjivNvwW8bhBS5KxNETmGXq1l/a0J2iQ=";
      })
    ];
  });
}
