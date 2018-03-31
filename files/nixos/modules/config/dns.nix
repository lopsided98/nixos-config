{ config, lib, ... }: {

# Unbound DNS server
  services.unbound = {
    enable = true;
    allowedAccess = [ "192.168.1.0/24" "2601:18a:0:7829::/64" "172.17.0.0/16" ];
    interfaces = [ "0.0.0.0" "::0" ];
    forwardAddresses = [ "8.8.8.8" ];
    extraConfig = ''
      # Continue server section
        num-threads: 4
        so-reuseport: yes
        prefetch: yes

        local-zone: "benwolsieffer.com" typetransparent
        
        # RasPi2
        local-data: "raspi2.benwolsieffer.com A 192.168.1.2"

        # ODROID-XU4
        local-data: "odroid-xu4.benwolsieffer.com A 192.168.1.3"

        # Dell-Optiplex-780
        local-data: "dell-optiplex-780.benwolsieffer.com A 192.168.1.4"
        
        # HP-Z420
        local-data: "hp-z420.benwolsieffer.com A 192.168.1.5"
        local-data: "arch.benwolsieffer.com A 192.168.1.5"
        local-data: "hydra.benwolsieffer.com A 192.168.1.5"
        local-data: "hackerhats.benwolsieffer.com A 192.168.1.5"
        local-data: "influxdb.benwolsieffer.com A 192.168.1.5"
        local-data: "grafana.benwolsieffer.com A 192.168.1.5"
        
        # Rock64
        local-data: "rock64.benwolsieffer.com A 192.168.1.6"

    remote-control:
      control-enable: no
    '';
  };
}
