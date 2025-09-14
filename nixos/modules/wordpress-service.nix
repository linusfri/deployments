{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.linusfri.wordpress;
  
  phpFpmSettings = import ../settings/phpfpm-settings.nix;

  inherit (config.terraflake.input) node;

  nginxUser = config.services.nginx.user;

  createEnvironment = pkgs.writeShellScriptBin "create-environment" ''
    ${createEnvFile}/bin/create-env-file

    # Creates a .envrc file for direnv to excecute for correct shell environment
    cat <<EOF > "${cfg.home}/.envrc"
    input="${cfg.home}/.env"
    while read -r line
    do
      # If we encounter a blank line, continue
      [[ -z "\$line" ]] && continue

      KEY=\$(echo "\$line" | cut -d "=" -f 1)
      VALUE=\$(echo "\$line" | cut -d "=" -f 2)
      export "\$KEY"="\$VALUE"
    done < "\$input"
    EOF

    # Edits .zshrc add direnv configuration hook only if it doesn't exist
    grep -qxF 'eval "$(direnv hook zsh)"' ${cfg.home}/.zshrc || echo 'eval "$(direnv hook zsh)"' >> ${cfg.home}/.zshrc
  '';

  createEnvFile = pkgs.writeShellScriptBin "create-env-file" ''
    cat ${config.age.secrets."${cfg.appName}-env".path} > ${cfg.home}/.env

    # Concatinates public envs to secret part
    cat <<EOF >> ${cfg.home}/.env
    WP_DEBUG_DISPLAY=${toString cfg.debug.display}
    WP_ENV=${cfg.environment}
    WP_DEBUG=${toString cfg.debug.enabled}
    DB_USER=${cfg.user}
    DB_NAME=${cfg.dbName}
    DB_PASSWORD="" # Wp cli commands complain otherwise
    DB_PREFIX=${cfg.dbPrefix}
    WP_DEBUG_LOG=/var/log/debug-wp.log
    WP_HOME=https://${cfg.domain}
    WP_SITEURL=https://${cfg.domain}/wp
    CONTENT_PATH=${cfg.home}
    FS_METHOD=direct
    WP_REDIS_PATH=${config.services.redis.servers.${cfg.user}.unixSocket}
    WP_REDIS_PORT=0
    WP_REDIS_HOST=localhost
    WP_REDIS_SCHEME=unix
    WP_REDIS_DISABLE_DROPIN_CHECK=true
    WP_REDIS_DISABLE_DROPIN_AUTOUPDATE=true
    EOF
  '';

  setupContentDir = pkgs.writeShellScriptBin "setup-content-dir" ''
    PATH=${lib.makeBinPath [ pkgs.rsync ]}:$PATH
    CONTENT_DIR="${cfg.home}/content"
    TMP_CONTENT="/tmp/${cfg.user}-content"

    mkdir -p "$CONTENT_DIR"

    # Creates .env file and configures direnv
    ${createEnvironment}/bin/create-environment

    # Creates wp-cli.yml to be able to use wp cli
    cat <<EOF > "${cfg.home}/wp-cli.yml"
      path: ${cfg.package}/share/php/${cfg.projectDir}/public/wp
    EOF

    # Temp folder for intermediate storage
    mkdir -p "$TMP_CONTENT"
    rsync -r ${cfg.package}/share/php/${cfg.projectDir}/packages/ "$TMP_CONTENT"
    rsync -r ${cfg.package}/share/php/${cfg.projectDir}/public/content/ "$TMP_CONTENT"

    # Sync persistant content with repo content
    rsync -r --delete --exclude "uploads" "$TMP_CONTENT/" "$CONTENT_DIR"

    rm -rf "$TMP_CONTENT"
    chown -R ${cfg.user}:${cfg.user} "${cfg.home}"
    chmod -R 755 "$CONTENT_DIR"
  '';

  setupCache = pkgs.writeShellScriptBin "set-up-cache" ''
    PATH=${lib.makeBinPath [ pkgs.rsync ]}:$PATH

    # SET UP OBJECT CACHE
    PUBLIC_CONTENT=${cfg.package}/share/php/${cfg.projectDir}/public/content

    # Copy object cache file to make redis work with DISALLOW_FILE_[MODS|EDIT]=true
    # Redis plugin deletes this file if inactivated in Admin. Don't do it.
    if [[ -d $PUBLIC_CONTENT/plugins/redis-cache ]]; then
      rsync -vL $PUBLIC_CONTENT/plugins/redis-cache/includes/object-cache.php ${cfg.home}/content/
    fi

    chown ${cfg.user}:${cfg.user} ${cfg.home}/content/object-cache.php

    # SET UP PAGE CACHE DIRECTORY FOR FASTCGI CACHE
    mkdir -p /var/run/nginx-cache/${cfg.appName}
    chown -R ${nginxUser}:${nginxUser} /var/run/nginx-cache/${cfg.appName}

    # Don't do this. Find a better way instead of allowing all with 777
    chmod -R 777 /var/run/nginx-cache/${cfg.appName}
  '';
in
{
  options.services.linusfri.wordpress = {
    enable = mkEnableOption "WordPress service";

    appName = mkOption {
      type = types.str;
      description = "Application name";
    };

    package = mkOption {
      type = types.package;
      description = "WordPress package to use";
    };

    user = mkOption {
      type = types.str;
      description = "User to run WordPress as";
    };

    home = mkOption {
      type = types.path;
      description = "Home directory for the WordPress user";
    };

    domain = mkOption {
      type = types.str;
      description = "Domain name for the WordPress site";
    };

    dbName = mkOption {
      type = types.str;
      description = "Database name";
    };

    dbPrefix = mkOption {
      type = types.str;
      default = "wp_";
      description = "Database table prefix";
    };

    projectDir = mkOption {
      type = types.str;
      description = "Project directory name within the package";
    };

    environment = mkOption {
      type = types.enum [ "development" "staging" "production" ];
      default = "production";
      description = "WordPress environment";
    };

    debug = {
      enabled = mkOption {
        type = types.bool;
        default = false;
        description = "Enable WordPress debugging";
      };

      display = mkOption {
        type = types.bool;
        default = false;
        description = "Display debug output";
      };
    };

    ssl = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable ACME SSL certificates";
      };

      force = mkOption {
        type = types.bool;
        default = true;
        description = "Force SSL redirect";
      };
    };

    basicAuth = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable basic authentication";
      };
    };

    assetProxy = mkOption {
      type = types.str;
      default = "";
      description = "Asset proxy URL for production assets";
    };
  };

  config = mkIf cfg.enable {
    users.users.${cfg.user} = {
      name = cfg.user;
      group = cfg.user;
      extraGroups = [ "wheel" ];
      home = cfg.home;
      createHome = true;
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICGavKgHzlln0r9APH/vyVQ5uGB+BXR6ybHoiAdLS+DY linus@nixos"
      ];
    };

    users.groups."${cfg.user}" = {
      name = cfg.user;
    };

    services.mysql = {
      initialDatabases = [ { name = "${cfg.dbName}"; } ];
      ensureDatabases = [ cfg.dbName ];
      ensureUsers = [
        {
          name = cfg.user;
          ensurePermissions = {
            "${cfg.dbName}.*" = "ALL PRIVILEGES";
          };
        }
      ];
    };

    services.redis = {
      servers = {
        ${cfg.user} = {
          enable = true;
          user = cfg.user;
          group = cfg.user;
          port = 0; # Listen only on unix socket
          unixSocket = "/run/redis-${cfg.user}/redis.sock";
        };
      };
    };

    services.phpfpm.pools.${cfg.user} = {
      user = cfg.user;
      settings = phpFpmSettings // {
        "listen.owner" = config.services.nginx.user;
        "access.log" = "/var/log/${cfg.user}-phpfpm-access.log";
      };
      phpOptions = ''
        error_log = /var/log/php-error.log
        error_reporting = -1
        log_errors = On
        log_errors_max_len = 0
      '';
      phpEnv = {
        PATH = lib.makeBinPath [ pkgs.php ];
        ENV_FILE_PATH = "/var/lib/${cfg.user}";
      };
    };

    services.nginx = {
      appendHttpConfig = ''
        fastcgi_cache_path /var/run/nginx-cache/${cfg.appName} levels=1:2 keys_zone=${cfg.appName}:100m inactive=45m;
      '';
      virtualHosts."${cfg.domain}" = {
        enableACME = cfg.ssl.enable;
        forceSSL = cfg.ssl.force;
        root = "${cfg.package}/share/php/${cfg.projectDir}/public";
        basicAuth = mkIf cfg.basicAuth.enable {
          ${cfg.user} = cfg.user;
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
          fastcgi_cache ${cfg.appName};
          fastcgi_cache_key "$scheme$request_method$host$request_uri";
          fastcgi_cache_valid 200 301 302 30m;

          # Add these headers for debugging
          add_header X-Cache-Status $upstream_cache_status;

          # PARAMS
          fastcgi_pass unix:${config.services.phpfpm.pools.${cfg.user}.socket};
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
          fastcgi_cache_purge ${cfg.appName} "$scheme$request_method$host$1";
        '';

        locations."/content/uploads/".extraConfig = ''
          alias /var/lib/${cfg.user}/content/uploads/;
          try_files $uri @production;
        '';

        locations."@production".extraConfig = ''
          resolver 8.8.8.8;
          proxy_ssl_server_name on;
          proxy_pass ${cfg.assetProxy};
        '';
      };
    };

    systemd.services."${cfg.appName}-setupCache" = {
      description = "Creates object-cache.php in content dir for redis to work. Sets up nginx fastcgi cache";
      serviceConfig = {
        ExecStart = "${setupCache}/bin/set-up-cache";
        Type = "simple";
      };
      wantedBy = [ "multi-user.target" ];
    };

    systemd.services."${cfg.appName}-content-dir" = {
      description = "Copies the project content folder to /var/lib";
      serviceConfig = {
        ExecStart = "${setupContentDir}/bin/setup-content-dir";
        Type = "simple";
      };
      wantedBy = [ "multi-user.target" ];
    };

    age.secrets."${cfg.appName}-env" = {
      rekeyFile = ../${node.name}/secrets/${cfg.appName}-env.age;
    };
  };
}
