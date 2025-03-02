{ 
  appName,
  user,
  dbName,
  dbPrefix,
  home,
  assetProxy ? "" 
}:
{ config, pkgs, lib, ... }:
let
  phpFpmSettings = import ../modules/phpfpm-settings.nix;

  inherit (config.terraflake.input) node nodes;

  nginxUser = config.services.nginx.user;

  createEnv = pkgs.writeShellScriptBin "create-env" ''
    if [[ ! -d ${home} ]]; then
      mkdir -p ${home}
    fi

    cat ${config.age.secrets."${appName}-env".path} > ${home}/.env
  '';

  copyContentDir = pkgs.writeShellScriptBin "copy-content-dir" ''
    PATH=${lib.makeBinPath [ pkgs.rsync ]}:$PATH
    CONTENT_DIR="${home}/content"

    mkdir -p "$CONTENT_DIR"

    # Sync persistant content with repo content
    rsync -rv ${pkgs.${appName}}/share/php/${appName}/public/content/ "$CONTENT_DIR"
    rsync -rv ${pkgs.${appName}}/share/php/${appName}/packages/themes/ "$CONTENT_DIR"/themes
    rsync -rv ${pkgs.${appName}}/share/php/${appName}/packages/plugins/ "$CONTENT_DIR"/plugins

    chown -R ${user}:${user} "$CONTENT_DIR"
    chmod -R 755 "$CONTENT_DIR"
  '';

  setupCache = pkgs.writeShellScriptBin "set-up-cache" ''
    PATH=${lib.makeBinPath [ pkgs.rsync ]}:$PATH

    # SET UP OBJECT CACHE
    PUBLIC_CONTENT=${pkgs.${appName}}/share/php/${appName}/public/content

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
    isSystemUser = true;
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
      display_errors = on
      error_log = /var/log/phpfpm-error.log
      error_reporting = E_ALL
    '';
    phpEnv = {
      PATH = lib.makeBinPath [ pkgs.php ];
      ENV_FILE_PATH = "/var/lib/${user}";
      WP_DEBUG_DISPLAY = "true";
      DB_USER = user;
      DB_NAME = user;
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
      root = "${pkgs.${appName}}/share/php/${appName}/public";
      basicAuth = {
        ${appName} = appName;
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
        if ($http_cookie ~* "comment_author|wordpress_[a-f0-9]+|wp-postpass|wordpress_no_cache|wordpress_logged_in") {
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

  systemd.services."${appName}-env" = {
    description = "Creates an env file";
    serviceConfig = {
      ExecStart = "${createEnv}/bin/create-env";
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
      ExecStart = "${copyContentDir}/bin/copy-content-dir";
      Type = "simple";
    };
    wantedBy = [ "multi-user.target" ];
  };

  services.borgbackup.jobs.${appName} = {
    paths = [ "${home}/content/uploads" ];
    encryption.mode = "none";
    environment.BORG_RSH = "ssh -i /old-root/etc/ssh/ssh_host_ed25519_key";
    extraCreateArgs = "--verbose --stats";
    repo = "root@${nodes.vps1.ip}:/root/backup/${appName}";
    compression = "auto,zstd";
    startAt = "daily";
  };

  age.secrets."${appName}-env" = {
    rekeyFile = ../${node.name}/secrets/${appName}-env.age;
    generator.script = "passphrase";
  };
}
