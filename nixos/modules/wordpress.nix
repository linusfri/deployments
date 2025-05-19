{
  appName,
  package,
  user,
  dbName,
  dbPrefix,
  home,
  enableBasicAuth ? false,
  projectDir ? appName,
  bankId ? false,
  assetProxy ? "",
}:
{
  config,
  pkgs,
  lib,
  ...
}:
let
  # Send this to derivation to use in build step for composer install
  # caravanclub-wp = pkgs.caravanclub-wp // {
  #   AUTH_JSON = "${config.age.secrets.caravanclub-composerjson}";
  # };

  phpFpmSettings = import ../settings/phpfpm-settings.nix;

  inherit (config.terraflake.input) node nodes;

  nginxUser = config.services.nginx.user;

  setPermissions = pkgs.writeShellScriptBin "set-permissions" ''
    chown -R "${user}:${user}" "$@"
  '';

  setupContentDir = pkgs.writeShellScriptBin "setup-content-dir" ''
    PATH=${lib.makeBinPath [ pkgs.rsync ]}:$PATH
    CONTENT_DIR="${home}/content"

    mkdir -p "$CONTENT_DIR"

    # Creates .env file
    cat ${config.age.secrets."${appName}-env".path} > ${home}/.env

    # Sync persistant content with repo content
    rsync -rv ${package}/share/php/${projectDir}/packages/ "$CONTENT_DIR"
    rsync -rv ${package}/share/php/${projectDir}/public/content/ "$CONTENT_DIR"

    chown -R ${user}:${user} "${home}"
    chmod -R 755 "$CONTENT_DIR"
  '';

  setupCache = pkgs.writeShellScriptBin "set-up-cache" ''
    PATH=${lib.makeBinPath [ pkgs.rsync ]}:$PATH

    # SET UP OBJECT CACHE
    PUBLIC_CONTENT=${package}/share/php/${projectDir}/public/content

    # Copy object cache file to make redis work with DISALLOW_FILE_[MODS|EDIT]=true
    # Redis plugin deletes this file if inactivated in Admin. Don't do it.
    if [[ -d $PUBLIC_CONTENT/plugins/redis-cache ]]; then
      rsync -vL $PUBLIC_CONTENT/plugins/redis-cache/includes/object-cache.php ${home}/content/
    fi

    chown ${user}:${user} ${home}/content/object-cache.php

    # SET UP PAGE CACHE DIRECTORY FOR FASTCGI CACHE
    mkdir -p /var/run/nginx-cache/${appName}
    chown -R ${nginxUser}:${nginxUser} /var/run/nginx-cache/${appName}

    # Don't do this. Find a better way instead of allowing all with 777
    chmod -R 777 /var/run/nginx-cache/${appName}
  '';
in
{
  users.users.${user} = {
    name = user;
    group = user;
    extraGroups = [ "wheel" ];
    home = home;
    createHome = true;
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICGavKgHzlln0r9APH/vyVQ5uGB+BXR6ybHoiAdLS+DY linus@nixos"
    ];
  };

  users.groups."${user}" = {
    name = user;
  };

  services.mysql = {
    initialDatabases = [ { name = "${dbName}"; } ];
    ensureDatabases = [ dbName ];
    ensureUsers = [
      {
        name = user;
        ensurePermissions = {
          "${dbName}.*" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  services.redis = {
    servers = {
      ${user} = {
        enable = true;
        inherit user;
        group = user;
        port = 0; # Listen only on unix socket
        unixSocket = "/run/redis-${user}/redis.sock";
      };
    };
  };

  services.phpfpm.pools.${user} = {
    inherit user;
    settings = phpFpmSettings // {
      "listen.owner" = config.services.nginx.user;
      "access.log" = "/var/log/${user}-phpfpm-access.log";
    };
    phpOptions = ''
      error_log = /var/log/php-error.log
      error_reporting = -1
      log_errors = On
      log_errors_max_len = 0
    '';
    phpEnv = {
      PATH = lib.makeBinPath [ pkgs.php ];
      ENV_FILE_PATH = "/var/lib/${user}";
      WP_DEBUG_DISPLAY = "true";
      WP_ENV = "production";
      WP_DEBUG = "true";
      BANKID_CERTIFICATE_PATH = lib.mkIf (bankId) config.age.secrets."${appName}-bankid-cert".path;
      DB_USER = user;
      DB_NAME = dbName;
      DB_PREFIX = dbPrefix;
      WP_DEBUG_LOG = "/var/log/debug-wp.log";
      WP_HOME = "https://${node.domains.${appName}}";
      WP_SITEURL = "https://${node.domains.${appName}}/wp";
      CONTENT_PATH = home;
      FS_METHOD = "direct";
      WP_REDIS_PATH = config.services.redis.servers.${user}.unixSocket;
      WP_REDIS_PORT = "0";
      WP_REDIS_HOST = "localhost";
      WP_REDIS_SCHEME = "unix";
      WP_REDIS_DISABLE_DROPIN_CHECK = "true";
      WP_REDIS_DISABLE_DROPIN_AUTOUPDATE = "true";
    };
  };

  services.nginx = {
    appendHttpConfig = ''
      fastcgi_cache_path /var/run/nginx-cache/${appName} levels=1:2 keys_zone=${appName}:100m inactive=45m;
    '';
    virtualHosts."${node.domains.${appName}}" = {
      enableACME = true;
      forceSSL = true;
      root = "${package}/share/php/${projectDir}/public";
      basicAuth = lib.mkIf enableBasicAuth {
        ${user} = user;
      };
      extraConfig = ''
        set $skip_cache 0;

        # POST requests and urls with a query string should always go to PHP
        if ($request_method = POST) {
            set $skip_cache 1;
        }   
        if ($query_string != "") {
            set $skip_cache 1;
        }   

        # Don't cache uris containing the following segments
        if ($request_uri ~* "/wp-admin/|/xmlrpc.php|wp-.*.php|/feed/|index.php|sitemap(_index)?.xml") {
            set $skip_cache 1;
        }   

        # Don't use the cache for logged in users or recent commenters
        # We should look into adding a seperate cookie for Admin-users, since this will disable page cache for ALL logged in users.
        if ($http_cookie ~* "comment_author|wordpress_[a-f0-9]+|wp-postpass|wordpress_no_cache|wordpress_logged_in") {
            set $skip_cache 1;
        }

        # Don't use the cache for users with items in their cart
        # Should perhaps look at the boolean value instead of only its presence
        if ($http_cookie ~* "woocommerce_items_in_cart") {
            set $skip_cache 1;
        }
      '';

      locations."/".extraConfig = ''
        index index.php;
        try_files $uri $uri/ /index.php$is_args$args;
      '';

      locations."~ \\.php$".extraConfig = ''
        # CACHE
        fastcgi_cache_bypass $skip_cache;
        fastcgi_no_cache $skip_cache;
        fastcgi_cache ${appName};
        fastcgi_cache_key "$scheme$request_method$host$request_uri";
        fastcgi_cache_valid 200 301 302 30m;

        # Add these headers for debugging
        add_header X-Cache-Status $upstream_cache_status;

        # PARAMS
        fastcgi_pass unix:${config.services.phpfpm.pools.${user}.socket};
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
      '';

      locations."~ /purge(/.*)".extraConfig = ''
        fastcgi_cache_purge ${appName} "$scheme$request_method$host$1";
      '';

      locations."/content/uploads/".extraConfig = ''
        alias /var/lib/${user}/content/uploads/;
        try_files $uri @production;
      '';

      locations."@production".extraConfig = ''
        resolver 8.8.8.8;
        proxy_ssl_server_name on;
        proxy_pass ${assetProxy};
      '';
    };
  };

  systemd.services."${appName}-bankid-cert-perms" = lib.mkIf (bankId) {
    description = "Sets permissions.";
    serviceConfig = {
      ExecStart = ''${setPermissions}/bin/set-permissions ${
        config.age.secrets."${appName}-bankid-cert".path
      }'';
      Type = "simple";
    };
    wantedBy = [ "multi-user.target" ];
  };

  systemd.services."${appName}-setupCache" = {
    description = "Creates object-cache.php in content dir for redis to work. Sets up nginx fastcgi cache";
    serviceConfig = {
      ExecStart = "${setupCache}/bin/set-up-cache";
      Type = "simple";
    };
    wantedBy = [ "multi-user.target" ];
  };

  systemd.services."${appName}-content-dir" = {
    description = "Copies the project content folder to /var/lib";
    serviceConfig = {
      ExecStart = "${setupContentDir}/bin/setup-content-dir";
      Type = "simple";
    };
    wantedBy = [ "multi-user.target" ];
  };

  age.secrets."${appName}-env" = {
    rekeyFile = ../${node.name}/secrets/${appName}-env.age;
  };

  age.secrets."${appName}-bankid-cert" = lib.mkIf (bankId) {
    rekeyFile = ../${node.name}/secrets/${appName}-bankid-cert.age;
    generator.script = "passphrase";
  };

  age.secrets.caravanclub-bankid-cert = {
    rekeyFile = ../${node.name}/secrets/caravanclub-bankid-cert.age;
    generator.script = "passphrase";
  };
}
