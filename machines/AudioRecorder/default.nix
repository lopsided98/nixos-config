{ device,
  totalDevices ? 16,
  useWm8960 ? device == 8,
  ap ? device == 1 }:

{ lib, config, pkgs, secrets, ... }:

with lib;

let
  hostNamePrefix = "AudioRecorder";
  hostName = hostNamePrefix + toString device;
in {
  imports = [
    ../../modules
    ../../modules/local/machine/raspberry-pi.nix
  ];

  # Enable cross-compilation
  local.system.buildSystem.system = "x86_64-linux";

  local.machine.raspberryPi.enableWirelessFirmware = true;
  local.profiles.minimal = true;

  sdImage = {
    firmwarePartitionID = "0x" + substring 0 8 (builtins.hashString "md5" "firmware" + hostName);
    rootPartitionUUID = let 
      hash = substring 0 32 (builtins.hashString "sha1" "root" + hostName);
      u1 = substring 0 8 hash;
      u2 = substring 8 4 hash;
      u3 = substring 12 4 hash;
      u4 = substring 16 4 hash;
      u5 = substring 20 12 hash;
    in "${u1}-${u2}-${u3}-${u4}-${u5}";
    compressImage = false;
  };

  boot = {
    loader.raspberryPi = {
      enable = true;
      version = 0;
      uboot.enable = true;
    };
    kernelPackages = lib.mkForce pkgs.linuxPackages_rpi0;
    kernelPatches = [
      {
        name = "ASoC-wm8960-enable-mic-bias-network-for-electret-mic";
        patch = ./0001-ASoC-wm8960-enable-mic-bias-network-for-electret-mic.patch;
      }
      {
        name = "ASoC-wm8960-use-sysclk-auto-mode-by-default";
        patch = ./0002-ASoC-wm8960-use-sysclk-auto-mode-by-default.patch;
      }
      {
        name = "ASoC-wm8960-use-sysclk-as-MCLK-if-PLL-is-not-configu";
        patch = ./0003-ASoC-wm8960-use-sysclk-as-MCLK-if-PLL-is-not-configu.patch;
      }
    ];
  };
  hardware.deviceTree = {
    filter = "bcm2708-rpi-zero-w.dtb";
    overlays = singleton (if useWm8960 then {
      name = "wm8960-soundcard";
      dtsFile = ./wm8960-soundcard.dts;
    } else {
      name = "fe-pi-audio";
      dtsFile = ./fe-pi-audio.dts;
    });
  };

  nixpkgs.config.platform = lib.systems.platforms.raspberrypi;

  networking.wireless.networks = {
    # Use same PSK as home network
    AudioRecorder = mkIf (!ap) {
      pskRaw = "ext:HOME_PSK";
    };
    # Make home network higher priority
    Thunderbolt.priority = 2;
  };
  local.networking.wireless.home = {
    enable = true;
    interfaces = [ "wlan0" ];
  };

  services.udev.extraRules = ''
    # Disable power saving (causes network hangs every few seconds)
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="wlan0", RUN+="${pkgs.iw}/bin/iw dev $name set power_save off"
  '' + optionalString ap ''
    # Create virtual AP
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="wlan0", RUN+="${pkgs.iw}/bin/iw dev $name interface add ap0 type __ap"
  '';

  services.hostapd = mkIf ap {
    enable = true;
    interface = "ap0";
    ssid = hostNamePrefix;
    extraConfig = ''
      wpa=2
      wpa_psk_file=${secrets.getSystemdSecret "hostapd" secrets.AudioRecorder.hostapd.wpaPsk}
    '';
  };
  systemd.services.hostapd = mkIf ap {
    wantedBy = [ "network.target" ];
    before = [ "wpa_supplicant-wlan0.service" ];
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
        IPv6SendRA = true;
        LLMNR = true;
        MulticastDNS = true;
      };
      dhcpServerConfig = {
        EmitDNS = false;
        EmitNTP = false;
      };
      ipv6SendRAConfig.EmitDNS = false;
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
    { type = "rsa"; bits = 4096; path = secrets.getSystemdSecret "sshd" secrets.AudioRecorder.ssh."${hostName}".hostRsaKey; }
    { type = "ed25519"; path = secrets.getSystemdSecret "sshd" secrets.AudioRecorder.ssh."${hostName}".hostEd25519Key; }
  ];

  services.resolved.llmnr = "true";

  # Time synchronization
  services.chrony = {
    enable = true;
    servers = optional (!ap) "audiorecorder1.local";
    initstepslew = {
      enabled = !ap;
      threshold = 0.1;
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
  services.zeusAudio = {
    enable = true;
    mixerEnums = [
      (mkIf (!useWm8960) {
        control = "Capture Mux";
        value = "LINE_IN";
      })
    ];
    devices = map (d: optionalString (d != hostName) "http://${toLower d}.local")
      (genList (i: hostNamePrefix + toString (i + 1)) totalDevices);
    clockMaster = ap;
  };

  # Samba file sharing
  services.samba = {
    enable = true;
    enableWinbindd = false;
    shares.audio = {
      path = "/var/lib/${config.services.zeusAudio.audioDir}";
      "valid users" = "ben, gary";
      writable = "yes";
    };
    extraConfig = ''
      workgroup = MSHOME
      passdb backend = smbpasswd:${secrets.getSystemdSecret "samba" secrets.AudioRecorder.samba.smbpasswd}

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
      ExecStart = "${pkgs.libraspberrypi}/bin/tvservice -o";
      ExecStop = "${pkgs.libraspberrypi}/bin/tvservice -p";
    };

    description = "Disable HDMI port";
  };

  # Save/restore time
  services.fakeHwClock.enable = true;

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
    hostapd = mkIf ap {
      units = [ "hostapd.service" ];
      files = secrets.mkSecret secrets.AudioRecorder.hostapd.wpaPsk {};
    };
    sshd = {
      units = [ "sshd@.service" ];
      lazy = false;
      files = mkMerge [
        (secrets.mkSecret secrets.AudioRecorder.ssh."${hostName}".hostRsaKey {})
        (secrets.mkSecret secrets.AudioRecorder.ssh."${hostName}".hostEd25519Key {})
      ];
    };
    samba = {
      units = [ "samba-smbd.service" ];
      files = secrets.mkSecret secrets.AudioRecorder.samba.smbpasswd {};
    };
  };
}
