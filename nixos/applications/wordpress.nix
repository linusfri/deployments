{
  config,
  pkgs,
  ...
}:
let
  inherit (config.terraflake.input) node;
in
{
  imports = [ ../modules/wordpress/wordpress-multisite-service.nix ];

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
      package = pkgs.bedrock-wp;
      user = "carolin";
      home = "/var/lib/carolin";
      domain = "carolin.example.com";
      dbName = "carolin_db";
      dbPrefix = "wp_";
      projectDir = "wordpress";

      environment = "production";

      debug = {
        enabled = true;
        display = true;
      };

      ssl = {
        enable = false;
        force = false;
      };

      basicAuth = {
        enable = true; # Enable basic auth for staging
      };
    };

    # Add more sites as needed...
  };
}

# services.linusfri.wordpress = {
#   enable = true;
#   appName = "elin";
#   package = pkgs.bedrock-wp;  # Replace with your actual package
#   user = "elin";
#   home = "/var/lib/elin";
#   domain = node.domains.elin;  # Or use a string like "example.com"
#   dbName = "elin_db";
#   dbPrefix = "wp_";
#   projectDir = "bedrock-wp";  # Adjust based on your package structure

#   environment = "production";

#   debug = {
#     enabled = false;
#     display = false;
#   };

#   ssl = {
#     enable = true;
#     force = true;
#   };

#   basicAuth = {
#     enable = false;
#   };
# };
