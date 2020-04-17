self: super: with super.lib; let
  pythonOverridesFor = python: python.override (old: {
    packageOverrides = pySelf: pySuper: {
      aur = pySelf.callPackage ./python-modules/aur { };

      galileo = pySelf.callPackage ./python-modules/galileo { };

      memoizedb = pySelf.callPackage ./python-modules/memoizedb { };

      pyalpm = pySelf.callPackage ./python-modules/pyalpm {
        inherit (self) libarchive;
      };

      xcgf = pySelf.callPackage ./python-modules/xcgf { };

      xcpf = pySelf.callPackage ./python-modules/xcpf { };
    };
  });

in {

  audio-recorder = {
    audio-server = self.callPackage ./audio-recorder/audio-server.nix {};
    web-interface = self.python3Packages.callPackage ./audio-recorder/web-interface.nix {};
  };

  aur-buildbot = self.callPackage ./aur-buildbot {};

  dnsupdate = self.python3Packages.callPackage ./dnsupdate { };

  hacker-hats = self.callPackage ./hacker-hats {};

  kitty-cam = self.python3Packages.callPackage ./kitty-cam {};

  nixos-secrets = self.python3Packages.callPackage ./nixos-secrets { };

  tinyssh = self.callPackage ./tinyssh {};

  watchdog = self.callPackage ./watchdog { };

  water-level-base-station = self.callPackage ./water-level-base-station { };

  python27 = pythonOverridesFor super.python27;
  python36 = pythonOverridesFor super.python36;
  python37 = pythonOverridesFor super.python37;
  python38 = pythonOverridesFor super.python38;
  python39 = pythonOverridesFor super.python39;

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

  openrocket = self.callPackage ./openrocket { };

  sox = super.sox.override {
    enableLibpulseaudio = false;
  };

  linux_rock64_5_4 = self.callPackage ./linux-rock64/5.4.nix {
    kernelPatches = [ self.kernelPatches.bridge_stp_helper ];
  };
  linuxPackages_rock64_5_4 = self.recurseIntoAttrs (self.linuxPackagesFor self.linux_rock64_5_4);
}
