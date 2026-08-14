{ config, lib, pkgs, secrets, ... }:

with lib;

let
  net = config.lib.net;
  cfg = config.local.networking.vpn.home.wireGuard;

  privateKeyFile = secrets.getSystemdSecret "vpn-home-wireguard-server" cfg.server.privateKeySecret;

  wireguardFwMark = 52998;
  amneziawgFwMark = 52999;
  wireguardTable = 52998;
  amneziawgTable = 52999;
in {

  # Interface

  options.local.networking.vpn.home.wireGuard.server = {
    enable = mkEnableOption "home network WireGuard server";

    interface = mkOption {
      type = types.str;
      description = "VPN network interface name";
      default = "wg0";
    };

    uplinkInterface = mkOption {
      type = types.str;
      description = "Network interface that delegates the IPv6 prefix";
    };

    port = mkOption {
      type = types.int;
      description = "UDP port to listen on";
      default = 4296;
      readOnly = true;
    };

    ipv4Address = mkOption {
      type = net.types.ipv4;
      description = "IPv4 address assigned to WireGuard interface";
      readOnly = true;
    };

    ipv6Address = mkOption {
      type = net.types.ipv6;
      description = "IPv6 address assigned to WireGuard interface";
      readOnly = true;
    };

    privateKeySecret = mkOption {
      type = types.str;
      description = "Server private key secret";
    };

    amneziawg = {
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
    };
  };

  # Implementation

  config = mkMerge [
    {
      local.networking.vpn.home.wireGuard.server = {
        ipv4Address = net.cidr.host 1 cfg.ipv4Subnet;
        ipv6Address = net.cidr.host 1 cfg.ipv6Prefix;
        amneziawg = {
          ipv4Address = net.cidr.host 254 cfg.ipv4Subnet;
          ipv6Address = net.cidr.host 254 cfg.ipv6Prefix;
        };
      };
    }
    (mkIf cfg.server.enable {
      systemd.network = {
        netdevs."30-vpn-home-wireguard-server" = {
          netdevConfig = {
            Name = cfg.server.interface;
            Kind = "wireguard";
            MTUBytes = "1392";
          };

          wireguardConfig = {
            ListenPort = toString cfg.server.port;
            PrivateKeyFile = privateKeyFile;
          };

          wireguardPeers = mapAttrsToList (publicKey: peerCfg: {
            AllowedIPs = [
              peerCfg.ipv4Address
              peerCfg.ipv6Address
            ];
            PublicKey = publicKey;
          }) cfg.peers;
        };

        networks."30-vpn-home-wireguard-server" = {
          name = cfg.server.interface;
          address = [
            # No subnet to avoid the default subnet route in the main table. We
            # add it manually to a different table below.
            "${cfg.server.ipv4Address}/32"
            "${cfg.server.ipv6Address}/128"
          ];
          networkConfig = {
            IPv6AcceptRA = false;
            DHCPPrefixDelegation = true;
            IPv4Forwarding = true;
            # Doesn't actually control forwarding and probably doesn't matter if
            # we set it, but it doesn't hurt.
            # See: https://tldp.org/HOWTO/Linux+IPv6-HOWTO/ch11s02.html
            IPv6Forwarding = true;
          };
          dhcpPrefixDelegationConfig = {
            SubnetId = 0;
            Assign = false;
          };
          routes = [
            {
              Destination = "${cfg.ipv4Subnet}";
              Scope = "link";
              Table = wireguardTable;
            }
            {
              Destination = "${cfg.ipv6Prefix}";
              Scope = "link";
              Table = wireguardTable;
            }
          ];
          routingPolicyRules = [
            {
              Table = wireguardTable;
              FirewallMark = wireguardFwMark;
              Family = "both";
            }
            {
              Table = amneziawgTable;
              FirewallMark = amneziawgFwMark;
              Family = "both";
            }
          ];
        };

        # Enables forwarding globally. Linux has no per-interface setting; you
        # are supposed to use the firewall.
        config.networkConfig.IPv6Forwarding = true;
      };

      networking.wg-quick.interfaces.${cfg.server.amneziawg.interface} = {
        type = "amneziawg";
        listenPort = cfg.server.amneziawg.port;
        address = [
          # No subnet to avoid the default subnet route in the main table.
          # wg-quick adds individual routes for each peer in the specified
          # table.
          "${cfg.server.amneziawg.ipv4Address}/32"
          "${cfg.server.amneziawg.ipv6Address}/128"
        ];
        privateKeyFile = secrets.getSystemdSecret "vpn-home-amneziawg-server" cfg.server.privateKeySecret;
        peers = mapAttrsToList (publicKey: peerCfg: {
          allowedIPs = [
            peerCfg.ipv4Address
            peerCfg.ipv6Address
          ];
          publicKey = publicKey;
        }) cfg.peers;
        table = builtins.toString amneziawgTable;

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
          ${pkgs.procps}/bin/sysctl -w net.ipv6.conf.${cfg.server.amneziawg.interface}.forwarding=1
        '';
      };

      networking.nftables.enable = true;

      systemd.services.vpn-home-wireguard-client-router = let
        bpfSource = pkgs.writeText "client_router.c" ''
          #include <linux/bpf.h>
          #include <linux/pkt_cls.h>
          #include <linux/if_ether.h>
          #include <linux/ip.h>
          #include <linux/ipv6.h>
          #include <bpf/bpf_helpers.h>
          #include <bpf/bpf_endian.h>

          // Maps to store the interface state
          struct {
              __uint(type, BPF_MAP_TYPE_HASH);
              __uint(max_entries, 256);
              __type(key, __u32);
              __type(value, __u32);
          } ipv4_map SEC(".maps");

          struct {
              __uint(type, BPF_MAP_TYPE_HASH);
              __uint(max_entries, 256);
              __type(key, struct in6_addr);
              __type(value, __u32);
          } ipv6_map SEC(".maps");

          // Helper for L3 (Layer 3) ingress tracking on wg0 and awg0
          static int track_client(struct __sk_buff *skb, __u32 mark) {
              void *data_end = (void *)(long)skb->data_end;
              void *data = (void *)(long)skb->data;

              // WireGuard/AmneziaWG are L3 devices; data points directly to the IP header
              if (skb->protocol == bpf_htons(ETH_P_IP)) {
                  struct iphdr *ip = data;
                  if ((void *)(ip + 1) > data_end) return TC_ACT_OK;

                  __u32 src_ip = ip->saddr;
                  bpf_map_update_elem(&ipv4_map, &src_ip, &mark, BPF_ANY);
                  bpf_printk("update: %08x -> %u", bpf_ntohl(src_ip), mark);
              } else if (skb->protocol == bpf_htons(ETH_P_IPV6)) {
                  struct ipv6hdr *ipv6 = data;
                  if ((void *)(ipv6 + 1) > data_end) return TC_ACT_OK;

                  bpf_map_update_elem(&ipv6_map, &ipv6->saddr, &mark, BPF_ANY);
              }

              // Mark the incoming packet so it passes NixOS rp_filter rules
              skb->mark = mark;
              return TC_ACT_OK;
          }

          SEC("tc/ingress_wireguard")
          int track_wireguard(struct __sk_buff *skb) {
              return track_client(skb, ${builtins.toString wireguardFwMark});
          }

          SEC("tc/ingress_amneziawg")
          int track_amneziawg(struct __sk_buff *skb) {
              return track_client(skb, ${builtins.toString amneziawgFwMark});
          }

          // Helper for L2 (Layer 2) ingress routing on the uplink interface
          SEC("tc/ingress_uplink")
          int route_uplink(struct __sk_buff *skb) {
              void *data_end = (void *)(long)skb->data_end;
              void *data = (void *)(long)skb->data;

              // LAN interfaces are L2 devices; data points to the Ethernet header
              struct ethhdr *eth = data;
              if ((void *)(eth + 1) > data_end) return TC_ACT_OK;

              __u32 *mark_ptr = NULL;

              if (eth->h_proto == bpf_htons(ETH_P_IP)) {
                  struct iphdr *ip = (void *)(eth + 1);
                  if ((void *)(ip + 1) > data_end) return TC_ACT_OK;

                  __u32 dst_ip = ip->daddr;
                  mark_ptr = bpf_map_lookup_elem(&ipv4_map, &dst_ip);
                  if (mark_ptr) {
                    bpf_printk("ingress: %08x -> %u", bpf_ntohl(dst_ip), *mark_ptr);
                  }
              } else if (eth->h_proto == bpf_htons(ETH_P_IPV6)) {
                  struct ipv6hdr *ipv6 = (void *)(eth + 1);
                  if ((void *)(ipv6 + 1) > data_end) return TC_ACT_OK;

                  mark_ptr = bpf_map_lookup_elem(&ipv6_map, &ipv6->daddr);
              }

              // If a mapping exists, apply the mark to route it to the correct VPN interface
              if (mark_ptr) {
                  skb->mark = *mark_ptr;
              }

              return TC_ACT_OK;
          }

          char __license[] SEC("license") = "GPL";
        '';

        bpfProgram = pkgs.runCommand "client_router.o" {
          nativeBuildInputs = [ pkgs.llvmPackages.clang-unwrapped ];
        } ''
          clang -O2 -g -target bpf \
            -isystem '${pkgs.linuxHeaders}/include' \
            -I '${pkgs.libbpf}/include' \
            -c ${bpfSource} -o "$out"
        '';
      in {
        description = "eBPF helper for WireGuard/AmneziaWG roaming";
        # Ensure this runs after the interfaces are created by systemd-networkd and wg-quick
        after = [ "network.target" "systemd-networkd.service" "wg-quick-${cfg.server.amneziawg.interface}.service" ];
        wantedBy = [ "multi-user.target" ];
        path = with pkgs; [ iproute2 bpftools ];
        environment.BPF_DIR = "/sys/fs/bpf/vpn_home_wireguard_client_router";

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };

        script = ''
          # Clean up existing qdiscs to allow the service to be restarted cleanly
          tc qdisc del dev ${cfg.server.interface} clsact 2>/dev/null || true
          tc qdisc del dev ${cfg.server.amneziawg.interface} clsact 2>/dev/null || true
          tc qdisc del dev ${cfg.server.uplinkInterface} clsact 2>/dev/null || true
          rm -rf "$BPF_DIR"

          # Load the BPF program
          mkdir -p "$BPF_DIR"
          bpftool prog loadall ${bpfProgram} "$BPF_DIR" type tc

          # Create clsact qdiscs on the interfaces
          tc qdisc add dev ${cfg.server.interface} clsact
          tc qdisc add dev ${cfg.server.amneziawg.interface} clsact
          tc qdisc add dev ${cfg.server.uplinkInterface} clsact

          # Attach the compiled BPF programs to the ingress hooks
          tc filter add dev ${cfg.server.interface} ingress bpf da object-pinned "$BPF_DIR/track_wireguard"
          tc filter add dev ${cfg.server.amneziawg.interface} ingress bpf da object-pinned "$BPF_DIR/track_amneziawg"
          tc filter add dev ${cfg.server.uplinkInterface} ingress bpf da object-pinned "$BPF_DIR/route_uplink"
        '';

        preStop = ''
          tc qdisc del dev ${cfg.server.interface} clsact 2>/dev/null || true
          tc qdisc del dev ${cfg.server.amneziawg.interface} clsact 2>/dev/null || true
          tc qdisc del dev ${cfg.server.uplinkInterface} clsact 2>/dev/null || true
          rm -rf "$BPF_DIR"
        '';
      };

      local.networking.home.interfaces.${cfg.server.uplinkInterface} = {
        ipv6DelegatedPrefix = cfg.ipv6Prefix;
        ipv4Forwarding = true;
      };

      environment.systemPackages = [ pkgs.wireguard-tools ];

      networking.firewall = {
        # FIXME: Should not be needed, doesn't actually appear to fix any
        # problems. Just included for debugging.
        checkReversePath = "loose";
        logReversePathDrops = true;
        allowedUDPPorts = [ cfg.server.port cfg.server.amneziawg.port ];
      };

      systemd.secrets = {
        vpn-home-wireguard-server = {
          files = secrets.mkSecret cfg.server.privateKeySecret { user = "systemd-network"; };
          units = [ "systemd-networkd.service" ];
        };
        vpn-home-amneziawg-server = {
          files = secrets.mkSecret cfg.server.privateKeySecret { };
          units = [ "wg-quick-${cfg.server.amneziawg.interface}.service" ];
        };
      };
    })
  ];
}
