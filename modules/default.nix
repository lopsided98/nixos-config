{ ... }: {
  imports = [
    # Automatically apply common configuration
    ./config/common

    ./system/build-machines.nix
    ./system/boot/initrd-tinyssh.nix
    ./system/boot/initrd-decryptssh.nix
    ./system/secrets.nix
    ./services/backup/sanoid.nix
    ./services/backup/syncoid.nix
    ./services/backup/syncthing-backup.nix
    ./services/continuous-integration/aur-buildbot/worker.nix
    ./services/continuous-integration/aur-buildbot/master.nix
    ./services/networking/dnsupdate.nix
    ./services/networking/doorman.nix
    ./services/networking/openvpn/client-home-network.nix
    ./services/monitoring/telegraf.nix
    ./tasks/filesystems/zfs.nix

    ../overlays/nixos-secrets/secrets.nix
  ];
}
