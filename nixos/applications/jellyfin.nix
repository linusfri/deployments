{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (config.terraflake.input) node;
in
{
  services.jellyfin = {
    enable = true;
    openFirewall = true;
    user = "linus";
    group = "linus";
  };

  services.nginx = {
    virtualHosts."${node.domains.jellyfin}" = {
      enableACME = true;
      forceSSL = true;
      extraConfig = ''
        client_max_body_size 20M;
        add_header X-Content-Type-Options "nosniff";
        add_header Content-Security-Policy "default-src https: data: blob: ; img-src 'self' https://* ; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' https://www.gstatic.com https://www.youtube.com blob:; worker-src 'self' blob:; connect-src 'self'; object-src 'none'; frame-ancestors 'self'; font-src 'self'";
        ssl_protocols TLSv1.3 TLSv1.2;
      '';
      locations = {
        "/" = {
          proxyPass = "http://localhost:${toString 8096}";
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Protocol $scheme;
            proxy_set_header X-Forwarded-Host $http_host;
          '';
        };
        "/socket" = {
          proxyPass = "http://localhost:${toString 8096}";
          extraConfig = ''
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Protocol $scheme;
            proxy_set_header X-Forwarded-Host $http_host;
          '';
        };
      };
    };
  };
}
