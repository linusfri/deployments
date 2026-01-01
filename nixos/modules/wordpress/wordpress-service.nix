{
  config,
  pkgs,
  lib,
  ...
}:
let
  sites = config.services.linusfri.wordpress.sites;

  phpFpmSettings = import ../../settings/phpfpm-settings.nix;

  inherit (config.terraflake.input) node;
  inherit (lib) types;

  nginxUser = config.services.nginx.user;

  createEnvironment =
    siteCfg:
    pkgs.writeShellScriptBin "create-environment" ''
      ${createEnvFile siteCfg}/bin/create-env-file

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

  createEnvFile =
    site:
    pkgs.writeShellScriptBin "create-env-file" ''
      cat ${config.age.secrets."${site.appName}-env".path} > ${site.home}/.env

      # Concatinates public envs to secret part
      cat <<EOF >> ${site.home}/.env
      WP_DEBUG_DISPLAY=${toString site.debug.display}
      WP_ENV=${site.environment}
      WP_DEBUG=${toString site.debug.enabled}
      DB_USER=${site.user}
      DB_NAME=${site.dbName}
      DB_PASSWORD="" # Wp cli commands complain otherwise
      DB_PREFIX=${site.dbPrefix}
      WP_DEBUG_LOG=/var/log/debug-wp.log
      WP_HOME=https://${site.domain}
      WP_SITEURL=https://${site.domain}/wp
      CONTENT_PATH=${site.home}
      FS_METHOD=direct
      WP_REDIS_PATH=${config.services.redis.servers.${site.user}.unixSocket}
      WP_REDIS_PORT=0
      WP_REDIS_HOST=localhost
      WP_REDIS_SCHEME=unix
      WP_REDIS_DISABLE_DROPIN_CHECK=true
      WP_REDIS_DISABLE_DROPIN_AUTOUPDATE=true
      EOF
    '';

  setupContentDir =
    site:
    pkgs.writeShellScriptBin "setup-content-dir" ''
      PATH=${lib.makeBinPath [ pkgs.rsync ]}:$PATH
      CONTENT_DIR="${site.home}/app"
      TMP_CONTENT="/tmp/${site.user}-app"

      mkdir -p "$CONTENT_DIR"

      # Creates .env file and configures direnv
      ${createEnvironment site}/bin/create-environment

      # Creates wp-cli.yml to be able to use wp cli
      cat <<EOF > "${site.home}/wp-cli.yml"
        path: ${site.package}/share/php/${site.projectDir}/web/wp
      EOF

      # Temp folder for intermediate storage
      mkdir -p "$TMP_CONTENT"
      rsync -r ${site.package}/share/php/${site.projectDir}/web/app/ "$TMP_CONTENT"

      # Sync persistant content with repo content
      rsync -r --delete --exclude "uploads" "$TMP_CONTENT/" "$CONTENT_DIR"

      rm -rf "$TMP_CONTENT"
      chown -R ${site.user}:${site.user} $CONTENT_DIR
      chmod -R 755 ${site.home}
    '';

  setupCache =
    site:
    pkgs.writeShellScriptBin "set-up-cache" ''
      PATH=${lib.makeBinPath [ pkgs.rsync ]}:$PATH

      # SET UP OBJECT CACHE
      PUBLIC_CONTENT=${site.package}/share/php/${site.projectDir}/web/app

      # Copy object cache file to make redis work with DISALLOW_FILE_[MODS|EDIT]=true
      # Redis plugin deletes this file if inactivated in Admin. Don't do it.
      if [[ -d $PUBLIC_CONTENT/plugins/redis-cache ]]; then
        rsync -vL $PUBLIC_CONTENT/plugins/redis-cache/includes/object-cache.php ${site.home}/app/
      fi

      chown ${site.user}:${site.user} ${site.home}/app/object-cache.php

      # SET UP PAGE CACHE DIRECTORY FOR FASTCGI CACHE
      mkdir -p /var/run/nginx-cache/${site.appName}
      chown -R ${nginxUser}:${nginxUser} /var/run/nginx-cache/${site.appName}

      # Don't do this. Find a better way instead of allowing all with 777
      chmod -R 777 /var/run/nginx-cache/${site.appName}
    '';
in
{
  options.services.linusfri.wordpress = {
    enable = lib.mkEnableOption "WordPress service";

    sites = lib.mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            imports = [
              ./site-cfg.nix
            ];
          }
        )
      );
      description = "WordPress sites";
    };
  };

  config =
    lib.mkIf (sites != { }) {
      users.users = lib.mkMerge (
        lib.mapAttrsToList (name: site: {
          ${site.user} = {
            isNormalUser = true;
            createHome = true;
            extraGroups = [ "nginx" ];
            home = site.home;
            group = site.user;
          };
        }) sites
      );

      users.groups = lib.mkMerge (
        lib.mapAttrsToList (name: site: {
          ${site.user} = {
            members = [
              site.user
            ];
          };
        }) sites
      );

      services.mysql = {
        initialDatabases = lib.mapAttrsToList (name: site: { name = "${site.dbName}"; }) sites;
        ensureDatabases = lib.mapAttrsToList (name: site: "${site.dbName}") sites;
        ensureUsers = lib.mapAttrsToList (name: site: {
          name = site.user;
          ensurePermissions = {
            "${site.dbName}.*" = "ALL PRIVILEGES";
          };
        }) sites;
      };

      services.redis.servers = lib.mkMerge (
        lib.mapAttrsToList (name: site: {
          ${site.user} = {
            enable = true;
            user = site.user;
            group = site.user;
            port = 0; # Listen only on unix socket
            unixSocket = "/run/redis-${site.user}/redis.sock";
          };
        }) sites
      );

      services.phpfpm.pools = lib.mkMerge (
        lib.mapAttrsToList (name: site: {
          ${site.user} = {
            user = site.user;
            settings = phpFpmSettings // {
              "listen.owner" = config.services.nginx.user;
              "access.log" = "/var/log/${site.user}-phpfpm-access.log";
            };
            phpOptions = ''
              error_log = /var/log/${site.user}/php-error.log
              error_reporting = -1
              log_errors = On
              log_errors_max_len = 0
            '';
            phpEnv = {
              PATH = lib.makeBinPath [ pkgs.php ];
              ENV_FILE_PATH = "${site.home}";
            };
          };
        }) sites
      );

      services.nginx = {
        appendHttpConfig = lib.concatMapStringsSep "\n" (site: ''
          fastcgi_cache_path /var/run/nginx-cache/${site.appName} levels=1:2 keys_zone=${site.appName}:100m inactive=45m;
        '') (lib.attrValues sites);

        virtualHosts = lib.mkMerge (
          lib.mapAttrsToList (name: site: {
            ${site.domain} = {
              enableACME = site.ssl.enable;
              forceSSL = site.ssl.force;
              root = "${site.package}/share/php/${site.projectDir}/web";
              basicAuth = lib.mkIf site.basicAuth.enable {
                ${site.user} = site.user;
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
                fastcgi_cache ${site.appName};
                fastcgi_cache_key "$scheme$request_method$host$request_uri";
                fastcgi_cache_valid 200 301 302 30m;

                # Add these headers for debugging
                add_header X-Cache-Status $upstream_cache_status;

                # PARAMS
                fastcgi_pass unix:${config.services.phpfpm.pools.${site.user}.socket};
                fastcgi_index index.php;
                include ${pkgs.nginx}/conf/fastcgi_params;
                fastcgi_param SCRIPT_FILENAME $request_filename;
                fastcgi_buffer_size 512k;
                fastcgi_buffers 16 512k;
              '';

              locations."~ /purge(/.*)".extraConfig = ''
                fastcgi_cache_purge ${site.appName} "$scheme$request_method$host$1";
              '';

              locations."/app/uploads/" = {
                alias = "/var/lib/${site.user}/app/uploads/";
                extraConfig = lib.mkIf (site.assetProxy != "") ''
                  try_files $uri @production;
                '';
              };

              locations."@production" = lib.mkIf (site.assetProxy != "") {
                extraConfig = ''
                  resolver 8.8.8.8;
                  proxy_ssl_server_name on;
                  proxy_pass ${site.assetProxy};
                '';
              };
            };
          }) sites
        );
      };

      systemd.services = lib.mkMerge (
        lib.mapAttrsToList (name: site: {
          "${site.appName}-setupCache" = {
            description = "Creates object-cache.php in content dir for redis to work. Sets up nginx fastcgi cache";
            serviceConfig = {
              ExecStart = "${setupCache site}/bin/set-up-cache";
              Type = "simple";
            };
            wantedBy = [ "multi-user.target" ];
          };

          "${site.appName}-content-dir" = {
            description = "Copies the project content folder to /var/lib";
            serviceConfig = {
              ExecStart = "${setupContentDir site}/bin/setup-content-dir";
              Type = "simple";
            };
            wantedBy = [ "multi-user.target" ];
          };
        }) sites
      );

      age.secrets = lib.mkMerge (
        lib.mapAttrsToList (name: site: {
          "${site.appName}-env" = {
            rekeyFile = ../../${node.name}/secrets/${site.appName}-env.age;
            generator.script = "passphrase";
          };
        }) sites
      );
    };
}
