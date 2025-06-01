{ ... }: {
  imports = [
    # Automatically apply common configuration
    ./config/common

    ./system/build-machines.nix
    ./system/boot/initrd-tinyssh.nix
    ./system/boot/initrd-decryptssh.nix
    ./system/boot/systemd-notify-failed.nix
    ./services/hardware/freefb.nix
    ./services/networking/dnsupdate.nix
    ./services/networking/doorman.nix
    ./services/networking/mavlink-router.nix
    ./services/networking/tinyssh.nix
    ./services/monitoring/watchdog.nix
    ./services/system/fake-hwclock.nix
    ./services/web-apps/hacker-hats.nix
    ./services/web-servers/nginx.nix
    ./tasks/filesystems/zfs.nix

    ./local/networking/home.nix
    ./local/networking/vpn/dartmouth.nix
    ./local/networking/vpn/home/tap-client.nix
    ./local/networking/vpn/home/wireguard
    ./local/networking/vpn/home/wireguard/client.nix
    ./local/networking/vpn/home/wireguard/server.nix
    ./local/networking/wireless
    ./local/networking/wireless/apartment.nix
    ./local/networking/wireless/eduroam
    ./local/networking/wireless/home.nix
    ./local/networking/wireless/thunderbat.nix
    ./local/networking/wireless/xfinitywifi.nix
    ./local/profiles/headless.nix
    ./local/profiles/limited-memory.nix
    ./local/profiles/minimal.nix
    ./local/profiles/standard.nix
    ./local/services/backup/sanoid.nix
    ./local/services/backup/server.nix
    ./local/services/backup/syncthing.nix
    ./local/services/deluge.nix
    ./local/services/mail.nix
    ./local/services/public-files.nix
    ./local/services/radonpy
    ./local/services/rtlamr
    ./local/services/telegraf.nix
    ./local/services/water-level-monitor.nix
    ./local/system.nix
  ];
}
