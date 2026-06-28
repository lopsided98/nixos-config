{
  lib,
  config,
  pkgs,
  secrets,
  ...
}:

with lib;

let
  kernel = pkgs.linuxManualConfig rec {
    pname = "linux-omnitech";
    version = "5.8.1";

    # branch needs to be x.y
    extraMeta.branch = lib.versions.majorMinor version;

    src = pkgs.fetchFromGitHub {
      name = "${pname}-${version}-source";
      owner = "lopsided98";
      repo = "linux";
      rev = "240dd1417e114c041e92adc126d90fbb73bc28b4";
      sha256 = "1gj6if3535ndfdaa44l3jyc9r5yxymmbxcsj3h73x0220jlg6qfn";
    };

    kernelPatches = with pkgs.kernelPatches; [
      bridge_stp_helper
      request_key_helper
    ];

    configfile = ./kernel.config;
    config = import ./kernel-config.nix;
  };
in
{
  imports = [ ../../modules ];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/6ead6662-dcfb-4427-a45b-57018f86b3c5";
      fsType = "ext4";
    };
    "/boot/firmware" = {
      device = "/dev/disk/by-uuid/3FF8-9E69";
      fsType = "vfat";
      options = [
        "nofail"
        "noauto"
        "x-systemd.automount"
      ];
    };
  };

  local.profiles.limitedMemory = true;

  local.system = {
    hostSystem = {
      config = "armv5tel-unknown-linux-gnueabi";
      gcc = {
        arch = "armv5te";
        float-abi = "soft";
        tune = "arm926ej-s";
      };
    };
    # Enable cross-compilation
    buildSystem.system = "x86_64-linux";
  };

  boot = {
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
    kernelPackages = lib.mkForce (pkgs.linuxPackagesFor kernel);
  };
  # Ignore broken kernel config assertions
  system.requiredKernelConfig = mkForce [ ];

  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom="US"
  '';
  hardware.firmware = [
    pkgs.wireless-regdb
    (pkgs.runCommand "mt7610u-firmware" { } ''
      mkdir -p "$out/lib/firmware/mediatek"
      cp '${pkgs.linux-firmware}'/lib/firmware/mediatek/mt7610?.bin "$out/lib/firmware/mediatek"
    '')
  ];

  /*
    local.networking.wireless.home = {
      enable = true;
      interfaces = [ "wlan0" ];
    };
  */

  networking.hostName = "omnitech";

  # Services to enable

  services.openssh = {
    hostKeys = [
      {
        type = "rsa";
        bits = 4096;
        path = secrets.getSystemdSecret "sshd" secrets.omnitech.ssh.hostRsaKey;
      }
      {
        type = "ed25519";
        path = secrets.getSystemdSecret "sshd" secrets.omnitech.ssh.hostEd25519Key;
      }
    ];
  };

  services.fakeHwClock.enable = true;

  systemd.secrets.sshd = {
    units = [ "sshd@.service" ];
    # Prevent first connection from failing due to decryption taking too long
    lazy = false;
    files = mkMerge [
      (secrets.mkSecret secrets.omnitech.ssh.hostRsaKey { })
      (secrets.mkSecret secrets.omnitech.ssh.hostEd25519Key { })
    ];
  };
}
