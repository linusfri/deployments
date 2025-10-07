# WordPress Multi-Site Service Usage

Import this service instead of the single-site one:

```nix
{
  config,
  pkgs,
  ...
}:
let
  inherit (config.terraflake.input) node;
in
{
  imports = [ ../modules/wordpress-multisite-service.nix ];

  services.linusfri.wordpress.sites = {
    # First site
    elin = {
      package = pkgs.bedrock-wp;
      user = "elin";
      home = "/var/lib/elin";
      domain = node.domains.elin;
      dbName = "elin_db";
      dbPrefix = "wp_";
      projectDir = "bedrock-wp";
      
      environment = "production";
      
      debug = {
        enabled = false;
        display = false;
      };
      
      ssl = {
        enable = true;
        force = true;
      };
      
      basicAuth = {
        enable = false;
      };
      
      assetProxy = "";
    };

    # Second site
    mysite = {
      package = pkgs.another-wp-package;
      user = "mysite";
      home = "/var/lib/mysite";
      domain = "mysite.example.com";
      dbName = "mysite_db";
      dbPrefix = "wp_";
      projectDir = "wordpress";
      
      environment = "staging";
      
      debug = {
        enabled = true;
        display = true;
      };
      
      ssl = {
        enable = true;
        force = false;  # Staging might not force SSL
      };
      
      basicAuth = {
        enable = true;  # Enable basic auth for staging
      };
      
      assetProxy = "https://production.example.com";
    };

    # Add more sites as needed...
  };
}
```

## Key Features:

1. **Multiple Sites**: Each site is defined under `services.linusfri.wordpress.sites.<name>`
2. **Independent Configuration**: Each site has its own:
   - User, home directory, and database
   - PHP-FPM pool and Redis instance
   - Nginx virtualhost
   - Systemd services (prefixed with site name)
   - Age secrets (named `<sitename>-env.age`)

3. **Automatic Resource Management**: 
   - Users and groups created per site
   - Database and permissions configured per site
   - Redis sockets isolated per site
   - Cache directories separated per site

4. **Clean Naming**: All resources are prefixed with the site name:
   - Systemd services: `elin-content-dir`, `elin-setupCache`
   - Age secrets: `elin-env.age`, `mysite-env.age`
   - Cache zones: `elin`, `mysite`
   - Log files: `/var/log/elin-debug-wp.log`

## Migration from Single-Site:

**Old (single-site service):**
```nix
services.linusfri.wordpress = {
  enable = true;
  appName = "elin";
  # ... config
};
```

**New (multi-site service):**
```nix
services.linusfri.wordpress.sites.elin = {
  # No enable or appName needed - the attribute name is the site name
  # ... same config
};
```

The site name (attribute name like `elin` or `mysite`) is automatically used for:
- systemd service names
- secret file names
- cache zone names
