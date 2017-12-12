
{ packages ? ../.., supportedSystems ? ["x86_64-linux" "armv7l-linux" ] }:
let
  localPkgs = (import "${packages}/pkgs/packages.nix" );
in
with (import ./release-lib.nix { 
  inherit supportedSystems; 
  overlay = localPkgs;
});
let
  jobs = {
    inherit (localPkgs) 
      dnsupdate
      aur-buildbot
      pacman
      muximux
      tinyssh
      tinyssh-convert
      sanoid;

    perlPackages = {
      inherit (localPkgs.perlPackages)
        ConfigIniFiles;
    };
    
    linuxPackages_latest = {
      inherit (localPkgs.linuxPackages_latest)
        tmon;
    };
    
    linuxPackages_4_13 = {
      inherit (localPkgs.linuxPackages_4_13)
        tmon;
    };

  } // mapTestOn {

    # Fancy shortcut to generate one attribute per supported platform.
    dnsupdate = supportedSystems;
    aur-buildbot = supportedSystems;
    pacman = supportedSystems;
    muximux = supportedSystems;
    tinyssh = supportedSystems;
    tinyssh-convert = supportedSystems;
    sanoid = supportedSystems;
    
    perlPackages = {
      ConfigIniFiles = supportedSystems;
    };

    linuxPackages_latest = {
      tmon = supportedSystems;
    };
    
    linuxPackages_4_13 = {
      tmon = supportedSystems;
    };
   
  };
in jobs // (let
  systemChannel = system: pkgs.releaseTools.channel {
    constituents = lib.catAttrs system (lib.attrValues jobs);
    name = "localpkgs-${system}";
    src = ./.;
  };
in {
  channels = lib.genAttrs supportedSystems systemChannel;
})
