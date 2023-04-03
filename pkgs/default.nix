self: super: with super.lib; let
  pythonOverridesFor = python: python.override (old: {
    packageOverrides = pySelf: pySuper: {
      aur = pySelf.callPackage ./python-modules/aur { };

      galileo = pySelf.callPackage ./python-modules/galileo { };

      memoizedb = pySelf.callPackage ./python-modules/memoizedb { };

      pyalpm = pySelf.callPackage ./python-modules/pyalpm {
        inherit (self) libarchive;
      };

      upnpclient = pySelf.callPackage ./python-modules/upnpclient { };

      xcgf = pySelf.callPackage ./python-modules/xcgf { };

      xcpf = pySelf.callPackage ./python-modules/xcpf { };
    };
  });

in {
  aur-buildbot = self.callPackage ./aur-buildbot {};

  dnsupdate = self.python3Packages.callPackage ./dnsupdate { };

  hacker-hats = self.callPackage ./hacker-hats {};

  libcamera-apps = self.callPackage ./libcamera-apps { };

  nixos-secrets = self.python3Packages.callPackage ./nixos-secrets { };

  tinyssh = self.callPackage ./tinyssh {};

  watchdog = self.callPackage ./watchdog { };

  python27 = pythonOverridesFor super.python27;
  python37 = pythonOverridesFor super.python37;
  python38 = pythonOverridesFor super.python38;
  python39 = pythonOverridesFor super.python39;
  python310 = pythonOverridesFor super.python310;
  python311 = pythonOverridesFor super.python311;

  # GPG pulls in huge numbers of graphics libraries by default
  gnupg = super.gnupg.override { guiSupport = false; };

  linux_omnitech = self.callPackage ./linux-omnitech {
    kernelPatches = with self.kernelPatches; [
      bridge_stp_helper
      request_key_helper
    ];
  };
  linuxPackages_omnitech = self.recurseIntoAttrs (self.linuxPackagesFor self.linux_omnitech);

  wpa_supplicant = super.wpa_supplicant.overrideAttrs ({ patches ? [], ... }: {
    patches = patches ++ [
      # Fix external passwords with 4-way handshake offloading
      (self.fetchpatch {
        url = "https://github.com/lopsided98/hostap/commit/023c17659786fe381312f154cf06663f1cb3607c.patch";
        hash = "sha256-sQDcLPRMWGmos+V7O+mNv7myZ/Ubxg6ZLftF+g3lUng=";
      })
      # Fix external passwords with WPA3-SAE
      (self.fetchpatch {
        url = "https://github.com/lopsided98/hostap/commit/abf0b545c7f29ce10a07e6aad08f01878125ae5e.patch";
        hash = "sha256-qxh8VnSe6eQpjivNvwW8bhBS5KxNETmGXq1l/a0J2iQ=";
      })
    ];
  });
}
