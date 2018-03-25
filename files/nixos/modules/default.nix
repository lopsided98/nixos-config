{ ... }: {
  imports = [
    # Automatically apply common configuration
    ./config/common.nix
  
    ./system/build-machines.nix
    ./system/secrets/secrets.nix
    ./system/boot/initrd-tinyssh.nix
    ./system/boot/initrd-decryptssh.nix
    ./services/backup/sanoid.nix
    ./services/backup/syncoid.nix
    ./services/continuous-integration/aur-buildbot/worker.nix
    ./services/continuous-integration/aur-buildbot/master.nix
    ./services/networking/dnsupdate.nix
    ./services/networking/openvpn/openvpn-client-home-network.nix
  ];
}
