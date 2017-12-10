self: super: rec {
  dnsupdate = super.callPackage ./dnsupdate/default.nix {
    inherit (self.python3Packages) buildPythonApplication requests pyyaml beautifulsoup4 netifaces;
  };
  
  aur-buildbot = super.callPackage ./aur-buildbot/default.nix {};
  
  buildbot = super.buildbot.override { 
    pythonPackages = self.python3Packages;
  };
  
  buildbot-worker = (super.buildbot-worker.override {
    pythonPackages = self.python3Packages;
  }).overrideAttrs (oldAttrs: rec {
    version = "0.9.12";
    src = self.python3Packages.fetchPypi {
      inherit (oldAttrs) pname;
      inherit version;
      sha256 = "0hdgcm175xnb49mdmgqh5mpw90wbzfd2nvgrq5jqklavabswvafj";
    };
  
    passthru = oldAttrs.passthru // {
      python = self.python3Packages.python;
    };
  });
  
  pacman = super.callPackage ./pacman/default.nix {};
  
  muximux = super.callPackage ./muximux/default.nix {};
  
  tinyssh = super.callPackage ./tinyssh/default.nix {};
  
  tinyssh-convert = super.callPackage ./tinyssh-convert/default.nix {};

  sanoid = super.callPackage ./sanoid/default.nix {
    inherit (perlPackages) ConfigIniFiles;
    mbufferSupport = true;
    pvSupport = true;
    lzoSupport = true;
    gzipSupport = true;
    parallelGzipSupport = true;
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
  
  linuxPackages_latest = super.linuxPackages_latest // {
    tmon = super.callPackage ./tmon/default.nix {
      kernel = self.linuxPackages_latest.kernel;
    };
  };
  
  linuxPackages_4_13 = super.linuxPackages_4_13 // {
    tmon = super.callPackage ./tmon/default.nix {
      kernel = self.linuxPackages_4_13.kernel;
    };
  };
}
