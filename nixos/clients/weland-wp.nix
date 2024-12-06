{ config, pkgs, ... }:
let
  inherit (config.terraflake.input) node nodes;

  user = "weland";
  dbName = "weland";
  serverName = "weland.friikod.se";
  port = 80;
  sslPort = 443;
  home = "/var/lib/${user}";
in
{
  users.extraUsers.${user} = {
    name = user;
    group = user;
    home = home;
    createHome = true;
    isSystemUser = true;
  };

  users.extraGroups."${user}" = {
    name = user;
  };
  
  services.mysql = {
    initialDatabases = [{ name = "${dbName}"; }];
    ensureDatabases = [dbName];
    ensureUsers = [
      {
        name = user;
        ensurePermissions = {
          "${dbName}.*" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  services.nginx = {
      enable = lib.mkDefault true;
      virtualHosts."${node.domains.weland-wp}" = {
        enableACME = true;
        forceSSL = true;
        root = "${weland-wp}/public";

        locations."~ \\.php$".extraConfig = ''
          fastcgi_pass unix:${config.languages.php.fpm.pools.web.socket};
          fastcgi_index index.php;
          fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
          fastcgi_param QUERY_STRING  $query_string;
          fastcgi_param REQUEST_METHOD  $request_method;
          fastcgi_param CONTENT_TYPE  $content_type;
          fastcgi_param CONTENT_LENGTH  $content_length;
          fastcgi_param SCRIPT_FILENAME  $request_filename;
          fastcgi_param SCRIPT_NAME  $fastcgi_script_name;
          fastcgi_param REQUEST_URI  $request_uri;
          fastcgi_param DOCUMENT_URI  $document_uri;
          fastcgi_param DOCUMENT_ROOT  $document_root;
          fastcgi_param SERVER_PROTOCOL  $server_protocol;
          fastcgi_param GATEWAY_INTERFACE CGI/1.1;
          fastcgi_param SERVER_SOFTWARE  nginx/$nginx_version;
          fastcgi_param REMOTE_ADDR  $remote_addr;
          fastcgi_param REMOTE_PORT  $remote_port;
          fastcgi_param SERVER_ADDR  $server_addr;
          fastcgi_param SERVER_PORT  $server_port;
          fastcgi_param SERVER_NAME  $server_name;
          fastcgi_param HTTPS   $https if_not_empty;
          fastcgi_param REDIRECT_STATUS  200;
          fastcgi_param HTTP_PROXY  "";
          fastcgi_buffer_size 512k;
          fastcgi_buffers 16 512k;
          fastcgi_param HTTP_HOST $host:${toString sslPort};
        '';
      };

      # httpConfig = lib.mkDefault ''
      #   server {
      #     listen ${toString port};
      #     listen ${toString sslPort} ssl;

      #     root ${config.env.DEVENV_ROOT}/${serveDir};
      #     index index.php index.html index.htm;
      #     server_name ${serverName};

      #     error_page 497 https://$server_name:$server_port$request_uri;
      #     client_max_body_size 64m;

      #     location / {
      #       try_files $uri $uri/ /index.php$is_args$args;
      #     }

      #     location ~ \.php$ {
            fastcgi_pass unix:${config.languages.php.fpm.pools.web.socket};
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_param QUERY_STRING  $query_string;
            fastcgi_param REQUEST_METHOD  $request_method;
            fastcgi_param CONTENT_TYPE  $content_type;
            fastcgi_param CONTENT_LENGTH  $content_length;
            fastcgi_param SCRIPT_FILENAME  $request_filename;
            fastcgi_param SCRIPT_NAME  $fastcgi_script_name;
            fastcgi_param REQUEST_URI  $request_uri;
            fastcgi_param DOCUMENT_URI  $document_uri;
            fastcgi_param DOCUMENT_ROOT  $document_root;
            fastcgi_param SERVER_PROTOCOL  $server_protocol;
            fastcgi_param GATEWAY_INTERFACE CGI/1.1;
            fastcgi_param SERVER_SOFTWARE  nginx/$nginx_version;
            fastcgi_param REMOTE_ADDR  $remote_addr;
            fastcgi_param REMOTE_PORT  $remote_port;
            fastcgi_param SERVER_ADDR  $server_addr;
            fastcgi_param SERVER_PORT  $server_port;
            fastcgi_param SERVER_NAME  $server_name;
            fastcgi_param HTTPS   $https if_not_empty;
            fastcgi_param REDIRECT_STATUS  200;
            fastcgi_param HTTP_PROXY  "";
            fastcgi_buffer_size 512k;
            fastcgi_buffers 16 512k;
            fastcgi_param HTTP_HOST $host:${toString sslPort};
      #     }
      #   }
      # '';
    };

  # services.nginx = {
  #   virtualHosts."${node.domains.weland-wp}" = {
  #     enableACME = true;
  #     forceSSL = true;
  #     locations."/" = {
  #       proxyPass = "http://localhost:8080";
  #     };
  #   };
  # };
}