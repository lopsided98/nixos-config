{ config, lib, pkgs, secrets, ... }:

with lib;

let
  net = config.lib.net;
  cfg = config.local.networking.vpn.home.amneziawg;
in {

  # Interface

  options.local.networking.vpn.home.amneziawg.server = {
    enable = mkEnableOption "home network WireGuard server";

    interface = mkOption {
      type = types.str;
      description = "AmneziaWG network interface name";
      default = "awg0";
    };

    port = mkOption {
      type = types.int;
      description = "UDP port to listen on";
      default = 4297;
      readOnly = true;
    };

    ipv4Address = mkOption {
      type = net.types.ipv4;
      description = "IPv4 address assigned to AmneziaWG interface";
      readOnly = true;
    };

    ipv6Address = mkOption {
      type = net.types.ipv6;
      description = "IPv6 address assigned to AmneziaWG interface";
      readOnly = true;
    };

    privateKeySecret = mkOption {
      type = types.str;
      description = "Server private key secret";
    };
  };

  # Implementation

  config = mkMerge [
    {
      local.networking.vpn.home.amneziawg.server = {
        ipv4Address = net.cidr.host 1 cfg.ipv4Subnet;
        ipv6Address = net.cidr.host 1 cfg.ipv6Prefix;
      };
    }
    (mkIf cfg.server.enable {
      networking.wg-quick.interfaces.${cfg.server.interface} = {
        type = "amneziawg";
        listenPort = cfg.server.port;
        address = [
          "${cfg.server.ipv4Address}/${toString (net.cidr.length cfg.ipv4Subnet)}"
          "${cfg.server.ipv6Address}/${toString (net.cidr.length cfg.ipv6Prefix)}"
        ];
        privateKeyFile = secrets.getSystemdSecret "vpn-home-amneziawg-server" cfg.server.privateKeySecret;
        peers = mapAttrsToList (publicKey: peerCfg: {
          allowedIPs = [
            peerCfg.ipv4Address
            peerCfg.ipv6Address
          ];
          publicKey = publicKey;
        }) cfg.peers;

        # Generated using script from:
        # https://community.hetzner.com/tutorials/making-website-accessible-from-restricted-regions
        extraOptions = {
          Jc = 6;
          Jmin = 79;
          Jmax = 296;
          S1 = 33;
          S2 = 33;
          S3 = 18;
          S4 = 7;
          H1 = "604080000-604180000";
          H2 = "1020760000-1020860000";
          H3 = "2197640000-2197740000";
          H4 = "3358320000-3358420000";
          I1 = "<b 0x5245474953544552207369703a676f6f676c652e636f6d205349502f322e300d0a5669613a205349502f322e302f554450203139322e3136382e3139302e36393a353036303b6272616e63683d7a39684734624b6539333234666138323366373037626238316133303731650d0a4d61782d466f7277617264733a2037300d0a546f3a203c7369703a7573657240676f6f676c652e636f6d3e0d0a46726f6d3a203c7369703a7573657240676f6f676c652e636f6d3e3b7461673d633263306265376538613737306531630d0a43616c6c2d49443a2064356164323436343062643137353264383436376632323466306132306234320d0a435365713a20312052454749535445520d0a436f6e746163743a203c7369703a75736572403139322e3136382e3138382e3138303a353036303e0d0a557365722d4167656e743a204d6963726f5349502f332e302e300d0a457870697265733a20363332390d0a436f6e74656e742d4c656e6774683a20300d0a0d0a>";
          I2 = "<b 0x16030300610100005d0303d995291fa816c9595ff913e584fb8ec77d96ea574493592a1c4f3196c8a8006d08cb0dde5cbdcb06bc000213020100002a0000000f00000d00000a676f6f676c652e636f6d000b000403000102000a000a00082e256359f8e88f01>";
          I3 = "<b 0x160303002f0200002b03039bb8f96eb6d3f3cbd08554d018cffc13e7c97cd4f2f931cbe0aa3f7b9d5be456039267fd1303000000>";
          I4 = "<b 0x10000080e706947c9aaee3ddc6f8a2284fe0246fcd33a9f73f4e76f037bdce5aefc6d25d0b282526104ae29197f15222a2f765bc090e4e831f0f8d8b7ef46ec795242350dea3724d4870bc4f9ad2ec8579d7878c8f6eb8547e3ffb8ca58044335e20d738cf8cbc192bfbacdaa974660ca4796c5149d598d06cf1504e65e93fc982c0e0201403030001011603030034d25ef0bbf310470d943dcefe6d240da16b21a42f577140fb3e243e80224c228583f367a87e1cdab550d93ad98ed3e9cc7757a28f>";
          I5 = "<b 0x17030301a2504f5354202f70686f746f7320485454502f312e310d0a486f73743a20796f75747562652e636f6d0d0a557365722d4167656e743a204d6f7a696c6c612f352e30202857696e646f7773204e542031302e303b2057696e36343b2078363429204170706c655765624b69742f3533372e333620284b48544d4c2c206c696b65204765636b6f29204368726f6d652f39312e302e343437322e313234205361666172692f3533372e33360d0a4163636570743a20746578742f68746d6c2c6170706c69636174696f6e2f7868746d6c2b786d6c2c6170706c69636174696f6e2f786d6c3b713d302e392c696d6167652f776562702c2a2f2a3b713d302e380d0a4163636570742d4c616e67756167653a20656e2d55532c656e3b713d302e350d0a4163636570742d456e636f64696e673a20677a69702c206465666c6174652c2062720d0a436f6e6e656374696f6e3a206b6565702d616c6976650d0a436f6e74656e742d547970653a206170706c69636174696f6e2f782d7777772d666f726d2d75726c656e636f6465640d0a436f6e74656e742d4c656e6774683a20300d0a0d0a>";
        };

        postUp = ''
          ${pkgs.procps}/bin/sysctl -w net.ipv4.ip_forward=1
          ${pkgs.procps}/bin/sysctl -w net.ipv6.conf.${cfg.server.interface}.forwarding=1
        '';
      };

      networking.firewall.allowedUDPPorts = [ cfg.server.port ];

      systemd.secrets.vpn-home-amneziawg-server = {
        files = secrets.mkSecret cfg.server.privateKeySecret { };
        units = [ "wg-quick-${cfg.server.interface}.service" ];
      };
    })
  ];
}
