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

  ffmpeg-full = super.ffmpeg-full.override {
    libX11 = null; # Xlib support
    libxcb = null; # X11 grabbing using XCB
    libxcbshmExtlib = false; # X11 grabbing shm communication
    libxcbxfixesExtlib = false; # X11 grabbing mouse rendering
    libxcbshapeExtlib = false; # X11 grabbing shape rendering
    libXv = null; # Xlib support
    libpulseaudio = null; # Pulseaudio input support
  };

  libao = super.libao.override {
    usePulseAudio = false;
  };

  sox = super.sox.override {
    enableLibpulseaudio = false;
  };

  linux_omnitech = self.callPackage ./linux-omnitech {
    kernelPatches = with self.kernelPatches; [
      bridge_stp_helper
      request_key_helper
    ];
  };
  linuxPackages_omnitech = self.recurseIntoAttrs (self.linuxPackagesFor self.linux_omnitech);
}
