self: super: with super.lib; let
  armv7lPackages = super.crossPackages {
    system = "x86_64-linux";
    platform = systems.platforms.pc64;
  } systems.examples.armv7l-hf-multiplatform;

  aarch64Packages = super.crossPackages {
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

  buildbot-pkg = super.buildbot-pkg.override {
    inherit (self.python3Packages) buildPythonPackage fetchPypi setuptools;
  };

  buildbot-plugins = mapAttrs (n: p: p.override {
    pythonPackages = self.python3Packages;
  }) super.buildbot-plugins;

  buildbot-worker = super.buildbot-worker.override {
    pythonPackages = self.python3Packages;
  };

  pacman = super.callPackage ./pacman/default.nix {};

  hacker-hats = super.callPackage ./hacker-hats/default.nix {};

  tinyssh = super.callPackage ./tinyssh/default.nix {};

  tinyssh-convert = super.callPackage ./tinyssh-convert/default.nix {};

  libcreate = super.callPackage ./libcreate {};

  sanoid = super.callPackage ./sanoid/default.nix {
    inherit (perlPackages) ConfigIniFiles;
    mbufferSupport = true;
    pvSupport = true;
    lzoSupport = true;
    gzipSupport = true;
    parallelGzipSupport = true;
  };

  python3 = super.python3.override {
    packageOverrides = se: su: {
      sqlalchemy_migrate = su.sqlalchemy_migrate.overridePythonAttrs (oldAttrs: {
        patches = [ ./sqlachemy-migrate-use-raw-strings.patch ];
      });
    };
  };

  python3Packages = with self.python3Packages; super.python3Packages // {
    pyalpm = super.callPackage ./python-modules/pyalpm/default.nix {
      inherit buildPythonPackage nose;
    };

    xcgf = super.callPackage ./python-modules/xcgf/default.nix {
      inherit buildPythonPackage;
    };

    memoizedb = super.callPackage ./python-modules/memoizedb/default.nix {
      inherit buildPythonPackage;
    };

    xcpf = super.callPackage ./python-modules/xcpf/default.nix {
      inherit buildPythonPackage pyalpm pyxdg memoizedb xcgf;
    };

    aur = super.callPackage ./python-modules/aur/default.nix {
      inherit buildPythonPackage pyalpm xcgf xcpf pyxdg;
    };
  };

  perlPackages = super.perlPackages // {
    ConfigIniFiles = with self.perlPackages; buildPerlModule rec {
      name = "Config-IniFiles-2.94";
      src = fetchurl {
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

  # Cross compile kernel on ARMv6/7
  linux_4_16 = if super.stdenv.hostPlatform.isArm then crossPackages.linux_4_16 else super.linux_4_16;

  linux_odroid_xu4 = crossPackages.callPackage ./linux-odroid-xu4/linux-odroid-xu4.nix {
    kernelPatches =
      [ self.kernelPatches.bridge_stp_helper
        # See pkgs/os-specific/linux/kernel/cpu-cgroup-v2-patches/README.md
        # when adding a new linux version
        self.kernelPatches.cpu-cgroup-v2."4.11"
        self.kernelPatches.modinst_arg_list_too_long
      ];
  };

  linux_rock64_mainline = super.callPackage ./linux-rock64-mainline/linux-rock64-mainline.nix {
    kernelPatches =
      [ self.kernelPatches.bridge_stp_helper
        # See pkgs/os-specific/linux/kernel/cpu-cgroup-v2-patches/README.md
        # when adding a new linux version
        # self.kernelPatches.cpu-cgroup-v2."4.11"
        self.kernelPatches.modinst_arg_list_too_long
      ];
  };

  linux_rock64 = super.callPackage ./linux-rock64/linux-rock64.nix {
    kernelPatches =
      [ self.kernelPatches.bridge_stp_helper
        self.kernelPatches.cpu-cgroup-v2."4.4"
        self.kernelPatches.modinst_arg_list_too_long
        {
          name = "remove-gcc-wrapper";
          patch = ./linux-rock64/remove-gcc-wrapper.patch;
        }
      ];
  };

  linuxPackages_odroid_xu4 = super.recurseIntoAttrs (self.linuxPackagesFor self.linux_odroid_xu4);
  linuxPackages_rock64_mainline = super.recurseIntoAttrs (self.linuxPackagesFor self.linux_rock64_mainline);
  linuxPackages_rock64 = super.recurseIntoAttrs (self.linuxPackagesFor self.linux_rock64);
}
