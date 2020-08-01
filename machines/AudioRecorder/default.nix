{ hostName,
  ap ? false,
  firmwarePartitionID,
  rootPartitionUUID }:

{ lib, config, pkgs, secrets, ... }:

with lib;

{
  imports = [
    ../../modules
    ../../modules/local/machine/raspberry-pi.nix
  ];

  local.machine.raspberryPi.enableWirelessFirmware = true;
  local.profiles.minimal = true;

  sdImage = {
    inherit firmwarePartitionID rootPartitionUUID;
  };

  boot = {
    loader.raspberryPi = {
      enable = true;
      version = 0;
      firmwareConfig = ''
        dtoverlay=fe-pi-audio
        dtparam=audio=off
      '';
    };
    kernelPackages = lib.mkForce pkgs.crossPackages.linuxPackages_rpi0;
    /*kernelPatches = [ {
      name = "i2c-output-source-selection";
      patch = ./0001-ASoC-sgtl5000-add-I2S-output-source-selection.patch;
    } ];*/
  };

  nixpkgs.config = {
    platform = lib.systems.platforms.raspberrypi;
    packageOverrides = super: {
      avahi = super.avahi.overrideAttrs ({
        patches ? [], ...
      }: {
        # Prevent avahi from ever detecting mDNS conflicts. This works around
        # https://github.com/lathiat/avahi/issues/117
        patches = patches ++ [ ./avahi-disable-conflicts.patch ];
      });
    };
  };

  networking.wireless = {
    enable = true;
    interfaces = [ "wlan0" ];
    configFile = secrets.getSystemdSecret "wpa_supplicant" secrets.AudioRecorder.wpaSupplicant."${if ap then "apConf" else "conf"}";
  };
  local.networking.home = {
    enable = true;
    interfaces = [ "wlan0" ];
  };

  # Create virtual AP
  networking.localCommands = mkIf ap ''
    ${pkgs.iw}/bin/iw dev wlan0 interface add ap0 type __ap
  '';
  services.hostapd = mkIf ap {
    enable = true;
    interface = "ap0";
    ssid = "AudioRecorder";
    extraConfig = ''
      wpa=2
      wpa_psk_file=${secrets.getSystemdSecret "hostapd" secrets.AudioRecorder.hostapd.wpaPsk}
    '';
  };
  systemd.services.hostapd = mkIf ap {
    wantedBy = [ "network.target" ];
    before = [ "wpa_supplicant.service" ];
    # Hack to wait before starting wpa_supplicant
    serviceConfig.ExecStartPost = "${pkgs.coreutils}/bin/sleep 5";
  };
  systemd.network = {
    enable = true;
    # Access point
    networks."30-ap0" = {
      name = "ap0";
      address = [ "10.9.0.1/24" ];
      networkConfig = {
        DHCPServer = true;
        IPv6PrefixDelegation = true;
        LLMNR = "yes";
      };
      extraConfig = ''
        [DHCPServer]
        EmitDNS=no
        EmitNTP=no

        [IPv6PrefixDelegation]
        EmitDNS=no
      '';
    };
  };

  networking.hostName = hostName;

  # Allow access to audio devices
  users.users = {
    ben.extraGroups = [ "audio" "audio-recorder" ];
    gary = {
      isNormalUser = true;
      extraGroups = [ "wheel" "audio" "audio-recorder" ];
      uid = 1001;
      hashedPassword = "$6$aC3UnQWVt$y.uMfBSzkcdasHj.aWjtRvqJIRhi3OuervlLcyDiZmsF5rFPClOUTP5NaXdBPhMVLPUAEOIov/6pyTob2r0qx.";
      openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGmfMgjNEt/J4aW+CPj1JQjReapFe4y/NHZqLn9IxFCQ ed25519-key-20180907" ];
    };
  };

  environment.systemPackages = with pkgs; [ sox tmux ];

  # List services that you want to enable:

  services.openssh.hostKeys = [
    { type = "rsa"; bits = 4096; path = secrets.getSecret secrets.AudioRecorder.ssh."${hostName}".hostRsaKey; }
    { type = "ed25519"; path = secrets.getSecret secrets.AudioRecorder.ssh."${hostName}".hostEd25519Key; }
  ];

  services.resolved.llmnr = "true";

  # mDNS
  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      addresses = true;
    };
    nssmdns = true;
  };

  # Time synchronization
  services.chrony = {
    enable = true;
    servers = optional (!ap) "audiorecorder1.local";
    initstepslew = {
      enabled = !ap;
      threshold = 0.1;
      servers = config.services.chrony.servers;
    };
    extraConfig = optionalString ap ''
      local stratum 8
      manual
      allow all
      # Always allow time to be stepped (using settime)
      makestep 1 -1
      # Don't allow any frequency offset (this clock is authoritative)
      maxdrift 0
    '';
  };
  # Don't start on boot except for master
  systemd.services.chronyd = optionalAttrs (!ap) {
    wantedBy = mkForce [];
  };

  # Audio recording service
  sound.enable = true;
  modules.audioRecorder = {
    enable = true;
    devices = map (d: optionalString (d != hostName) "http://${toLower d}.local") [
      "AudioRecorder1"
      "AudioRecorder2"
      "AudioRecorder3"
      "AudioRecorder4"
      "AudioRecorder5"
      "AudioRecorder6"
      "AudioRecorder7"
      "AudioRecorder8"
    ];
    clockMaster = ap;
  };

  # Samba file sharing
  services.samba = {
    enable = true;
    enableWinbindd = false;
    shares.audio = {
      path = "/var/lib/${config.modules.audioRecorder.audioDir}";
      "valid users" = "ben, gary";
      writable = "yes";
    };
    extraConfig = ''
      workgroup = MSHOME
      passdb backend = smbpasswd:${secrets.getSecret secrets.AudioRecorder.samba.smbpasswd}

      # Disable printing
      load printers = no
      printing = bsd
      printcap name = /dev/null
      disable spoolss = yes
    '';
  };

  # Disable HDMI
  systemd.services.disable-hdmi = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.raspberrypi-tools}/bin/tvservice -o";
      ExecStop = "${pkgs.raspberrypi-tools}/bin/tvservice -p";
    };

    description = "Disable HDMI port";
  };

  # Save/restore time
  systemd.services.fake-hwclock = {
    before = [ "sysinit.target" "shutdown.target" ];
    after = [ "local-fs.target" ];
    wantedBy = [ "sysinit.target" ];
    conflicts = [ "shutdown.target" ];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      StateDirectory = "fake-hwclock";
      ExecStart = pkgs.writeScript "fake-hwclock-start" ''
        #!${pkgs.stdenv.shell}

        if [ -e /var/lib/fake-hwclock/clock ]; then
          ${pkgs.coreutils}/bin/date -s "$(cat /var/lib/fake-hwclock/clock)"
        fi
      '';
      ExecStop = pkgs.writeScript "fake-hwclock-stop" ''
        #!${pkgs.stdenv.shell}
        ${pkgs.coreutils}/bin/date > /var/lib/fake-hwclock/clock
      '';
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      34876 # Allow access to audio server for debugging
      139 445 # SMB
      5355 # LLMNR
    ];
    allowedUDPPorts = [
      137 128 # NetBIOS
      5353 # mDNS
      5355 # LLMNR
    ] ++ optionals ap [
      67 # DHCP server
      123 # NTP
    ];
  };

  systemd.secrets = {
    wpa_supplicant = {
      units = [ "wpa_supplicant.service" ];
      files = [ (secrets.mkSecret secrets.AudioRecorder.wpaSupplicant."${if ap then "apConf" else "conf"}" {}) ];
    };
    hostapd = mkIf ap {
      units = [ "hostapd.service" ];
      files = [ (secrets.mkSecret secrets.AudioRecorder.hostapd.wpaPsk {}) ];
    };
  };

  environment.secrets = mkMerge [
    (secrets.mkSecret secrets.AudioRecorder.ssh."${hostName}".hostRsaKey {})
    (secrets.mkSecret secrets.AudioRecorder.ssh."${hostName}".hostEd25519Key {})
    (secrets.mkSecret secrets.AudioRecorder.samba.smbpasswd {})
  ];
}
