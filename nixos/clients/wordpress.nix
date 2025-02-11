{ config, pkgs, ... }:
let
  inherit (config.terraflake.input) node nodes;

  lib = pkgs.lib;
  rsync = pkgs.rsync;

  appName = "wordpress";
  user = "wordpress";
  dbName = "wordpress";
  serverName = "wordpress.friikod.se";
  port = 80;
  sslPort = 443;
  home = "/var/lib/${user}";

  createEnv = pkgs.writeShellScriptBin "create-env" ''
    if [[ ! -d /var/lib/${appName} ]]; then
      mkdir -p /var/lib/${appName}
    fi
  
    cat ${config.age.secrets.wordpress-env.path} > /var/lib/${appName}/.env
  '';

  copyContentDir = pkgs.writeShellScriptBin "copy-content-dir" ''
    CONTENT_DIR="/var/lib/${appName}/content"

    # Do this only the first deploy
    if [[ ! -d "$CONTENT_DIR" ]]; then
      mkdir -p "$CONTENT_DIR"

      ${rsync}/bin/rsync -rv ${pkgs.wordpress-wp}/share/php/wordpress-wp/public/content/ "$CONTENT_DIR"
    fi

    # Do this every following deploy after the first
    ${rsync}/bin/rsync -rv ${pkgs.wordpress-wp}/share/php/wordpress-wp/public/content/plugins/ "$CONTENT_DIR"/plugins
    ${rsync}/bin/rsync -rv ${pkgs.wordpress-wp}/share/php/wordpress-wp/packages/plugins/ "$CONTENT_DIR"/plugins
    ${rsync}/bin/rsync -rv ${pkgs.wordpress-wp}/share/php/wordpress-wp/packages/themes/ "$CONTENT_DIR"/themes
    ${rsync}/bin/rsync -rv ${pkgs.wordpress-wp}/share/php/wordpress-wp/packages/mu-plugins/ "$CONTENT_DIR"/mu-plugins
    ${rsync}/bin/rsync -rv ${pkgs.wordpress-wp}/share/php/wordpress-wp/public/mu-plugins/ "$CONTENT_DIR"/mu-plugins
    ${rsync}/bin/rsync -rv ${pkgs.wordpress-wp}/share/php/wordpress-wp/public/content/languages/ "$CONTENT_DIR"/languages

    chown -R wordpress:wordpress "$CONTENT_DIR"
    chmod -R 755 "$CONTENT_DIR"
  '';
in
{
  users.users.${user} = {
    name = user;
    group = user;
    extraGroups = [ "wheel" ];
    home = home;
    createHome = true;
    isSystemUser = true;
  };

  users.groups."${user}" = {
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

  services.phpfpm.pools.${appName} = {
    inherit user;
    settings = {
      "listen.owner" = config.services.nginx.user;
      "clear_env" = "no";
      "pm" = "dynamic";
      "pm.max_children" = 10;
      "pm.start_servers" = 10;
      "pm.min_spare_servers" = 1;
      "pm.max_spare_servers" = 10;
      "request_terminate_timeout" = 360;
      "access.log" = "/var/log/${user}-phpfpm-access.log";
      "php_flag[display_errors]" = true;
      "php_admin_value[error_log]" = "/var/log/phpfpm-error.log";
      "php_admin_flag[log_errors]" = true;
      "php_value[memory_limit]" = "512M";
      "catch_workers_output" = true;
    };
    phpOptions = ''
      display_errors = on
      error_log = /var/log/phpfpm-error.log
      error_reporting = E_ALL
    '';
    phpEnv = {
      PATH = lib.makeBinPath [ pkgs.php ];
      ENV_FILE_PATH = "/var/lib/${appName}";
      WP_DEBUG = "true";
      WP_ENV = "production";
      WP_DEBUG_DISPLAY = "true";
      DB_USER = "wordpress";
      DB_NAME = "wordpress";
      WP_DEBUG_LOG = "/var/log/debug-wp.log";
      WP_HOME = "https://wordpress.friikod.se";
      WP_SITEURL = "https://wordpress.friikod.se/wp";
      CONTENT_PATH = "/var/lib/${user}";
      FS_METHOD = "direct";
    };
  };

  services.phpfpm.phpOptions = ''
    display_errors = on
    error_log = /var/log/phpfpm-error.log
  '';

  services.nginx = {
    virtualHosts."${node.domains.wordpress-wp}" = {
      enableACME = true;
      forceSSL = true;
      root = "${pkgs.wordpress-wp}/share/php/wordpress-wp/public";
      basicAuth = { wordpress = "wordpress"; };

      locations."/".extraConfig = ''
        index index.php;
        try_files $uri $uri/ /index.php$is_args$args;
      '';

      locations."~ \\.php$".extraConfig = ''
        fastcgi_pass unix:${config.services.phpfpm.pools.${appName}.socket};
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
        fastcgi_param HTTP_HOST $host;
      '';

      locations."/content/uploads/".extraConfig = ''
        alias /var/lib/${appName}/content/uploads/;
        try_files $uri @production;
      '';

      # locations."~* \.(?:jpg|jpeg|gif|pdf|png|webp|ico|cur|gz|svg|mp4|mp3|ogg|ogv|webm|htc)$".extraConfig = ''
      #   expires 1y;
      #   access_log off;
      #   add_header Access-Control-Allow-Origin *;
      #   try_files $uri @production;
      # '';

      locations."@production".extraConfig = ''
        resolver 8.8.8.8;
        proxy_ssl_server_name on;
        proxy_pass https://www.wordpress.se;
      '';
    };
  };

  systemd.services.wordpress-env = {
    description = "Creates an env file";
    serviceConfig = {
      ExecStart = "${createEnv}/bin/create-env";
      Type = "simple";
    };
    wantedBy = [ "multi-user.target" ];
  };

  systemd.services.wordpress-content-dir = {
    description = "Copies the project content folder to /var/lib";
    serviceConfig = {
      ExecStart = "${copyContentDir}/bin/copy-content-dir";
      Type = "simple";
    };
    wantedBy = [ "multi-user.target" ];
  };

  age.secrets.wordpress-env = {
    rekeyFile = ../${node.name}/secrets/wordpress-env.age;
    generator.script = "passphrase";
  };
}