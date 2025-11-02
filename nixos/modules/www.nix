{ config, pkgs, ... }:
let
  inherit (config.terraflake.input) node nodes;
in
{
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [
    80
    443
    25
    465
  ];

  services.nginx = {
    package = pkgs.nginx.override {
      modules = [ pkgs.nginxModules.cache-purge ];
    };
    enable = true;
    enableReload = true;
    logError = "stderr";
  };
}
