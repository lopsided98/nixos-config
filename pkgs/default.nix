self: super: with super.lib; let
  armv7lPackages = super.forceCross {
    system = "x86_64-linux";
    platform = systems.platforms.pc64;
  } systems.examples.armv7l-hf-multiplatform;

  aarch64Packages = super.forceCross {
    system = "x86_64-linux";
    platform = systems.platforms.pc64;
  } systems.examples.aarch64-multiplatform;

  crossPackages = if super.stdenv.hostPlatform.system == "armv7l-linux" then armv7lPackages
                  else if super.stdenv.hostPlatform.system == "aarch64-linux" then aarch64Packages
                  else super;
in rec {

  dnsupdate = super.callPackage ./dnsupdate/default.nix {
    inherit (self.python3Packages) buildPythonApplication requests pyyaml beautifulsoup4 netifaces;
  };

  aur-buildbot = super.callPackage ./aur-buildbot/default.nix {};

  buildbot = (super.buildbot.override {
    pythonPackages = self.python3Packages;
    inherit (self) buildbot-worker;
  }).overridePythonAttrs (oldAttrs: rec {

    # 7 tests fail because of some stupid ascii/utf-8 conversion issue, and I
    # don't use the failing modules anyway
    doCheck = false;
    LC_ALL = "en_US.UTF-8";
    preCheck = ''
      export PYTHONIOENCODING=utf8
    '';
  });

  pacman = super.callPackage ./pacman/default.nix {};

  hacker-hats = super.callPackage ./hacker-hats/default.nix {};

  tinyssh = super.callPackage ./tinyssh/default.nix {};

  tinyssh-convert = super.callPackage ./tinyssh-convert/default.nix {};

  libcreate = super.callPackage ./libcreate {};

  audioRecorder = self.python3Packages.callPackage ./audio-recorder {};

  nixUnstable = super.nixUnstable.overrideAttrs (old: {
    patches = [ ./nix-fix-xz-decompression.patch ];
  });

  sanoid = super.callPackage ./sanoid/default.nix {
    inherit (perlPackages) ConfigIniFiles;
    mbufferSupport = true;
    pvSupport = true;
    lzoSupport = true;
    gzipSupport = true;
    parallelGzipSupport = true;
  };

  python36 = super.python36.override {
    packageOverrides = pySelf: pySuper: with pySuper; {
      aur = pySelf.callPackage ./python-modules/aur { };

      grpcio-tools = pySelf.callPackage ./python-modules/grpcio-tools { };

      memoizedb = pySelf.callPackage ./python-modules/memoizedb { };

      netdisco = pySelf.callPackage ./python-modules/netdisco { };

      pyalpm = pySelf.callPackage ./python-modules/pyalpm {
        inherit (self) libarchive;
      };

      pyalsaaudio = pySelf.callPackage ./python-modules/pyalsaaudio { };

      upnpclient = pySelf.callPackage ./python-modules/upnpclient { };

      xcgf = pySelf.callPackage ./python-modules/xcgf { };

      xcpf = pySelf.callPackage ./python-modules/xcpf { };
    };
  };

  perlPackages = super.perlPackages // {
    ConfigIniFiles = with self.perlPackages; buildPerlModule rec {
      name = "Config-IniFiles-2.94";
      src = super.fetchurl {
        url = "mirror://cpan/authors/id/S/SH/SHLOMIF/${name}.tar.gz";
        sha256 = "1d4la72fpsf61hcpslmn03ajm5rfy8hm50piqmsfi7d7dm0qmlyn";
      };
      propagatedBuildInputs = [ IOStringy ];
      meta = {
        description = "A module for reading and writing .ini-style configuration files";
        homepage = https://github.com/shlomif/perl-Config-IniFiles;
        license = [ super.lib.licenses.gpl2 ];
      };
    };
  };

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

  linux_4_16 = if super.stdenv.hostPlatform.isArm then crossPackages.linux_4_16 else super.linux_4_16;
  linux_rpi = crossPackages.linux_rpi;
  linux_testing = crossPackages.linux_testing;

  linux_odroid_xu4 = crossPackages.callPackage ./linux-odroid-xu4 {
    kernelPatches =
      [ self.kernelPatches.bridge_stp_helper
        # See pkgs/os-specific/linux/kernel/cpu-cgroup-v2-patches/README.md
        # when adding a new linux version
        self.kernelPatches.cpu-cgroup-v2."4.11"
        self.kernelPatches.modinst_arg_list_too_long
      ];
  };
  linuxPackages_odroid_xu4 = super.recurseIntoAttrs (self.linuxPackagesFor self.linux_odroid_xu4);

  linux_rock64_mainline = super.callPackage ./linux-rock64-mainline {
    kernelPatches =
      [ self.kernelPatches.bridge_stp_helper
        # See pkgs/os-specific/linux/kernel/cpu-cgroup-v2-patches/README.md
        # when adding a new linux version
        # self.kernelPatches.cpu-cgroup-v2."4.11"
        self.kernelPatches.modinst_arg_list_too_long
      ];
  };
  linuxPackages_rock64_mainline = super.recurseIntoAttrs (self.linuxPackagesFor self.linux_rock64_mainline);
}
