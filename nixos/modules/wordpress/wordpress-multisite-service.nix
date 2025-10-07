{
  config,
  pkgs,
  lib,
  ...
}:
let
  # DON'T access config here!
  phpFpmSettings = import ../settings/phpfpm-settings.nix;

  # Create site-specific helper scripts
  mkSiteScripts = name: siteCfg: node: nginxUser: secretPath: redisSocket:
    let
      createEnvFile = pkgs.writeShellScriptBin "create-env-file-${name}" ''
        cat ${secretPath} > ${siteCfg.home}/.env

        # Concatinates public envs to secret part
        cat <<EOF >> ${siteCfg.home}/.env
        WP_DEBUG_DISPLAY=${toString siteCfg.debug.display}
        WP_ENV=${siteCfg.environment}
        WP_DEBUG=${toString siteCfg.debug.enabled}
        DB_USER=${siteCfg.user}
        DB_NAME=${siteCfg.dbName}
        DB_PASSWORD="" # Wp cli commands complain otherwise
        DB_PREFIX=${siteCfg.dbPrefix}
        WP_DEBUG_LOG=/var/log/${name}-debug-wp.log
        WP_HOME=https://${siteCfg.domain}
        WP_SITEURL=https://${siteCfg.domain}/wp
        CONTENT_PATH=${siteCfg.home}
        FS_METHOD=direct
        WP_REDIS_PATH=${redisSocket}
        WP_REDIS_PORT=0
        WP_REDIS_HOST=localhost
        WP_REDIS_SCHEME=unix
        WP_REDIS_DISABLE_DROPIN_CHECK=true
        WP_REDIS_DISABLE_DROPIN_AUTOUPDATE=true
        EOF
      '';      createEnvironment = pkgs.writeShellScriptBin "create-environment-${name}" ''
        ${createEnvFile}/bin/create-env-file-${name}

        # Creates a .envrc file for direnv to excecute for correct shell environment
        cat <<EOF > "${siteCfg.home}/.envrc"
        input="${siteCfg.home}/.env"
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
        if [[ ! -f ${siteCfg.home}/.zshrc ]]; then
          touch ${siteCfg.home}/.zshrc
        fi
        grep -qxF 'eval "$(direnv hook zsh)"' ${siteCfg.home}/.zshrc || echo 'eval "$(direnv hook zsh)"' >> ${siteCfg.home}/.zshrc
      '';
    in {
      inherit createEnvironment;

      setupContentDir = pkgs.writeShellScriptBin "setup-content-dir-${name}" ''
        PATH=${lib.makeBinPath [ pkgs.rsync ]}:$PATH
        CONTENT_DIR="${siteCfg.home}/app"
        TMP_CONTENT="/tmp/${siteCfg.user}-app"

        mkdir -p "$CONTENT_DIR"

        # Creates .env file and configures direnv
        ${createEnvironment}/bin/create-environment-${name}

        # Creates wp-cli.yml to be able to use wp cli
        cat <<EOF > "${siteCfg.home}/wp-cli.yml"
          path: ${siteCfg.package}/share/php/${siteCfg.projectDir}/web/wp
        EOF

        # Temp folder for intermediate storage
        mkdir -p "$TMP_CONTENT"
        rsync -r ${siteCfg.package}/share/php/${siteCfg.projectDir}/web/app/ "$TMP_CONTENT"

        # Sync persistant content with repo content
        rsync -r --delete --exclude "uploads" "$TMP_CONTENT/" "$CONTENT_DIR"

        rm -rf "$TMP_CONTENT"
        chown -R ${siteCfg.user}:${siteCfg.user} $CONTENT_DIR
        chmod -R 755 ${siteCfg.home}
      '';

      setupCache = pkgs.writeShellScriptBin "set-up-cache-${name}" ''
        PATH=${lib.makeBinPath [ pkgs.rsync ]}:$PATH

        # SET UP OBJECT CACHE
        PUBLIC_CONTENT=${siteCfg.package}/share/php/${siteCfg.projectDir}/web/app

        # Copy object cache file to make redis work with DISALLOW_FILE_[MODS|EDIT]=true
        # Redis plugin deletes this file if inactivated in Admin. Don't do it.
        if [[ -d $PUBLIC_CONTENT/plugins/redis-cache ]]; then
          rsync -vL $PUBLIC_CONTENT/plugins/redis-cache/includes/object-cache.php ${siteCfg.home}/app/
        fi

        chown ${siteCfg.user}:${siteCfg.user} ${siteCfg.home}/app/object-cache.php

        # SET UP PAGE CACHE DIRECTORY FOR FASTCGI CACHE
        mkdir -p /var/run/nginx-cache/${name}
        chown -R ${nginxUser}:${nginxUser} /var/run/nginx-cache/${name}

        # Don't do this. Find a better way instead of allowing all with 777
        chmod -R 777 /var/run/nginx-cache/${name}
      '';
    };

  # Create configuration for a single site
  mkSiteConfig = name: siteCfg: node: nginxUser: secretPath: redisSocket: phpfpmSocket:
    let
      scripts = mkSiteScripts name siteCfg node nginxUser secretPath redisSocket;
    in {
      users.users.${siteCfg.user} = {
        name = siteCfg.user;
        group = siteCfg.user;
        extraGroups = [ "nginx" ];
        home = siteCfg.home;
        createHome = true;
        isNormalUser = true;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICGavKgHzlln0r9APH/vyVQ5uGB+BXR6ybHoiAdLS+DY linus@nixos"
        ];
      };

      users.groups.${siteCfg.user} = {
        name = siteCfg.user;
      };

      services.mysql = {
        initialDatabases = [ { name = siteCfg.dbName; } ];
        ensureDatabases = [ siteCfg.dbName ];
        ensureUsers = [
          {
            name = siteCfg.user;
            ensurePermissions = {
              "${siteCfg.dbName}.*" = "ALL PRIVILEGES";
            };
          }
        ];
      };

      services.redis.servers.${siteCfg.user} = {
        enable = true;
        user = siteCfg.user;
        group = siteCfg.user;
        port = 0;
        unixSocket = "/run/redis-${siteCfg.user}/redis.sock";
      };

      services.phpfpm.pools.${siteCfg.user} = {
        user = siteCfg.user;
        settings = phpFpmSettings // {
          "listen.owner" = nginxUser;
          "access.log" = "/var/log/${siteCfg.user}-phpfpm-access.log";
        };
        phpOptions = ''
          error_log = /var/log/php-error.log
          error_reporting = -1
          log_errors = On
          log_errors_max_len = 0
        '';
        phpEnv = {
          PATH = lib.makeBinPath [ pkgs.php ];
          ENV_FILE_PATH = siteCfg.home;
        };
      };

      services.nginx = {
        appendHttpConfig = ''
          fastcgi_cache_path /var/run/nginx-cache/${name} levels=1:2 keys_zone=${name}:100m inactive=45m;
        '';

        virtualHosts.${siteCfg.domain} = {
          enableACME = siteCfg.ssl.enable;
          forceSSL = siteCfg.ssl.force;
          root = "${siteCfg.package}/share/php/${siteCfg.projectDir}/web";
          basicAuth = lib.mkIf siteCfg.basicAuth.enable {
            ${siteCfg.user} = siteCfg.user;
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

            # Don't use the cache for users with items in their cart
            if ($http_cookie ~* "woocommerce_items_in_cart") {
                set $skip_cache 1;
            }

            client_max_body_size 64m;
          '';

          locations."/".extraConfig = ''
            index index.php;
            try_files $uri $uri/ /index.php$is_args$args;
          '';

          locations."~ \\.php$".extraConfig = ''
            # CACHE
            fastcgi_cache_bypass $skip_cache;
            fastcgi_no_cache $skip_cache;
            fastcgi_cache ${name};
            fastcgi_cache_key "$scheme$request_method$host$request_uri";
            fastcgi_cache_valid 200 301 302 30m;

            # Add these headers for debugging
            add_header X-Cache-Status $upstream_cache_status;

            # PARAMS
            fastcgi_pass unix:${phpfpmSocket};
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
            fastcgi_cache_purge ${name} "$scheme$request_method$host$1";
          '';

          locations."/app/uploads/" = {
            alias = "/var/lib/${siteCfg.user}/app/uploads/";
            extraConfig = lib.mkIf (siteCfg.assetProxy != "") ''
              try_files $uri @production;
            '';
          };

          locations."@production" = lib.mkIf (siteCfg.assetProxy != "") {
            extraConfig = ''
              resolver 8.8.8.8;
              proxy_ssl_server_name on;
              proxy_pass ${siteCfg.assetProxy};
            '';
          };
        };
      };

      systemd.services."${name}-setupCache" = {
        description = "Creates object-cache.php in content dir for redis to work. Sets up nginx fastcgi cache for ${name}";
        serviceConfig = {
          ExecStart = "${scripts.setupCache}/bin/set-up-cache-${name}";
          Type = "simple";
        };
        wantedBy = [ "multi-user.target" ];
      };

      systemd.services."${name}-content-dir" = {
        description = "Copies the ${name} project content folder to /var/lib";
        serviceConfig = {
          ExecStart = "${scripts.setupContentDir}/bin/setup-content-dir-${name}";
          Type = "simple";
        };
        wantedBy = [ "multi-user.target" ];
      };

      age.secrets."${name}-env" = {
        rekeyFile = ../${node.name}/secrets/${name}-env.age;
      };
    };
in
{
  options.services.linusfri.wordpress = {
    sites = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          package = lib.mkOption {
            type = lib.types.package;
            description = "WordPress package to use";
          };

          user = lib.mkOption {
            type = lib.types.str;
            description = "User to run WordPress as";
          };

          home = lib.mkOption {
            type = lib.types.path;
            description = "Home directory for the WordPress user";
          };

          domain = lib.mkOption {
            type = lib.types.str;
            description = "Domain name for the WordPress site";
          };

          dbName = lib.mkOption {
            type = lib.types.str;
            description = "Database name";
          };

          dbPrefix = lib.mkOption {
            type = lib.types.str;
            default = "wp_";
            description = "Database table prefix";
          };

          projectDir = lib.mkOption {
            type = lib.types.str;
            description = "Project directory name within the package";
          };

          environment = lib.mkOption {
            type = lib.types.enum [ "development" "staging" "production" ];
            default = "production";
            description = "WordPress environment";
          };

          debug = {
            enabled = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Enable WordPress debugging";
            };

            display = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Enable debug display";
            };
          };

          ssl = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable ACME SSL certificates";
            };

            force = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Force SSL redirect";
            };
          };

          basicAuth = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Enable basic authentication";
            };
          };

          assetProxy = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Asset proxy URL for production assets";
          };
        };
      });
      default = {};
      description = "WordPress sites to configure";
    };
  };

  config = let
    cfg = config.services.linusfri.wordpress;
    inherit (config.terraflake.input) node;
    nginxUser = config.services.nginx.user;
  in lib.mkMerge (lib.mapAttrsToList (name: siteCfg:
    let
      secretPath = "/run/agenix/${name}-env";
      redisSocket = "/run/redis-${siteCfg.user}/redis.sock";
      phpfpmSocket = "/run/phpfpm/${siteCfg.user}.sock";
    in mkSiteConfig name siteCfg node nginxUser secretPath redisSocket phpfpmSocket
  ) cfg.sites);
}
