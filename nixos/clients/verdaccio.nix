{ config, pkgs, ... }:
let
  inherit (config.terraflake.input) node;
  verdaccio-config = pkgs.verdaccio-config;
in
{
  users.users.root.extraGroups = [ "docker" ];
  virtualisation = {
    arion = {
      backend = "docker";
      projects = {
        "app".settings.services."app".service = {
          image = "verdaccio/verdaccio";
          restart = "unless-stopped";
          environment = {
            VERDACCIO_PORT = 4873;
            VERDACCIO_PUBLIC_URL = node.domains.verdaccio;
          };
          ports = [
            "4873:4873"
          ];
          volumes = [
            "/var/lib/verdaccio/storage:/verdaccio/storage"
            "${verdaccio-config}:/verdaccio/config"
            "/var/lib/verdaccio/plugins:/verdaccio/plugins"
          ];
        };
      };
    };
    docker.rootless = {
      enable = true;
      setSocketVariable = true;
    };
    docker.enable = true;
  };

  services.nginx = {
    virtualHosts."${node.domains.verdaccio}" = {
      enableACME = true;
      forceSSL = true;
      locations = {
        "/" = {
          extraConfig = ''
            proxy_pass http://127.0.0.1:4873;
            proxy_set_header Host $host:$server_port;
            proxy_set_header X-Forwarded-For $remote_addr;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
      };
    };
  };
}
