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

  nixUnstable = super.nixUnstable.overrideAttrs (old: {
    patches = [ ./nix-fix-xz-decompression.patch ];
  });

  sanoid = super.callPackage ./sanoid/default.nix {
    inherit (self.perlPackages) ConfigIniFiles;
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

      lirc = pySelf.toPythonModule self.lirc;

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

  gst_all_1 = super.gst_all_1 // {
    gst-plugins-base = (super.gst_all_1.gst-plugins-base.override {
      inherit (self.gst_all_1) gstreamer;
    }).overrideAttrs (old: rec {
      name = "gst-plugins-base-1.14.3";
      src = self.fetchurl {
        url = "${old.meta.homepage}/src/gst-plugins-base/${name}.tar.xz";
        sha256 = "0lkr1fm3bz21nqq9vi5v74mlxw6dd6i7piw00fhc5zz0dg1ikczh";
      };
    });
    gst-plugins-bad = (super.gst_all_1.gst-plugins-bad.override {
      inherit (self.gst_all_1) gst-plugins-base;
    }).overrideAttrs (old: rec {
      buildInputs = old.buildInputs ++ [ self.rtmpdump ];
      name = "gst-plugins-bad-1.14.3";
      src = self.fetchurl {
        url = "${old.meta.homepage}/src/gst-plugins-bad/${name}.tar.xz";
        sha256 = "1mczcna91f3kkk3yv5fkfa8nmqdr9d93aq9z4d8sv18vkiflw8mj";
      };
    });
    gst-plugins-good = (super.gst_all_1.gst-plugins-good.override {
      inherit (self.gst_all_1) gst-plugins-base;
    }).overrideAttrs (old: rec {
      name = "gst-plugins-good-1.14.3";
      src = self.fetchurl {
        url = "${old.meta.homepage}/src/gst-plugins-good/${name}.tar.xz";
        sha256 = "0pgzgfqbfp8lz2ns68797xfxdr0cr5rpi93wd1h2grhbmzkbq4ji";
      };
    });
    gstreamer = super.gst_all_1.gstreamer.overrideAttrs (old: rec {
      name = "gstreamer-1.14.3";
      src = self.fetchurl {
        url = "${old.meta.homepage}/src/gstreamer/${name}.tar.xz";
        sha256 = "0mh4755an4gk0z3ygqhjpdjk0r2cwswbpwfgl0x6qmnln4757bhk";
      };
    });
    gst-omx = super.callPackage ./gst-omx {
      inherit (self.gst_all_1) gst-plugins-base;
    };
  };

  orc = super.orc.overrideAttrs (old: {
    doCheck = old.doCheck && !super.stdenv.hostPlatform.isAarch32;
  });

  libao = super.libao.override {
    usePulseAudio = false;
  };

  sox = super.sox.override {
    enableLibpulseaudio = false;
  };

  lirc = super.lirc.overrideAttrs (old: {
    buildInputs = with self; [ alsaLib xlibsWrapper libxslt systemd libusb libftdi1 ];
    nativeBuildInputs = old.nativeBuildInputs ++ (with self; [ autoreconfHook (python3.withPackages (p: with p; [ pyyaml setuptools ])) ]);
    patches = [ ./lirc-fix-python-bindings.patch ];
  });

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
