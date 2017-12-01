self: super:

with self; rec {
  dnsupdate = callPackage ./dnsupdate/default.nix {
    inherit (python3Packages) buildPythonApplication requests pyyaml beautifulsoup4;
  };
  
  muximux = callPackage ./muximux/default.nix {};
  
  tinyssh = callPackage ./tinyssh/default.nix {};
  
  tinyssh-convert = callPackage ./tinyssh-convert/default.nix {};

  sanoid = callPackage ./sanoid/default.nix {
    inherit ConfigIniFiles;
    mbufferSupport = true;
    pvSupport = true;
    lzoSupport = true;
    gzipSupport = true;
    parallelGzipSupport = true;
  };

  ConfigIniFiles = with perlPackages; buildPerlModule rec {
    name = "Config-IniFiles-2.94";
    src = fetchurl {
      url = "mirror://cpan/authors/id/S/SH/SHLOMIF/${name}.tar.gz";
      sha256 = "1d4la72fpsf61hcpslmn03ajm5rfy8hm50piqmsfi7d7dm0qmlyn";
    };
    propagatedBuildInputs = [ IOStringy ];
    meta = {
      description = "A module for reading and writing .ini-style configuration files";
      homepage = https://github.com/shlomif/perl-Config-IniFiles;
      license = [ stdenv.lib.licenses.gpl2 ];
    };
  };
}
