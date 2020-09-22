{
  description = "Packages, modules and configurations for my NixOS machines";

  inputs = {
    nixpkgs-unstable-custom.url = "github:lopsided98/nixpkgs/unstable-custom";
    nixpkgs-master-custom.url = "github:lopsided98/nixpkgs/master-custom"
  };

  outputs = { self, nixpkgs-unstable-custom }: {
    nixosConfigurations = import ./machines {
      inherit (nixpkgs-unstable-custom) lib;
      nixpkgs = nixpkgs-unstable-custom;
      hostSystems = [ "x86_64-linux" "aarch64-linux" ];
    };
  };
}
