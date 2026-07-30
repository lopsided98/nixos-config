final: prev: {
  # Fix amneziawg build with Linux 7.1
  linuxPackages_latest = prev.linuxPackages_latest.extend (lpFinal: lpPrev: {
    amneziawg = lpPrev.amneziawg.overrideAttrs ({ patches ? [], ... }: {
      patches = patches ++ [
        (final.fetchpatch2 {
          name = "amneziawg-ipv6-stub.patch";
          url = "https://github.com/amnezia-vpn/amneziawg-linux-kernel-module/commit/2a764691e22f15770aa1551ecae12c0431dbd651.patch?full_index=1";
          stripLen = 1;
          hash = "sha256-0BcCDBu5XHk1kTrx/24Nwq15n01tCRqnQfBkEvzJmxs=";
        })
      ];
    });
  });

  dnsupdate = final.python3Packages.callPackage ./dnsupdate { };

  hacker-hats = final.callPackage ./hacker-hats {};

  mavlink-router = final.callPackage ./mavlink-router { };

  nixos-secrets = final.python3Packages.callPackage ./nixos-secrets { };

  tinyssh = final.callPackage ./tinyssh {};

  watchdog = final.callPackage ./watchdog { };

  # GPG pulls in huge numbers of graphics libraries by default
  gnupg = prev.gnupg.override { guiSupport = false; };

  rpicam-apps = final.callPackage ./rpicam-apps { };
}
