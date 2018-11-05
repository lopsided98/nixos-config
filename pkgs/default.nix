self: super: with super.lib; let
  pkgsArmv6lLinuxCross = super.forceCross {
    system = "x86_64-linux";
    platform = systems.platforms.pc64;
  } systems.examples.raspberryPi;

  pkgsArmv7lLinuxCross = super.forceCross {
    system = "x86_64-linux";
    platform = systems.platforms.pc64;
  } systems.examples.armv7l-hf-multiplatform;

  pkgsAarch64LinuxCross = super.forceCross {
    system = "x86_64-linux";
    platform = systems.platforms.pc64;
  } systems.examples.aarch64-multiplatform;

  pythonOverridesFor = python: python.override (old: {
    packageOverrides = pySelf: pySuper: {
      aur = pySelf.callPackage ./python-modules/aur { };

      grpcio-tools = pySelf.callPackage ./python-modules/grpcio-tools { };

      memoizedb = pySelf.callPackage ./python-modules/memoizedb { };

      pyalpm = pySelf.callPackage ./python-modules/pyalpm {
        inherit (self) libarchive;
      };

      pyalsaaudio = pySelf.callPackage ./python-modules/pyalsaaudio { };

      upnpclient = pySelf.callPackage ./python-modules/upnpclient { };

      xcgf = pySelf.callPackage ./python-modules/xcgf { };

      xcpf = pySelf.callPackage ./python-modules/xcpf { };
    };
  });

  perlOverridesFor = perlPackages: perlPackages.override (old: {
    overrides = with perlPackages; {
      ConfigIniFiles = buildPerlModule rec {
        name = "Config-IniFiles-3.000000";
        src = super.fetchurl {
          url = "mirror://cpan/authors/id/S/SH/SHLOMIF/${name}.tar.gz";
          sha256 = "0acv3if31s639iy7rcg86nwa5f6s55hiw7r5ysmh6gmay6vzd4nd";
        };
        propagatedBuildInputs = [ IOStringy ];
        meta = {
          description = "A module for reading and writing .ini-style configuration files";
          homepage = https://github.com/shlomif/perl-Config-IniFiles;
          license = [ super.lib.licenses.gpl2 ];
        };
      };
    };
  });

in {

  pkgsArmv7lLinux = super.customSystem { system = "armv7l-linux"; };

  crossPackages = if super.stdenv.hostPlatform.system == "armv6l-linux" then pkgsArmv6lLinuxCross
                  else if super.stdenv.hostPlatform.system == "armv7l-linux" then pkgsArmv7lLinuxCross
                  else if super.stdenv.hostPlatform.system == "aarch64-linux" then pkgsAarch64LinuxCross
                  else super;

  dnsupdate = super.callPackage ./dnsupdate/default.nix {
    inherit (self.python3Packages) buildPythonApplication requests pyyaml beautifulsoup4 netifaces;
  };

  aur-buildbot = super.callPackage ./aur-buildbot/default.nix {};

  hacker-hats = super.callPackage ./hacker-hats/default.nix {};

  tinyssh = super.callPackage ./tinyssh/default.nix {};

  tinyssh-convert = super.callPackage ./tinyssh-convert/default.nix {};

  libcreate = super.callPackage ./libcreate {};

  audioRecorder = self.python3Packages.callPackage ./audio-recorder {};

  kittyCam = self.python3Packages.callPackage ./kitty-cam {};

  sanoid = super.callPackage ./sanoid/default.nix {
    inherit (self.perlPackages) ConfigIniFiles;
    mbufferSupport = true;
    pvSupport = true;
    lzoSupport = true;
    gzipSupport = true;
    parallelGzipSupport = true;
  };

  python36 = pythonOverridesFor super.python36;
  python37 = pythonOverridesFor super.python37;

  perl526Packages = perlOverridesFor super.perl526Packages;
  perl528Packages = perlOverridesFor super.perl528Packages;
  perldevelPackages = perlOverridesFor super.perldevelPackages;

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

  gst_all_1 = super.gst_all_1.extend (gstSelf: gstSuper: {
    gst-plugins-bad = gstSuper.gst-plugins-bad.overrideAttrs (old: rec {
      buildInputs = old.buildInputs ++ [ self.rtmpdump ];
    });
    gst-omx = gstSelf.callPackage ./gst-omx { };
  });

  orc = super.orc.overrideAttrs (old: {
    doCheck = old.doCheck && !super.stdenv.hostPlatform.isAarch32;
  });

  libao = super.libao.override {
    usePulseAudio = false;
  };

  sox = super.sox.override {
    enableLibpulseaudio = false;
  };

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
