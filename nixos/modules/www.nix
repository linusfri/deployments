{ config, pkgs, ... }:
let
  inherit (config.terraflake.input) node nodes;

  friikodPlaceholder = pkgs.writeTextFile {
    name = "index";
    text = ''
      <h2>Free</h2>
    '';
    executable = false;
    destination = "/src/index.html";
  };
in
{
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.nginx = {
    enable = true;
    virtualHosts = {
      "${node.domains.friikod}" = {
        forceSSL = true;
        enableACME = true;
        locations."/".root = "${friikodPlaceholder}/src";
      };

      "${node.domains.ladugardlive}" = {
        forceSSL = true;
        enableACME = true;
        locations."/".root = pkgs.ladugard-live;
      };
    };
  };
}
