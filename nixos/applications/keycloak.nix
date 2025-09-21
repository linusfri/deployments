{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (config.terraflake.input) node;
  domain = node.domains.keycloak;
in
{
  services.keycloak = {
    enable = true;
    database = {
      passwordFile = config.age.secrets.keycloakDbPassFile.path;
    };
    sslCertificate = "${config.security.acme.certs.${domain}.directory}/cert.pem";
    sslCertificateKey = "${config.security.acme.certs.${domain}.directory}/key.pem";
    settings = {
      hostname = "keycloak.friikod.se";
      http-port = 9090;
      https-port = 9443;
      proxy-headers = "xforwarded";
    };
  };

  environment.systemPackages = with pkgs; [
    keycloak
  ];

  services.nginx.virtualHosts."${domain}" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "https://localhost:9443";
      extraConfig = ''
        proxy_set_header X-Forwarded-For $proxy_protocol_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
      '';
    };
  };

  age.secrets."keycloakDbPassFile" = {
    rekeyFile = ../${node.name}/secrets/keycloak-db-pass-file.age;
    generator.script = "passphrase";
  };
}
